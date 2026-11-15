import QtQuick
import "../core"

Rectangle {
    id: tile
    property string icon: ""
    property string title: ""
    property string sub: ""
    property bool active: false
    signal clicked()

    implicitHeight: 64
    radius: 20
    color: active ? Theme.alpha(Theme.accent, hov.hovered ? 0.32 : 0.2) : hov.hovered ? Theme.surfaceHigh : Theme.surface
    scale: tap.pressed ? 0.94 : 1
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

    HoverHandler { id: hov }
    TapHandler { id: tap; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: tile.clicked() }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: tile.icon
            size: 22
            hoverable: false
            color: tile.active ? Theme.accent : Theme.text
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            Txt {
                text: tile.title
                weight: Font.DemiBold
            }
            Txt {
                width: tile.width - 62
                text: tile.sub
                size: 12
                color: Theme.subtext
                elide: Text.ElideRight
            }
        }
    }
}
