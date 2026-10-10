import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: light

    property double price: 0.0
    property double avgPrice: 0.0
    property bool hasData: false

    readonly property string greenColor: "#2ecc71"
    readonly property string yellowColor: "#f1c40f"
    readonly property string redColor: "#e74c3c"

    readonly property bool isCheap: hasData && (price <= avgPrice || price < 0)
    readonly property bool isNormal: hasData && !isCheap && avgPrice > 0 && price <= avgPrice * 2.0
    readonly property bool isExpensive: hasData && !isCheap && !isNormal

    readonly property string stateColor: isCheap ? greenColor
                                       : isNormal ? yellowColor
                                       : isExpensive ? redColor
                                       : Theme.secondaryColor

    readonly property string stateText: isCheap ? qsTr("Halpa")
                                   : isNormal ? qsTr("Normaali")
                                   : isExpensive ? qsTr("Kallis")
                                   : ""

    implicitWidth: Math.max(Theme.itemSizeSmall, label.implicitWidth + Theme.paddingMedium)
    implicitHeight: Theme.itemSizeSmall

    Row {
        anchors.centerIn: parent
        spacing: Theme.paddingSmall

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.itemSizeExtraSmall * 0.7
            height: width
            radius: width / 2
            color: light.stateColor
            visible: light.hasData
        }

        Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            text: light.stateText
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeMedium
            visible: light.hasData
        }
    }
}
