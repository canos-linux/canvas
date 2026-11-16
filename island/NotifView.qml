import QtQuick
import "../core"
import "../ui"
import "../services"
import Quickshell.Widgets

Item {
    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 22
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Row {
            spacing: 7
            Item {
                width: 14
                height: 14
                readonly property string src: IslandState.notifEntry ? Notifs.iconSource(IslandState.notifEntry.icon) : ""
                IconImage { anchors.fill: parent; visible: parent.src !== ""; source: parent.src }
                Icon { anchors.centerIn: parent; visible: parent.src === ""; text: "󰂚"; size: 14; color: Theme.accent; hoverable: false }
            }
            Txt {
                text: IslandState.notifApp + "  ·  " + Lang.t.now
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
