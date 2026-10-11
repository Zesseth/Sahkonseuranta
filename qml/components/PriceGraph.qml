import QtQuick 2.6
import Sailfish.Silica 1.0

// Bar chart of the day's prices. The current bar is highlighted, the
// configured thresholds are drawn as dashed horizontal lines, the
// x axis labels whole hours and the y axis shows the value range in
// cents per kWh.
Item {
    id: graph

    property var bars: []
    property double avgPrice: 0.0
    property double minPrice: 0.0
    property double maxPrice: 0.0
    property int nowIndex: -1
    property double cheapThreshold: 2.0
    property double expensiveThreshold: 10.0

    readonly property int axisHeight: 22
    readonly property double minV: minPrice < 0
                                   ? -Math.max(Math.abs(minPrice), Math.abs(maxPrice))
                                   : 0.0
    readonly property double maxV: Math.max(maxPrice, 0.001)
    readonly property double plotHeight: height - axisHeight
    readonly property double pxPerUnit: plotHeight / Math.max(maxV - minV, 0.001)
    readonly property double zeroFromBottom: (0.0 - minV) * pxPerUnit

    function yFromBottom(value) {
        return zeroFromBottom + value * pxPerUnit
    }

    function barColor(price) {
        if (price <= cheapThreshold)
            return "#2ecc71"
        if (price >= expensiveThreshold)
            return "#e74c3c"
        return "#f1c40f"
    }

    // Whole-hour labels: show every third hour to keep them readable
    function hourLabelStart(index) {
        var st = bars[index].start
        return st
    }
    function showHourLabel(index) {
        var st = bars[index].start
        return st.getMinutes() === 0 && (st.getHours() % 3) === 0
    }

    implicitHeight: Theme.itemSizeHuge
    clip: true

    // Bars
    Row {
        id: barsRow
        spacing: 0
        x: 0
        y: 0
        width: parent.width
        height: graph.plotHeight

        Repeater {
            model: graph.bars

            delegate: Item {
                width: barsRow.width / Math.max(graph.bars.length, 1)
                height: barsRow.height

                Rectangle {
                    width: parent.width
                    y: model.modelData.price >= 0
                       ? parent.height - graph.yFromBottom(model.modelData.price)
                       : parent.height - graph.zeroFromBottom
                    height: Math.min(Math.abs(model.modelData.price) * graph.pxPerUnit, parent.height)
                    radius: Math.min(3, width / 2)
                    color: index === graph.nowIndex ? Theme.primaryColor : graph.barColor(model.modelData.price)
                    opacity: index === graph.nowIndex ? 0.95 : 1.0
                }
            }
        }
    }

    // Dashed threshold lines and the average line, drawn once per data change
    Canvas {
        id: linesCanvas
        anchors.fill: parent
        visible: graph.bars.length > 0

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.lineWidth = 1
            // Qt 5.6 canvas has no setLineDash: draw the dashes by hand
            function dashed(color, value) {
                if (value < graph.minV || value > graph.maxV)
                    return
                var y = height - graph.yFromBottom(value)
                ctx.strokeStyle = color
                ctx.beginPath()
                var x = 0
                while (x < width) {
                    ctx.moveTo(x, y)
                    ctx.lineTo(Math.min(x + 4, width), y)
                    x += 8
                }
                ctx.stroke()
            }
            dashed(graph.barColor(graph.cheapThreshold), graph.cheapThreshold)
            dashed(graph.barColor(graph.expensiveThreshold), graph.expensiveThreshold)
            // solid average line
            var yAvg = height - graph.yFromBottom(graph.avgPrice)
            ctx.strokeStyle = Theme.rgba(Theme.secondaryColor, 0.8)
            ctx.beginPath()
            ctx.moveTo(0, yAvg)
            ctx.lineTo(width, yAvg)
            ctx.stroke()
        }

        Connections {
            target: graph
            onBarsChanged: linesCanvas.requestPaint()
            onAvgPriceChanged: linesCanvas.requestPaint()
        }
    }

    // Zero line when there are negative prices
    Rectangle {
        width: parent.width
        height: 1
        y: graph.plotHeight - graph.zeroFromBottom
        visible: graph.bars.length > 0 && graph.minPrice < 0
        color: Theme.secondaryColor
    }

    // Y axis: value range labels (c/kWh)
    Label {
        x: 0
        y: 0
        text: graph.maxPrice.toFixed(1).replace(".", ",")
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeTiny
    }
    Label {
        x: 0
        y: graph.plotHeight - graph.zeroFromBottom - height / 2
        visible: graph.minPrice < 0
        text: "0"
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeTiny
    }

    // X axis: whole-hour labels
    Row {
        id: hourAxis
        x: 0
        y: graph.plotHeight
        width: parent.width
        height: graph.axisHeight

        Repeater {
            model: graph.bars.length

            delegate: Item {
                width: hourAxis.width / Math.max(graph.bars.length, 1)
                height: hourAxis.height
                visible: index >= 0 && index < graph.bars.length && graph.showHourLabel(index)

                Label {
                    x: -width / 2
                    y: 0
                    text: graph.bars.length > index
                          ? ("0" + graph.bars[index].start.getHours()).slice(-2)
                          : ""
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeTiny
                }
            }
        }
    }
}
