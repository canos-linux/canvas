import QtQuick
import "../core"

Rectangle {
    id: pill
    property string icon: ""
    property string text: ""
    property bool primary: false
    property bool active: false
    signal clicked()

    implicitWidth: row.implicitWidth + 26
    implicitHeight: 34
    radius: height / 2
    color: primary ? (hov.hovered ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
         : active ? Theme.alpha(Theme.accent, hov.hovered ? 0.32 : 0.2)
         : hov.hovered ? Theme.surfaceHigh : Theme.card
    scale: tap.pressed ? 0.93 : 1
    Behavior on color { ColorAnimation { duration: Theme.dur(180) } }
    Behavior on scale { NumberAnimation { duration: Theme.dur(160); easing.type: Easing.OutBack } }

    HoverHandler { id: hov }
    TapHandler { id: tap; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: pill.clicked() }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7
        Icon {
            visible: pill.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: pill.icon
            size: 16
            hoverable: false
            color: pill.primary ? Theme.base : pill.active ? Theme.accent : Theme.text
        }
        Txt {
            visible: pill.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: pill.text
            size: 13
            weight: Font.Medium
            color: pill.primary ? Theme.base : Theme.text
        }
    }
}
