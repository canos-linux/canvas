import QtQuick
import "../core"

Icon {
    id: spin
    property bool running: visible
    text: "󰑓"
    hoverable: false
    color: Theme.accent
    RotationAnimator on rotation {
        running: spin.running
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
    }
}
