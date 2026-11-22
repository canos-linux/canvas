import QtQuick
import "../core"
import "../services"

Item {
    id: btn
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()
    width: 64
    height: 70

    Rectangle {
        id: circle
        anchors.horizontalCenter: parent.horizontalCenter
        width: 48
        height: 48
        radius: 24
        color: btn.active ? Theme.accent : hov.hovered ? Theme.alpha(Theme.accent, 0.25) : Theme.card
        scale: tap.pressed ? 0.88 : hov.hovered ? 1.1 : 1
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

        Icon {
            id: glyph
            anchors.centerIn: parent
            text: btn.icon
            size: 21
            hoverable: false
            color: btn.active ? Theme.base : Theme.text
        }

        SequentialAnimation {
            running: hov.hovered
            NumberAnimation { target: glyph; property: "rotation"; to: -14; duration: 90 }
            NumberAnimation { target: glyph; property: "rotation"; to: 12; duration: 120 }
            NumberAnimation { target: glyph; property: "rotation"; to: 0; duration: 160; easing.type: Easing.OutBack }
        }
    }

    Txt {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: btn.label
        size: 11
        color: hov.hovered ? Theme.text : Theme.subtext
    }

    HoverHandler { id: hov }
    TapHandler { id: tap; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: { Sounds.play("click"); btn.clicked() } }
}
