import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    property int dayOffset: 0

    Component.onCompleted: priceFetcher.refresh()

    // Card background shared by the price card, chart card and stat cards
    readonly property color cardColor: Theme.rgba(Theme.highlightBackgroundColor, 0.15)

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

            // Price card: ball + current price, centered
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: priceCardColumn.height + 2 * Theme.paddingLarge
                radius: Theme.paddingSmall * 2
                color: page.cardColor
                visible: (priceFetcher.hasData && dayOffset === 0) || priceFetcher.loading

                Column {
                    id: priceCardColumn
                    anchors.centerIn: parent
                    spacing: Theme.paddingSmall

                    PriceBall {
                        visible: priceFetcher.hasData && dayOffset === 0
                        price: priceFetcher.displayPrice
                        cheapThreshold: appSettings.cheapThreshold
                        expensiveThreshold: appSettings.expensiveThreshold
                        hasData: priceFetcher.hasData
                        priceFontSize: Theme.fontSizeHuge
                    }

                    Label {
                        visible: priceFetcher.hasData && dayOffset === 0
                        text: qsTr("Nyt")
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        visible: !priceFetcher.hasData
                        text: priceFetcher.loading ? qsTr("Ladataan...") : qsTr("Ei tietoja")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeLarge
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Error text when there is no card to show it in
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: !priceFetcher.hasData && !priceFetcher.loading && priceFetcher.errorString !== ""
                text: priceFetcher.errorString
                color: Theme.errorColor
                wrapMode: Text.WordWrap
            }

            // Chart card
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: graph.height + 2 * Theme.paddingMedium
                radius: Theme.paddingSmall * 2
                color: page.cardColor
                visible: priceFetcher.hasData

                PriceGraph {
                    id: graph
                    width: parent.width - 2 * Theme.paddingMedium
                    height: Math.max(page.height * 0.35, Theme.itemSizeHuge)
                    anchors.centerIn: parent
                    bars: priceFetcher.bars
                    avgPrice: priceFetcher.avgPrice
                    minPrice: priceFetcher.minPrice
                    maxPrice: priceFetcher.maxPrice
                    nowIndex: priceFetcher.nowIndex
                    cheapThreshold: appSettings.cheapThreshold
                    expensiveThreshold: appSettings.expensiveThreshold
                }
            }

            // Stats row: three mini cards
            Grid {
                id: statsGrid
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                columns: 3
                spacing: Theme.paddingMedium
                visible: priceFetcher.hasData

                Rectangle {
                    width: (statsGrid.width - 2 * statsGrid.spacing) / 3
                    height: avgColumn.height + 2 * Theme.paddingMedium
                    radius: Theme.paddingSmall
                    color: page.cardColor

                    Column {
                        id: avgColumn
                        anchors.centerIn: parent
                        spacing: 0

                        Label {
                            text: qsTr("Keskiarvo")
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            text: priceFetcher.avgPrice.toFixed(2).replace(".", ",")
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                Rectangle {
                    width: (statsGrid.width - 2 * statsGrid.spacing) / 3
                    height: minColumn.height + 2 * Theme.paddingMedium
                    radius: Theme.paddingSmall
                    color: page.cardColor

                    Column {
                        id: minColumn
                        anchors.centerIn: parent
                        spacing: 0

                        Label {
                            text: qsTr("Alin")
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            text: priceFetcher.minPrice.toFixed(2).replace(".", ",")
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                Rectangle {
                    width: (statsGrid.width - 2 * statsGrid.spacing) / 3
                    height: maxColumn.height + 2 * Theme.paddingMedium
                    radius: Theme.paddingSmall
                    color: page.cardColor

                    Column {
                        id: maxColumn
                        anchors.centerIn: parent
                        spacing: 0

                        Label {
                            text: qsTr("Ylin")
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            text: priceFetcher.maxPrice.toFixed(2).replace(".", ",")
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeMedium
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }
}
