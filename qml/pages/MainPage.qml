import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    property int dayOffset: 0

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
        return qsTr("Normaali")
    }

    function levelColor(level) {
        if (level === 0)
            return "#2ecc71"
        if (level === 2)
            return "#e74c3c"
        return "#f1c40f"
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
                text: dayOffset === 0 ? qsTr("Näytä huominen") : qsTr("Näytä tänään")
                onClicked: {
                    if (dayOffset === 0) {
                        dayOffset = 1
                        priceFetcher.showTomorrow()
                        var d = new Date()
                        d.setDate(d.getDate() + 1)
                        d.setHours(0, 0, 0, 0)
                        graph.scrollToDate(d)
                    } else {
                        dayOffset = 0
                        priceFetcher.showToday()
                        graph.scrollToNow()
                    }
                }
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
                title: dayOffset === 0 ? qsTr("Pörssisähkö tänään") : qsTr("Pörssisähkö huomenna")
            }

            // Box 1: price level now + forecast of how long it holds
            Rectangle {
                id: priceCard
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: priceBox1Column.height + 2 * Theme.paddingLarge
                radius: page.cardRadius
                color: page.cardColor
                visible: (priceFetcher.hasData && dayOffset === 0) || priceFetcher.loading

                Column {
                    id: priceBox1Column
                    x: Theme.paddingLarge
                    width: parent.width - 2 * Theme.paddingLarge
                    y: Theme.paddingLarge
                    spacing: Theme.paddingSmall

                    Label {
                        visible: priceFetcher.hasData
                        text: dayOffset === 0
                              ? qsTr("Hinta on nyt klo %1")
                                    .arg(Qt.formatDateTime(new Date(), "HH:mm"))
                              : qsTr("Huomisen hinnat")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                    }

                    PriceBall {
                        visible: priceFetcher.hasData
                        price: priceFetcher.displayPrice
                        cheapThreshold: appSettings.cheapThreshold
                        expensiveThreshold: appSettings.expensiveThreshold
                        hasData: priceFetcher.hasData
                    }

                    Label {
                        visible: priceFetcher.hasData && dayOffset === 0
                        text: qsTr("Taso nyt: %1")
                              .arg(page.levelName(page.levelOf(priceFetcher.displayPrice)))
                        color: page.levelColor(page.levelOf(priceFetcher.displayPrice))
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                    }

                    Label {
                        visible: priceFetcher.hasData && dayOffset === 0
                        text: priceFetcher.hasNextPrice
                              ? qsTr("Vaihtuu %1-tasoon")
                                    .arg(page.levelName(page.levelOf(priceFetcher.nextPrice)))
                              : qsTr("Hinta pysyy tällä tasolla koko näytettävän ajan")
                        color: priceFetcher.hasNextPrice
                               ? page.levelColor(page.levelOf(priceFetcher.nextPrice))
                               : Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        visible: priceFetcher.hasData && dayOffset === 0 && priceFetcher.hasNextPrice
                        text: qsTr("klo %1 · %2 snt/kWh")
                              .arg(Qt.formatDateTime(priceFetcher.nextPriceStart, "HH:mm"))
                              .arg(page.fmtPrice(priceFetcher.nextPrice))
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
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
