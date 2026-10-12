// SPDX-License-Identifier: AGPL-3.0-or-later
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

    // Bar width from the screen: aim for roughly 6.5 hours of quarter
    // bars or 14 hours of hourly bars visible at once, letting a
    // couple of bars run past the edge rather than squeezing tighter.
    readonly property double barWidth: {
        var barsPerScreen = appSettings.resolution === 60 ? 14 : 26
        return Math.max(plotAreaWidth / barsPerScreen, 2)
    }
    // Track the plot width explicitly to avoid binding loops with plotArea
    property double plotAreaWidth: 200
    onWidthChanged: plotAreaWidth = width - yAxisWidth
    // The initial scroll to "now" happens when bars arrive, which can
    // be before the final layout width is known; re-align once the
    // width settles so the view really starts at the current bar.
    onPlotAreaWidthChanged: {
        if (bars.length > 0 && nowIndex >= 0)
            scrollToNow()
    }
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

    // Precomputed x axis ticks: every whole hour; the midnight tick
    // carries the weekday abbreviation of the new day
    readonly property var hourTicks: {
        var ticks = []
        for (var i = 0; i < bars.length; ++i) {
            var st = bars[i].start
            if (st.getMinutes() === 0)
                ticks.push({ i: i, hour: st.getHours(), day: st.getHours() === 0 ? weekdayAbbr(st) : "" })
        }
        return ticks
    }

    function weekdayAbbr(date) {
        return [qsTr("Su"), qsTr("Ma"), qsTr("Ti"), qsTr("Ke"), qsTr("To"), qsTr("Pe"), qsTr("La")][date.getDay()]
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

    // Show the current bar as the first bar of the view so the user
    // scrolls forward from now. Accepts the index as an argument because
    // our own nowIndex binding may not have re-evaluated yet when the
    // caller's onBarsChanged fires.
    property int pendingNowIndex: -1
    function scrollToNow(idx) {
        var target = (idx === undefined) ? nowIndex : idx
        if (target < 0 || bars.length === 0)
            return
        // Defer: at data-arrival time the layout bindings (bar width,
        // content width) may not have settled yet, which used to clamp
        // the view to the start of the data instead of "now".
        pendingNowIndex = target
        scrollTimer.restart()
    }

    Timer {
        id: scrollTimer
        interval: 50
        onTriggered: {
            if (graph.pendingNowIndex < 0 || graph.bars.length === 0)
                return
            var bw = graph.barWidth
            var x = graph.pendingNowIndex * bw
            var maxX = graph.bars.length * bw - scroll.width
            scroll.contentX = Math.max(0, Math.min(x, Math.max(0, maxX)))
        }
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

        // The c/kWh unit lives in the chart caption; here only the values
        Repeater {
            model: graph.yTicks

            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                // keep the number fully inside the axis column even at
                // the very top and bottom of the value range
                y: Math.min(Math.max(yAxis.height - graph.yFromBottom(modelData) - height / 2, 0),
                            yAxis.height - height)
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
                            color: graph.barColor(model.modelData.price)
                            border.width: index === graph.nowIndex ? 2 : 0
                            border.color: Theme.primaryColor
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
                    text: modelData.day !== ""
                          ? "00 " + modelData.day
                          : ("0" + modelData.hour).slice(-2)
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeTiny
                }
            }

            // "Now" marker under the axis, scrolling with the bars
            Rectangle {
                visible: graph.nowIndex >= 0 && graph.nowIndex < graph.bars.length
                x: graph.barX(graph.nowIndex) + graph.barWidth / 2 - 4
                y: axisRow.height / 2 - 4
                width: 8
                height: 8
                radius: 1
                rotation: 45
                color: Theme.primaryColor
            }
        }
    }
}
