import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

CoverBackground {
    id: cover

    CoverPlaceholder {
        anchors.centerIn: parent
        visible: !priceFetcher.hasData
        text: priceFetcher.loading ? qsTr("Ladataan...") : qsTr("Ei tietoja")
        icon.source: "image://theme/icon-m-clock"
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.paddingMedium
        spacing: Theme.paddingSmall
        visible: priceFetcher.hasData

        Label {
            width: parent.width
            text: qsTr("Pörssisähkö nyt")
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeSmall
        }

        Label {
            width: parent.width
            text: priceFetcher.currentPrice.toFixed(2) + qsTr(" snt/kWh")
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
            truncationMode: TruncationMode.Fade
        }

        TrafficLight {
            price: priceFetcher.currentPrice
            avgPrice: priceFetcher.avgPrice
            hasData: priceFetcher.hasData
        }

        Label {
            width: parent.width
            text: priceFetcher.avgPrice > 0
                  ? qsTr("Keskihinta %1").arg(priceFetcher.avgPrice.toFixed(2))
                  : ""
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }
}
