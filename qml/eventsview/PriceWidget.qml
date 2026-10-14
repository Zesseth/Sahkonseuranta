// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Events View widget. Lipstick loads this file inside its own process,
// so the widget is fully self-contained: it fetches the spot prices
// itself from the porssisahko.net v2 API and reads the thresholds the
// app persisted via QSettings. The price-level logic is shared with
// the app through Levels.js and PriceBall.
import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
import "../components/Levels.js" as Levels

Item {
    id: root

    width: parent ? parent.width : Screen.width
    implicitWidth: width
    implicitHeight: content.height + 2 * Theme.paddingLarge
    height: implicitHeight

    // Lipstick's Events View keeps enabled widgets instantiated with a
    // Loader whose item stays visible the whole time, so visibility
    // alone cannot tell whether the Events View is on screen. The
    // loader scope also provides eventsViewVisible; the widget may
    // only do work while both hold. If that context property is
    // ever unavailable, degrade to the plain visibility rule
    // instead of breaking the widget.
    property bool active: visible
                          && (typeof eventsViewVisible === "undefined"
                              ? true : eventsViewVisible)

    // Price periods in ascending start order: [{price, start, end}]
    property var entries: []
    property bool loading: false
    property bool error: false
    property var xhr: null

    // Threshold defaults match the app Settings defaults (5.0 / 10.0)
    property double cheapThreshold: 5.0
    property double expensiveThreshold: 10.0
    property int resolution: 15 // minutes, 15 or 60

    readonly property int currentIndex: findCurrentIndex()
    readonly property var currentEntry: currentIndex >= 0 ? entries[currentIndex] : null
    readonly property bool hasData: currentEntry !== null
    readonly property double displayPrice: computeDisplayPrice()
    readonly property int level: !hasData ? 1
                                 : Levels.levelOf(displayPrice, cheapThreshold, expensiveThreshold)
    readonly property var nextLevelEntry: findNextLevelEntry()

    function findCurrentIndex() {
        var now = new Date()
        for (var i = 0; i < entries.length; ++i) {
            if (entries[i].start <= now && now < entries[i].end)
                return i
        }
        return -1
    }

    function sameHour(a, b) {
        return a.getFullYear() === b.getFullYear()
                && a.getMonth() === b.getMonth()
                && a.getDate() === b.getDate()
                && a.getHours() === b.getHours()
    }

    // The ongoing spot price at 15 min resolution, the ongoing hour's
    // average at 60 min resolution - the same rule as the app front page
    function computeDisplayPrice() {
        if (currentIndex < 0)
            return 0.0
        if (resolution !== 60)
            return entries[currentIndex].price
        var sum = 0.0
        var count = 0
        var hour = entries[currentIndex].start
        for (var i = 0; i < entries.length; ++i) {
            if (sameHour(entries[i].start, hour)) {
                sum += entries[i].price
                count++
            }
        }
        return count > 0 ? sum / count : entries[currentIndex].price
    }

    // The first period after the ongoing one whose level differs from
    // the current one - the price may change several times inside the
    // same level before it actually switches
    function findNextLevelEntry() {
        if (currentIndex < 0)
            return null
        for (var i = currentIndex + 1; i < entries.length; ++i) {
            if (Levels.levelOf(entries[i].price, cheapThreshold, expensiveThreshold) !== level)
                return entries[i]
        }
        return null
    }

    function levelName(lvl) {
        if (lvl === 0)
            return qsTr("Halpa")
        if (lvl === 2)
            return qsTr("Kallis")
        return qsTr("Keskitaso")
    }

    function levelNameIllative(lvl) {
        if (lvl === 0)
            return qsTr("halvan tasoon")
        if (lvl === 2)
            return qsTr("kalliin tasoon")
        return qsTr("keskitasoon")
    }

    // "HH:mm", with the weekday abbreviation appended when the moment
    // is not today (same rule as the app uses)
    function formatTime(t) {
        function pad(n) { return n < 10 ? "0" + n : "" + n }
        var text = pad(t.getHours()) + ":" + pad(t.getMinutes())
        var now = new Date()
        if (t.getFullYear() === now.getFullYear() && t.getMonth() === now.getMonth()
                && t.getDate() === now.getDate())
            return text
        var names = [qsTr("Su"), qsTr("Ma"), qsTr("Ti"), qsTr("Ke"), qsTr("To"), qsTr("Pe"), qsTr("La")]
        return text + " " + names[t.getDay()]
    }

    // Time the next fetch a few seconds after the next quarter-hour
    // boundary, when the spot price changes
    function msToNextBoundary() {
        var quarter = 15 * 60 * 1000
        var msIntoQuarter = Date.now() % quarter
        var interval = quarter - msIntoQuarter + 5000
        return Math.max(10 * 1000, Math.min(interval, quarter + 5000))
    }

    function refresh() {
        readSettings()
        if (active)
            fetch()
    }

    function reload() {
        refresh()
    }

    function save() {
        // The widget has no settings of its own to persist
    }

    Component.onCompleted: if (active) refresh()

    onActiveChanged: {
        if (active) {
            refresh()
        } else {
            boundaryTimer.stop()
            if (xhr) {
                xhr.abort()
                xhr = null
                loading = false
            }
        }
    }

    function readSettings() {
        // The app persists its settings with QSettings under
        // fi.zesseth/sahkonseuranta; the widget reads the same file so
        // the level colors always match the app. HOME comes from the
        // Lipstick process environment; the environ read can fail
        // (procfs reports a size of zero), and the standard user home
        // differs between releases, so the standard homes are tried
        // as well: /home/defaultuser on Sailfish OS 5.x and
        // /home/nemo on 4.x and earlier.
        var environ = new XMLHttpRequest()
        environ.onreadystatechange = function() {
            if (environ.readyState !== XMLHttpRequest.DONE)
                return
            var home = ""
            if (environ.responseText.length > 0) {
                // Entries are NUL-separated; anchor HOME= to
                // the start of an entry so a variable such
                // as XDG_CONFIG_HOME=/... is not mistaken for HOME
                var match = environ.responseText.match(/(?:^|\x00)HOME=(\/[^\x00]*)/)
                if (match)
                    home = match[1]
            }
            var homes = []
            if (home && home !== "/home/defaultuser" && home !== "/home/nemo")
                homes.push(home)
            homes.push("/home/defaultuser")
            homes.push("/home/nemo")
            // The app stores its settings inside the
            // sailjail-whitelisted fi.zesseth/sahkonseuranta directory;
            // the legacy QSettings default file is read as well
            var candidates = []
            for (var i = 0; i < homes.length; ++i) {
                candidates.push(homes[i] + "/.config/fi.zesseth/sahkonseuranta/settings.ini")
                candidates.push(homes[i] + "/.config/fi.zesseth/sahkonseuranta.conf")
            }
            readNextSettingsFile(candidates, 0)
        }
        environ.open("GET", "file:///proc/self/environ")
        environ.send()
    }

    // Apply the first candidate settings file that has any of the keys
    // the widget needs; missing files fall through silently
    function readNextSettingsFile(candidates, index) {
        if (index >= candidates.length)
            return
        var conf = new XMLHttpRequest()
        conf.onreadystatechange = function() {
            if (conf.readyState !== XMLHttpRequest.DONE)
                return
            var cheap = conf.responseText.match(/^cheapThreshold=(\d+)$/m)
            var expensive = conf.responseText.match(/^expensiveThreshold=(\d+)$/m)
            var res = conf.responseText.match(/^resolution=(\d+)$/m)
            if (cheap || expensive || res) {
                if (cheap)
                    root.cheapThreshold = parseInt(cheap[1], 10)
                if (expensive)
                    root.expensiveThreshold = parseInt(expensive[1], 10)
                if (res && (parseInt(res[1], 10) === 15 || parseInt(res[1], 10) === 60))
                    root.resolution = parseInt(res[1], 10)
                return
            }
            readNextSettingsFile(candidates, index + 1)
        }
        conf.open("GET", "file://" + candidates[index])
        conf.send()
    }

    function fetch() {
        if (xhr) {
            xhr.abort()
            xhr = null
        }
        loading = true
        var req = new XMLHttpRequest()
        xhr = req
        req.onreadystatechange = function() {
            if (req !== xhr || req.readyState !== XMLHttpRequest.DONE)
                return
            xhr = null
            loading = false
            if (req.status === 200) {
                var parsed = []
                try {
                    var doc = JSON.parse(req.responseText)
                    var arr = doc.prices
                    for (var i = 0; i < arr.length; ++i) {
                        var start = new Date(arr[i].startDate)
                        var end = new Date(arr[i].endDate)
                        var price = arr[i].price
                        if (isNaN(start.getTime()) || isNaN(end.getTime()) || end <= start)
                            continue
                        // A malformed price would propagate NaN into the
                        // Lipstick UI; skip it like an invalid date
                        if (typeof price !== "number" || !isFinite(price))
                            continue
                        parsed.push({ price: price, start: start, end: end })
                    }
                } catch (e) {
                    parsed = []
                }
                parsed.sort(function(a, b) { return a.start - b.start })
                entries = parsed
                error = parsed.length === 0
            } else {
                error = true
            }
            if (active)
                scheduleNextFetch()
        }
        req.open("GET", "https://api.porssisahko.net/v2/latest-prices.json")
        req.send()
        timeoutTimer.restart()
    }

    Timer {
        id: timeoutTimer
        interval: 20 * 1000
        onTriggered: {
            if (xhr) {
                xhr.abort()
                xhr = null
                loading = false
                error = true
                if (root.active)
                    root.scheduleNextFetch()
            }
        }
    }

    // Time the next fetch a few seconds after the next quarter-hour
    // boundary, when the spot price changes. The interval is assigned
    // imperatively: a binding would never re-evaluate because
    // Date.now() is not a notifiable dependency.
    function scheduleNextFetch() {
        boundaryTimer.interval = msToNextBoundary()
        boundaryTimer.restart()
    }

    Timer {
        id: boundaryTimer
        onTriggered: if (root.active) root.fetch()
    }

    Column {
        id: content
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        y: Theme.paddingLarge
        spacing: Theme.paddingSmall

        // The current price and its level share one row so the widget
        // stays compact and leaves room for the notifications below it
        Row {
            id: currentRow
            spacing: Theme.paddingLarge

            PriceBall {
                price: root.displayPrice
                cheapThreshold: root.cheapThreshold
                expensiveThreshold: root.expensiveThreshold
                hasData: root.hasData
                priceFontSize: Theme.fontSizeExtraLarge
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.hasData
                text: qsTr("Taso nyt: %1").arg(root.levelName(root.level))
                color: Levels.levelColor(root.level)
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
            }
        }

        Label {
            width: parent.width
            visible: root.hasData
            wrapMode: Text.WordWrap
            // A failed fetch leaves the previous data on display; say so
            // instead of showing a forecast the data cannot support
            text: root.error
                  ? qsTr("Ei yhteyttä")
                  : (root.nextLevelEntry !== null
                     ? qsTr("Vaihtuu %1 klo %2")
                       .arg(root.levelNameIllative(
                                Levels.levelOf(root.nextLevelEntry.price,
                                              root.cheapThreshold,
                                              root.expensiveThreshold)))
                       .arg(root.formatTime(root.nextLevelEntry.start))
                     : qsTr("Hinta pysyy tällä tasolla koko näytettävän ajan"))
            color: root.error
                   ? Theme.secondaryColor
                   : (root.nextLevelEntry !== null
                      ? Levels.levelColor(Levels.levelOf(root.nextLevelEntry.price,
                                                         root.cheapThreshold,
                                                         root.expensiveThreshold))
                      : Theme.secondaryHighlightColor)
            font.pixelSize: Theme.fontSizeSmall
        }

        Label {
            width: parent.width
            visible: !root.hasData
            text: root.loading ? qsTr("Ladataan...")
                              : (root.error ? qsTr("Ei yhteyttä") : qsTr("Ei tietoja"))
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeMedium
        }
    }
}
