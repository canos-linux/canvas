import QtQuick
import Quickshell
import "../../core"
import "."

Pill {
    icon: "󰒓"
    iconColor: Theme.accent
    iconItem.rotation: iconHover.hovered ? 90 : 0
    Behavior on iconItem.rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

    HoverHandler { id: iconHover }
    TapHandler {
        onTapped: Quickshell.execDetached(["xdg-open", Config.path])
    }
}
