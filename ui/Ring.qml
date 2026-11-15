import QtQuick
import "../core"

Item {
    id: ring
    property real value: 0
    property real shown: 0
    property string label: ""
    property string text: ""
    property color tint: Theme.accent
    width: 58
    height: 74

    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    onValueChanged: shown = Math.max(0, Math.min(1, value))
    onShownChanged: canvas.requestPaint()
    onTintChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        width: 58
        height: 58
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.lineWidth = 5
            ctx.lineCap = "round"
            ctx.strokeStyle = Theme.surfaceHigh
            ctx.beginPath()
            ctx.arc(29, 29, 24, 0.75 * Math.PI, 2.25 * Math.PI)
            ctx.stroke()
            ctx.strokeStyle = ring.tint
            ctx.beginPath()
            ctx.arc(29, 29, 24, 0.75 * Math.PI, (0.75 + 1.5 * ring.shown) * Math.PI)
            ctx.stroke()
        }
    }

    Txt {
        anchors.centerIn: canvas
        text: ring.text
        size: 13
        weight: Font.DemiBold
    }

    Txt {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: ring.label
        size: 11
        color: Theme.subtext
    }
}
