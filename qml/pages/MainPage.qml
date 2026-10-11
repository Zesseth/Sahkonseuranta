import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    Component.onCompleted: priceFetcher.refresh()

    // Card background shared by all boxes
    readonly property color cardColor: Theme.rgba(Theme.highlightBackgroundColor, 0.2)
    readonly property int cardRadius: Theme.paddingLarge

    function fmtPrice(v) {
        return v.toFixed(2).replace(".", ",")
    }

    // Price levels follow the thresholds configured in Settings
    function levelOf(price) {
        if (price <= appSettings.cheapThreshold)
            return 0
        if (price >= appSettings.expensiveThreshold)
            return 2
        return 1
    }

    function levelName(level) {
        if (level === 0)
            return qsTr("Halpa")
        if (level === 2)
            return qsTr("Kallis")
        return qsTr("Keskitaso")
    }

    function levelColor(level) {
        if (level === 0)
            return "#2ecc71"
        if (level === 2)
            return "#e74c3c"
        return "#f1c40f"
    }

    // Next bar whose level differs from the current one - the price may
    // change several times inside the same level before it actually
    // switches. null when the level holds to the end of the data.
    function nextLevelBar() {
        var bars = priceFetcher.allBars
        var now = priceFetcher.allNowIndex
        if (now < 0 || now >= bars.length)
            return null
        var curLevel = levelOf(priceFetcher.displayPrice)
        for (var i = now + 1; i < bars.length; ++i) {
            if (levelOf(bars[i].price) !== curLevel)
                return bars[i]
        }
        return null
    }

    // Cached per binding refresh so the labels can null-check safely
    readonly property var nextLevel: nextLevelBar()

    // Start time of the ongoing price period: the quarter start at
    // 15 min resolution, the hour start at 60 min
    function currentPeriodStart() {
        var i = priceFetcher.nowIndex
        if (i < 0 || i >= priceFetcher.bars.length)
            return ""
        return Qt.formatDateTime(priceFetcher.bars[i].start, "HH:mm")
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("Päivitä")
                onClicked: priceFetcher.refresh()
            }
            MenuItem {
                text: qsTr("Asetukset")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
        }

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingMedium

            PageHeader {
                id: header
                title: qsTr("Pörssisähkö tänään")
            }

            // Box 1: price level now + forecast of how long it holds
            Rectangle {
                id: priceCard
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: priceBox1Column.height + 2 * Theme.paddingLarge
                radius: page.cardRadius
                color: page.cardColor
                visible: priceFetcher.hasData || priceFetcher.loading

                Column {
                    id: priceBox1Column
                    x: Theme.paddingLarge
                    width: parent.width - 2 * Theme.paddingLarge
                    y: Theme.paddingLarge
                    spacing: Theme.paddingSmall

                    Label {
                        visible: priceFetcher.hasData
                        text: qsTr("Hinta on nyt klo %1")
                              .arg(page.currentPeriodStart())
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    // Ball on the left, level and forecast beside it
                    Row {
                        visible: priceFetcher.hasData
                        width: parent.width
                        spacing: Theme.paddingLarge

                        PriceBall {
                            id: ball
                            price: priceFetcher.displayPrice
                            cheapThreshold: appSettings.cheapThreshold
                            expensiveThreshold: appSettings.expensiveThreshold
                            hasData: priceFetcher.hasData
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - ball.width - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.paddingSmall

                            Label {
                                text: qsTr("Taso nyt: %1")
                                      .arg(page.levelName(page.levelOf(priceFetcher.displayPrice)))
                                color: page.levelColor(page.levelOf(priceFetcher.displayPrice))
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: true
                            }

                            Label {
                                id: levelChangeLabel
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: page.nextLevel !== null
                                      ? qsTr("Vaihtuu %1-tasoon")
                                            .arg(page.nextLevel !== null
                                                 ? page.levelName(page.levelOf(page.nextLevel.price))
                                                 : "")
                                      : qsTr("Hinta pysyy tällä tasolla koko näytettävän ajan")
                                color: page.nextLevel !== null
                                       ? page.levelColor(page.levelOf(page.nextLevel.price))
                                       : Theme.secondaryHighlightColor
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Label {
                                visible: page.nextLevel !== null
                                text: page.nextLevel !== null
                                      ? qsTr("klo %1 · %2 snt/kWh")
                                            .arg(Qt.formatDateTime(page.nextLevel.start, "HH:mm"))
                                            .arg(page.fmtPrice(page.nextLevel.price))
                                      : ""
                                color: Theme.secondaryHighlightColor
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }
                    }

                    Label {
                        visible: !priceFetcher.hasData
                        text: priceFetcher.loading ? qsTr("Ladataan...") : qsTr("Ei tietoja")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeLarge
                    }
                }
            }

            // Error text when there is no box to show it in
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: !priceFetcher.hasData && !priceFetcher.loading && priceFetcher.errorString !== ""
                text: priceFetcher.errorString
                color: Theme.errorColor
                wrapMode: Text.WordWrap
            }

            // Box 2: price now at clock + period, and today's stats
            Rectangle {
                id: statsCard
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: statsColumn.height + 2 * Theme.paddingLarge
                radius: page.cardRadius
                color: page.cardColor
                visible: priceFetcher.hasData

                Column {
                    id: statsColumn
                    x: Theme.paddingLarge
                    width: parent.width - 2 * Theme.paddingLarge
                    y: Theme.paddingLarge
                    spacing: Theme.paddingMedium

                    Row {
                        width: parent.width
                        spacing: Theme.paddingLarge

                        Column {
                            width: (parent.width - 2 * parent.spacing) / 3
                            spacing: 2

                            Label {
                                text: qsTr("Alin")
                                color: Theme.secondaryHighlightColor
                                font.pixelSize: Theme.fontSizeSmall
                            }
                            Label {
                                text: page.fmtPrice(priceFetcher.minPrice)
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                            }
                        }

                        Column {
                            width: (parent.width - 2 * parent.spacing) / 3
                            spacing: 2

                            Label {
                                text: qsTr("Keskiarvo")
                                color: Theme.secondaryHighlightColor
                                font.pixelSize: Theme.fontSizeSmall
                            }
                            Label {
                                text: page.fmtPrice(priceFetcher.avgPrice)
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                            }
                        }

                        Column {
                            width: (parent.width - 2 * parent.spacing) / 3
                            spacing: 2

                            Label {
                                text: qsTr("Ylin")
                                color: Theme.secondaryHighlightColor
                                font.pixelSize: Theme.fontSizeSmall
                            }
                            Label {
                                text: page.fmtPrice(priceFetcher.maxPrice)
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                            }
                        }
                    }
                }
            }

            // Box 3: the chart fills the rest of the screen
            Rectangle {
                id: chartCard
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: chartColumn.height + 2 * Theme.paddingLarge
                radius: page.cardRadius
                color: page.cardColor
                visible: priceFetcher.hasData

                Column {
                    id: chartColumn
                    x: Theme.paddingLarge
                    width: parent.width - 2 * Theme.paddingLarge
                    y: Theme.paddingLarge
                    spacing: Theme.paddingSmall

                    Label {
                        id: chartCaption
                        text: appSettings.resolution === 60
                              ? qsTr("Tunnin keskiarvot c/kWh")
                              : qsTr("Vartin hinnat c/kWh")
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    PriceGraph {
                        id: graph
                        width: parent.width
                        height: page.height
                               - header.height
                               - priceCard.height
                               - statsCard.height
                               - chartCaption.height
                               - 3 * column.spacing
                               - 5 * Theme.paddingLarge
                        bars: priceFetcher.allBars
                        nowIndex: priceFetcher.allNowIndex
                        cheapThreshold: appSettings.cheapThreshold
                        expensiveThreshold: appSettings.expensiveThreshold
                        onBarsChanged: scrollToNow()
                    }
                }
            }
        }
    }
}
