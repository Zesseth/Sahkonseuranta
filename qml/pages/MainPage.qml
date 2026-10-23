// SPDX-License-Identifier: AGPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
import "../components/Levels.js" as Levels

Page {
    id: page

    Component.onCompleted: priceFetcher.refresh()

    function fmtPrice(v) {
        return v.toFixed(2).replace(".", ",")
    }

    // Price levels follow the thresholds configured in Settings
    function levelOf(price) {
        return Levels.levelOf(price, appSettings.cheapThreshold, appSettings.expensiveThreshold)
    }

    function levelName(level) {
        if (level === 0)
            return qsTr("Halpa")
        if (level === 2)
            return qsTr("Kallis")
        return qsTr("Keskitaso")
    }

    function levelNameIllative(level) {
        if (level === 0)
            return qsTr("halpaan tasoon")
        if (level === 2)
            return qsTr("kalliiseen tasoon")
        return qsTr("keskitasoon")
    }

    function levelColor(level) {
        return Levels.levelColor(level)
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

            // No data or loading placeholder
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: !priceFetcher.hasData
                text: priceFetcher.loading ? qsTr("Ladataan...") : qsTr("Ei tietoja")
                color: priceFetcher.loading ? Theme.highlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeLarge
                wrapMode: Text.WordWrap
                height: visible ? implicitHeight : 0
            }

            // Fetch error text. Also shown on top of stale data after a
            // failed refresh: without it an airplane-mode "Päivitä" would
            // silently leave the old prices looking current.
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: !priceFetcher.loading && priceFetcher.errorString !== ""
                text: priceFetcher.errorString
                color: Theme.errorColor
                wrapMode: Text.WordWrap
                height: visible ? implicitHeight : 0
            }

            // Section 1: price level now + forecast of how long it holds
            Column {
                id: levelSection
                width: parent.width
                spacing: Theme.paddingMedium
                visible: priceFetcher.hasData
                // Positioners keep space for invisible items: collapse
                // so the no-data page is not followed by empty scroll
                height: visible ? implicitHeight : 0

                SectionHeader {
                    text: qsTr("Hinta on nyt klo %1").arg(page.currentPeriodStart())
                }

                Row {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
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
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                        }

                        Label {
                            id: levelChangeLabel
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: page.nextLevel !== null
                                  ? qsTr("Vaihtuu %1")
                                        .arg(page.levelNameIllative(page.levelOf(page.nextLevel.price)))
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
            }

            // Section 2: min / average / max over the chart window
            Column {
                id: statsSection
                width: parent.width
                spacing: Theme.paddingMedium
                visible: priceFetcher.hasData
                height: visible ? implicitHeight : 0

                Row {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    spacing: Theme.paddingLarge

                    Column {
                        width: (parent.width - 2 * parent.spacing) / 3
                        spacing: Theme.paddingSmall

                        Label {
                            text: qsTr("Alin")
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        Row {
                            spacing: Theme.paddingSmall

                            Label {
                                id: minValue
                                text: page.fmtPrice(priceFetcher.minPrice)
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                            }
                            Label {
                                anchors.baseline: minValue.baseline
                                text: qsTr("snt/kWh")
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeExtraSmall
                            }
                        }
                        Label {
                            text: priceFetcher.minTimeText
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeTiny
                            visible: priceFetcher.minTimeText !== ""
                            height: visible ? implicitHeight : 0
                        }
                    }

                    Column {
                        width: (parent.width - 2 * parent.spacing) / 3
                        spacing: Theme.paddingSmall

                        Label {
                            text: qsTr("Keskiarvo")
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        Row {
                            spacing: Theme.paddingSmall

                            Label {
                                id: avgValue
                                text: page.fmtPrice(priceFetcher.avgPrice)
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                            }
                            Label {
                                anchors.baseline: avgValue.baseline
                                text: qsTr("snt/kWh")
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeExtraSmall
                            }
                        }
                        Label {
                            text: priceFetcher.windowSpanText
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeTiny
                            visible: priceFetcher.windowSpanText !== ""
                            height: visible ? implicitHeight : 0
                        }
                    }

                    Column {
                        width: (parent.width - 2 * parent.spacing) / 3
                        spacing: Theme.paddingSmall

                        Label {
                            text: qsTr("Ylin")
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        Row {
                            spacing: Theme.paddingSmall

                            Label {
                                id: maxValue
                                text: page.fmtPrice(priceFetcher.maxPrice)
                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                            }
                            Label {
                                anchors.baseline: maxValue.baseline
                                text: qsTr("snt/kWh")
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeExtraSmall
                            }
                        }
                        Label {
                            text: priceFetcher.maxTimeText
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeTiny
                            visible: priceFetcher.maxTimeText !== ""
                            height: visible ? implicitHeight : 0
                        }
                    }
                }
            }

            // Section 3: the chart fills the rest of the screen
            Column {
                id: chartColumn
                width: parent.width
                spacing: Theme.paddingSmall
                visible: priceFetcher.hasData
                height: visible ? implicitHeight : 0

                SectionHeader {
                    id: chartCaption
                    text: appSettings.resolution === 60
                        ? qsTr("Tunnin keskiarvot c/kWh")
                        : qsTr("Vartin hinnat c/kWh")
                }

                PriceGraph {
                    id: graph
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    height: page.height
                           - header.height
                           - levelSection.height
                           - statsSection.height
                           - chartCaption.height
                           - 3 * column.spacing
                           - 4 * Theme.paddingLarge
                    bars: priceFetcher.allBars
                    nowIndex: priceFetcher.allNowIndex
                    cheapThreshold: appSettings.cheapThreshold
                    expensiveThreshold: appSettings.expensiveThreshold
                    // Pass the index directly: graph.nowIndex may
                    // not have re-evaluated yet when this fires
                    onBarsChanged: scrollToNow(priceFetcher.allNowIndex)
                }
            }
        }
    }
}
