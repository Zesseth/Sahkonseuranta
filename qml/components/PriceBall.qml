// SPDX-License-Identifier: AGPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0

// Ball whose color tells the price level plus the plain price next to
// it. The color follows the user-configured thresholds:
//   green  - at or below the cheap threshold
//   yellow - between the thresholds
//   red    - at or above the expensive threshold
Row {
    id: ball

    property double price: 0.0
    property double cheapThreshold: 2.0
    property double expensiveThreshold: 10.0
    property bool hasData: false
    property int priceFontSize: Theme.fontSizeHuge

    readonly property string greenColor: "#2ecc71"
    readonly property string yellowColor: "#f1c40f"
    readonly property string redColor: "#e74c3c"

    readonly property bool isCheap: hasData && price <= cheapThreshold
    readonly property bool isExpensive: hasData && price >= expensiveThreshold

    readonly property string stateColor: !hasData ? Theme.secondaryColor
                                   : isCheap ? greenColor
                                   : isExpensive ? redColor
                                   : yellowColor

    spacing: Theme.paddingLarge

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: ball.priceFontSize * 1.5
        height: width
        radius: width / 2
        color: ball.stateColor
        visible: ball.hasData

        // subtle ring so the ball reads well on any Ambience
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: width / 2
            color: "transparent"
            border.width: 3
            border.color: Theme.rgba(ball.stateColor, 0.4)
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Label {
            text: ball.price.toFixed(2).replace(".", ",")
            color: Theme.highlightColor
            font.pixelSize: ball.priceFontSize
            font.bold: true
            visible: ball.hasData
        }
        Label {
            text: qsTr("snt/kWh")
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeMedium
            visible: ball.hasData
        }
    }
}
