import QtQuick
import "../core"
import "../services"
import "../ui"

Item {
    Row {
        anchors.centerIn: parent
        spacing: 10
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: "#ff5c5c"
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: "REC  " + Recorder.time
            size: 14
            weight: Font.DemiBold
        }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰓛"
            size: 18
            color: Theme.accent
            onClicked: Recorder.stop()
        }
    }
}
