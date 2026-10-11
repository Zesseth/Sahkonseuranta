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

            PriceBall {
                x: Theme.horizontalPageMargin
                visible: priceFetcher.hasData && dayOffset === 0
                price: priceFetcher.displayPrice
                cheapThreshold: appSettings.cheapThreshold
                expensiveThreshold: appSettings.expensiveThreshold
                hasData: priceFetcher.hasData
                priceFontSize: Theme.fontSizeExtraLarge
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: !priceFetcher.hasData
                text: priceFetcher.loading ? qsTr("Ladataan...") : qsTr("Ei tietoja")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }

            Label {
                x: Theme.horizontalPageMargin
                visible: priceFetcher.hasData && dayOffset === 0
                text: qsTr("Nyt")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
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
                cheapThreshold: appSettings.cheapThreshold
                expensiveThreshold: appSettings.expensiveThreshold
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
