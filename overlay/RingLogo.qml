import QtQuick

// CanOS ring "C" with dot; progress 0..1 draws the ring
Canvas {
    id: logo
    property color tint: "#cdbdff"
    property real progress: 1
    width: 110
    height: 110
    onTintChanged: requestPaint()
    onProgressChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const r = width * 0.38
        const a0 = Math.PI * 0.22, a1 = Math.PI * 1.78
        ctx.lineWidth = width * 0.075
        ctx.lineCap = "round"
        ctx.strokeStyle = tint
        if (progress > 0.01) {
            ctx.beginPath()
            ctx.arc(width / 2, height / 2, r, a0, a0 + (a1 - a0) * Math.min(1, progress))
            ctx.stroke()
        }
        if (progress >= 0.98) {
            ctx.fillStyle = tint
            ctx.beginPath()
            ctx.arc(width / 2 + r, height / 2, width * 0.06, 0, Math.PI * 2)
            ctx.fill()
        }
    }
}
