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
                    } else {
                        dayOffset = 0
                        priceFetcher.showToday()
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

                    PriceBall {
                        price: priceFetcher.displayPrice
                        cheapThreshold: appSettings.cheapThreshold
                        expensiveThreshold: appSettings.expensiveThreshold
                        hasData: priceFetcher.hasData
                    }

                    Label {
                        visible: priceFetcher.hasData && dayOffset === 0
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: priceFetcher.hasNextPrice
                              ? qsTr("Taso pysyy klo %1 asti, jolloin hinta on %2")
                                    .arg(Qt.formatDateTime(priceFetcher.nextPriceStart, "HH:mm"))
                                    .arg(page.fmtPrice(priceFetcher.nextPrice))
                              : qsTr("Hinta pysyy tällä tasolla koko näytettävän ajan")
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

                    Label {
                        width: parent.width
                        text: dayOffset === 0
                              ? qsTr("Hinta on nyt klo %1 (%2)")
                                    .arg(Qt.formatDateTime(new Date(), "HH:mm"))
                                    .arg(appSettings.resolution === 60 ? qsTr("tunnin keskiarvo") : qsTr("vartin hinta"))
                              : qsTr("Huomisen hinnat")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                    }

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

            // Box 3: the chart
            Rectangle {
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
                        text: qsTr("Pylväät c/kWh, katkoviivat omat rajat")
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    PriceGraph {
                        id: graph
                        width: parent.width
                        height: Math.max(page.height * 0.3, Theme.itemSizeHuge)
                        bars: priceFetcher.bars
                        avgPrice: priceFetcher.avgPrice
                        minPrice: priceFetcher.minPrice
                        maxPrice: priceFetcher.maxPrice
                        nowIndex: priceFetcher.nowIndex
                        cheapThreshold: appSettings.cheapThreshold
                        expensiveThreshold: appSettings.expensiveThreshold
                    }
                }
            }
        }
    }
}
