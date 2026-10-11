import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: graph

    property var bars: []
    property double avgPrice: 0.0
    property double minPrice: 0.0
    property double maxPrice: 0.0
    property int nowIndex: -1
    property double cheapThreshold: 2.0
    property double expensiveThreshold: 10.0

    readonly property double minV: minPrice < 0
                                   ? -Math.max(Math.abs(minPrice), Math.abs(maxPrice))
                                   : 0.0
    readonly property double maxV: Math.max(maxPrice, 0.001)
    readonly property double pxPerUnit: height / Math.max(maxV - minV, 0.001)
    readonly property double zeroFromBottom: (0.0 - minV) * pxPerUnit

    function barColor(price) {
        if (price < 0)
            return "#2ecc71"
        if (price <= cheapThreshold)
            return "#2ecc71"
        if (price >= expensiveThreshold)
            return "#e74c3c"
        return "#f1c40f"
    }

    implicitHeight: Theme.itemSizeHuge
    clip: true

    Row {
        id: barsRow
        spacing: 1
        anchors.fill: parent

        Repeater {
            model: graph.bars

            delegate: Item {
                width: (barsRow.width - barsRow.spacing * Math.max(graph.bars.length - 1, 0)) / Math.max(graph.bars.length, 1)
                height: barsRow.height

                Rectangle {
                    width: parent.width
                    y: model.modelData.price >= 0
                       ? parent.height - graph.zeroFromBottom - height
                       : parent.height - graph.zeroFromBottom
                    height: Math.min(Math.abs(model.modelData.price) * graph.pxPerUnit, parent.height)
                    radius: Math.min(2, width / 2)
                    color: index === graph.nowIndex ? Theme.primaryColor : graph.barColor(model.modelData.price)
                    opacity: index === graph.nowIndex ? 0.9 : 1.0
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: graph.zeroFromBottom + graph.avgPrice * graph.pxPerUnit - 1
        visible: graph.bars.length > 0
        color: Theme.secondaryColor
    }

    Rectangle {
        width: parent.width
        height: 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: graph.zeroFromBottom - 1
        visible: graph.minPrice < 0
        color: Theme.primaryColor
    }
}
