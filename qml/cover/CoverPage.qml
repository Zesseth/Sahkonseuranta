// SPDX-License-Identifier: AGPL-3.0-or-later
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

        PriceBall {
            price: priceFetcher.displayPrice
            cheapThreshold: appSettings.cheapThreshold
            expensiveThreshold: appSettings.expensiveThreshold
            hasData: priceFetcher.hasData
            priceFontSize: Theme.fontSizeLarge
        }

        Label {
            width: parent.width
            visible: priceFetcher.hasData
            text: qsTr("Keskihinta %1")
                  .arg(priceFetcher.avgPrice.toFixed(2).replace(".", ","))
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }
}
