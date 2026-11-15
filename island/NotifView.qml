import QtQuick
import "../core"
import "../ui"

Item {
    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 22
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Row {
            spacing: 7
            Icon {
                text: "󰂚"
                size: 14
                color: Theme.accent
                hoverable: false
            }
            Txt {
                text: IslandState.notifApp + "  ·  jetzt"
                size: 12
                color: Theme.subtext
            }
        }
        Txt {
            width: parent.width
            text: IslandState.notifTitle
            size: 15
            weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Txt {
            width: parent.width
            text: IslandState.notifBody
            size: 13
            color: Theme.subtext
            elide: Text.ElideRight
        }
    }
}
