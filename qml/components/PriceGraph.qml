import QtQuick 2.6
import Sailfish.Silica 1.0

// Scrollable bar chart of everything the API returned (today +
// tomorrow). The current bar is highlighted, the configured
// thresholds are drawn as dashed horizontal lines, the x axis labels
// whole hours and the left y axis shows the value range in whole
// cents per kWh.
Item {
    id: graph

    property var bars: []
    property int nowIndex: -1
    property double cheapThreshold: 2.0
    property double expensiveThreshold: 10.0

    // Fixed bar width: the chart scrolls when the window does not fit
    readonly property double barWidth: 8
    readonly property int xAxisHeight: 22
    readonly property int yAxisWidth: 44

    // Data-driven value range of the visible window (whole cents)
    readonly property double dataMax: {
        var m = 0.0
        for (var i = 0; i < bars.length; ++i)
            m = Math.max(m, bars[i].price)
        return m
    }
    readonly property double dataMin: {
        var m = 0.0
        for (var i = 0; i < bars.length; ++i)
            m = Math.min(m, bars[i].price)
        return m
    }
    // Nice-value scaling: top rounds up to the next whole ten
    // (a max of 28 -> 30, of 10.5 -> 20, of up to 10 -> 10); negative
    // prices extend the axis downward in steps of five cents. Zero is
    // always inside the range.
    readonly property double tickTop: dataMax <= 0.0 ? 0.0 : Math.ceil(dataMax / 10.0) * 10.0
    readonly property double tickBottom: dataMin >= 0.0 ? 0.0 : Math.floor(dataMin / 5.0) * 5.0
    readonly property double minV: tickBottom
    readonly property double maxV: Math.max(tickTop, tickBottom + 10.0)
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

    // Y axis ticks: every five cents below zero, every ten above
    readonly property var yTicks: {
        var t = []
        for (var v = tickBottom; v < 0; v += 5)
            t.push(v)
        t.push(0)
        for (var v2 = 10; v2 <= tickTop; v2 += 10)
            t.push(v2)
        return t
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

    function barX(index) {
        return index * barWidth
    }

    // Center the view on a bar index, clamped to the content bounds
    function scrollToIndex(index) {
        if (index < 0 || bars.length === 0)
            return
        var x = barX(index) + barWidth / 2 - scroll.width / 2
        scroll.contentX = Math.max(0, Math.min(x, scroll.contentWidth - scroll.width))
    }

    function scrollToNow() {
        scrollToIndex(nowIndex)
    }

    // Scroll to the first bar at or after the given time
    function scrollToDate(when) {
        for (var i = 0; i < bars.length; ++i) {
            if (bars[i].start >= when) {
                scrollToIndex(i)
                return
            }
        }
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

        Repeater {
            model: graph.yTicks

            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                y: yAxis.height - graph.yFromBottom(modelData) - height / 2
                text: modelData
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeTiny
            }
        }
    }

    // Plot area: horizontally scrollable bars
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
        clip: true

        Flickable {
            id: scroll
            anchors.fill: parent
            contentWidth: graph.bars.length * graph.barWidth
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick

            Row {
                id: barsRow
                spacing: 0
                y: 0
                height: scroll.height

                Repeater {
                    model: graph.bars

                    delegate: Item {
                        width: graph.barWidth
                        height: barsRow.height

                        Rectangle {
                            width: parent.width - 1
                            x: 0.5
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

            // Threshold dashes and the average line, scrolling with the bars
            Canvas {
                id: linesCanvas
                anchors.fill: parent
                width: scroll.contentWidth
                visible: graph.bars.length > 0

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.lineWidth = 1
                    // Qt 5.6 canvas has no setLineDash: draw the dashes by hand
                    function dashedH(color, value, dash, gap) {
                        if (value < graph.minV || value > graph.maxV)
                            return
                        var y = height - graph.yFromBottom(value)
                        ctx.strokeStyle = color
                        ctx.beginPath()
                        var x = 0
                        while (x < width) {
                            ctx.moveTo(x, y)
                            ctx.lineTo(Math.min(x + dash, width), y)
                            x += dash + gap
                        }
                        ctx.stroke()
                    }
                    function dashedV(color, x, dash, gap) {
                        ctx.strokeStyle = color
                        ctx.beginPath()
                        var y = 0
                        while (y < height) {
                            ctx.moveTo(x, y)
                            ctx.lineTo(x, Math.min(y + dash, height))
                            y += dash + gap
                        }
                        ctx.stroke()
                    }
                    // Gray grid: horizontal every five cents
                    var gridCol = Theme.rgba(Theme.secondaryColor, 0.35)
                    for (var v = graph.tickBottom; v <= graph.tickTop + 0.01; v += 5)
                        dashedH(gridCol, v, 3, 5)
                    // ...and vertical at every whole hour
                    for (var i = 0; i < graph.bars.length; ++i) {
                        if (graph.bars[i].start.getMinutes() === 0)
                            dashedV(gridCol, (i + 0.5) * graph.barWidth, 3, 5)
                    }
                    // Threshold lines on top, colored
                    dashedH(graph.barColor(graph.cheapThreshold), graph.cheapThreshold, 4, 4)
                    dashedH(graph.barColor(graph.expensiveThreshold), graph.expensiveThreshold, 4, 4)
                }

                Connections {
                    target: graph
                    onBarsChanged: linesCanvas.requestPaint()
                }
            }

        }
    }

    // X axis: hour labels positioned absolutely over their bars,
    // following the scroll position
    Item {
        id: axisRow
        anchors {
            left: plotArea.left
            right: plotArea.right
            bottom: parent.bottom
        }
        height: graph.xAxisHeight
        clip: true

        Item {
            x: -scroll.contentX
            width: Math.max(graph.bars.length * graph.barWidth, axisRow.width)
            height: parent.height

            Repeater {
                model: graph.hourTicks

                Label {
                    visible: modelData.i < graph.bars.length
                    x: graph.barX(modelData.i) + graph.barWidth / 2 - width / 2
                    y: 0
                    text: ("0" + modelData.hour).slice(-2)
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeTiny
                }
            }
        }
    }
}
