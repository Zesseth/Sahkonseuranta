import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    property int dayOffset: 0

    Component.onCompleted: priceFetcher.refresh()

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
        }

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingMedium

            PageHeader {
                id: header
                title: dayOffset === 0 ? qsTr("Pörssisähkö tänään") : qsTr("Pörssisähkö huomenna")
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingMedium

                Column {
                    id: priceColumn
                    spacing: Theme.paddingSmall

                    Label {
                        text: priceFetcher.hasData
                              ? priceFetcher.currentPrice.toFixed(2).replace(".", ",") + qsTr(" snt/kWh")
                              : (priceFetcher.loading ? qsTr("Ladataan...") : qsTr("Ei tietoja"))
                        color: priceFetcher.hasData ? Theme.highlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraLarge
                    }

                    Label {
                        visible: dayOffset === 0
                        text: qsTr("Nyt")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                TrafficLight {
                    anchors.bottom: priceColumn.bottom
                    price: priceFetcher.currentPrice
                    avgPrice: priceFetcher.avgPrice
                    hasData: priceFetcher.hasData && dayOffset === 0
                }
            }

            Row {
                id: resRow
                spacing: Theme.paddingSmall
                x: Theme.horizontalPageMargin

                Rectangle {
                    width: Theme.itemSizeExtraSmall * 1.6
                    height: Theme.itemSizeSmall
                    radius: Theme.paddingSmall
                    color: priceFetcher.resolution === 15 ? Theme.highlightBackgroundColor : Theme.secondaryHighlightColor
                    opacity: priceFetcher.resolution === 15 ? 1.0 : 0.5

                    Label {
                        anchors.centerIn: parent
                        text: "15 min"
                        color: priceFetcher.resolution === 15 ? Theme.highlightColor : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    MouseArea { anchors.fill: parent; onClicked: priceFetcher.resolution = 15 }
                }

                Rectangle {
                    width: Theme.itemSizeExtraSmall * 1.6
                    height: Theme.itemSizeSmall
                    radius: Theme.paddingSmall
                    color: priceFetcher.resolution === 60 ? Theme.highlightBackgroundColor : Theme.secondaryHighlightColor
                    opacity: priceFetcher.resolution === 60 ? 1.0 : 0.5

                    Label {
                        anchors.centerIn: parent
                        text: "1 h"
                        color: priceFetcher.resolution === 60 ? Theme.highlightColor : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    MouseArea { anchors.fill: parent; onClicked: priceFetcher.resolution = 60 }
                }
            }

            PriceGraph {
                id: graph
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: Math.max(page.height * 0.4, Theme.itemSizeHuge)
                visible: priceFetcher.hasData
                bars: priceFetcher.bars
                avgPrice: priceFetcher.avgPrice
                minPrice: priceFetcher.minPrice
                maxPrice: priceFetcher.maxPrice
                nowIndex: priceFetcher.nowIndex
            }

            Grid {
                id: statsGrid
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                columns: 3
                spacing: Theme.paddingMedium
                visible: priceFetcher.hasData

                Column {
                    width: (statsGrid.width - 2 * statsGrid.spacing) / 3
                    spacing: 0

                    Label {
                        text: qsTr("Keskiarvo")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    Label {
                        text: priceFetcher.avgPrice.toFixed(2).replace(".", ",")
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeMedium
                    }
                }

                Column {
                    width: (statsGrid.width - 2 * statsGrid.spacing) / 3
                    spacing: 0

                    Label {
                        text: qsTr("Alin")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    Label {
                        text: priceFetcher.minPrice.toFixed(2).replace(".", ",")
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeMedium
                    }
                }

                Column {
                    width: (statsGrid.width - 2 * statsGrid.spacing) / 3
                    spacing: 0

                    Label {
                        text: qsTr("Ylin")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    Label {
                        text: priceFetcher.maxPrice.toFixed(2).replace(".", ",")
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeMedium
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: !priceFetcher.hasData && !priceFetcher.loading && priceFetcher.errorString !== ""
                text: priceFetcher.errorString
                color: Theme.errorColor
                wrapMode: Text.WordWrap
            }
        }
    }
}
