import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../core"

Row {
    id: tray
    property var barWindow
    property bool shown: SystemTray.items.values.length > 0
    spacing: 10

    Repeater {
        model: SystemTray.items
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20

            IconImage {
                anchors.fill: parent
                source: modelData.icon
                scale: itemHover.hovered ? 1.2 : 1
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            }

            HoverHandler { id: itemHover }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                        modelData.activate()
                    } else if (modelData.hasMenu && tray.barWindow) {
                        const p = mapToItem(null, 0, height)
                        modelData.display(tray.barWindow, p.x, p.y + 8)
                    }
                }
            }
        }
    }
}
