import QtQuick 2.6
import Sailfish.Silica 1.0

// Bar chart of the day's prices. The current bar is highlighted, the
// configured thresholds are drawn as dashed horizontal lines, the
// x axis labels whole hours and the left y axis shows the value range
// in cents per kWh.
Item {
    id: graph

    property var bars: []
    property double avgPrice: 0.0
    property double minPrice: 0.0
    property double maxPrice: 0.0
    property int nowIndex: -1
    property double cheapThreshold: 2.0
    property double expensiveThreshold: 10.0

    readonly property int xAxisHeight: 22
    readonly property int yAxisWidth: 40

    readonly property double minV: minPrice < 0
                                   ? -Math.max(Math.abs(minPrice), Math.abs(maxPrice))
                                   : 0.0
    readonly property double maxV: Math.max(maxPrice, 0.001)
    readonly property double pxPerUnit: plotArea.height / Math.max(maxV - minV, 0.001)
    readonly property double zeroFromBottom: (0.0 - minV) * pxPerUnit

    // Precomputed x axis ticks: whole hours, every third hour
    readonly property var hourTicks: {
        var ticks = []
        for (var i = 0; i < bars.length; ++i) {
            var st = bars[i].start
            if (st.getMinutes() === 0 && st.getHours() % 3 === 0)
                ticks.push({ i: i, hour: st.getHours() })
        }
        return ticks
    }
    // Precomputed y axis ticks: top, middle and bottom values
    readonly property var yTicks: {
        var lo = minPrice < 0 ? minV : 0.0
        return [maxV, (maxV + lo) / 2, lo]
    }

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

    function fmtTick(value) {
        return value.toFixed(1).replace(".", ",")
    }

    implicitHeight: Theme.itemSizeHuge
    clip: true

    // Y axis column on the left
    Item {
        id: yAxis
        anchors {
            top: parent.top
            left: parent.left
            bottom: axisRow.top
        }
        width: graph.yAxisWidth

        Label {
            anchors.top: parent.top
            anchors.right: parent.right
            text: qsTr("c/kWh")
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeTiny
        }
        Label {
            anchors.top: parent.top
            anchors.topMargin: Theme.fontSizeTiny + 2
            anchors.right: parent.right
            text: graph.fmtTick(graph.yTicks.length > 0 ? graph.yTicks[0] : 0)
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeTiny
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            text: graph.fmtTick(graph.yTicks.length > 1 ? graph.yTicks[1] : 0)
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeTiny
        }
        Label {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            text: graph.fmtTick(graph.yTicks.length > 2 ? graph.yTicks[2] : 0)
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeTiny
        }
    }

    // Plot area: bars, threshold lines, average line, zero line
    Item {
        id: plotArea
        anchors {
            top: parent.top
            left: parent.left
            leftMargin: graph.yAxisWidth
            right: parent.right
            bottom: parent.bottom
            bottomMargin: graph.xAxisHeight
        }

        Row {
            id: barsRow
            spacing: 0
            anchors.fill: parent

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

        Rectangle {
            width: parent.width
            height: 1
            y: plotArea.height - graph.zeroFromBottom
            visible: graph.bars.length > 0 && graph.minPrice < 0
            color: Theme.secondaryColor
        }
    }

    // X axis: hour labels positioned absolutely over their bars
    Item {
        id: axisRow
        anchors {
            left: plotArea.left
            right: plotArea.right
            bottom: parent.bottom
        }
        height: graph.xAxisHeight

        Repeater {
            model: graph.hourTicks

            Label {
                visible: modelData.i < graph.bars.length
                x: (modelData.i * axisRow.width / Math.max(graph.bars.length, 1)) - width / 2
                y: 0
                text: ("0" + modelData.hour).slice(-2)
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeTiny
            }
        }
    }
}
