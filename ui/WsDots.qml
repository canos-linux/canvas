import QtQuick
import "../core"
import "../services"

Row {
    property bool clickable: true
    spacing: 7
    Repeater {
        model: 5
        Rectangle {
            property int num: index + 1
            property bool isActive: Hypr.active === num
            anchors.verticalCenter: parent.verticalCenter
            width: isActive ? 34 : dotHover.hovered ? 18 : 12
            height: 12
            radius: 6
            color: isActive ? Theme.accent : Hypr.occupied.indexOf(num) !== -1 ? Theme.subtext : Theme.surfaceHigh
            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 250 } }
            HoverHandler { id: dotHover }
            TapHandler {
                gesturePolicy: TapHandler.ReleaseWithinBounds
                enabled: parent.parent.clickable
                onTapped: Hypr.focus(num)
            }
        }
    }
}
