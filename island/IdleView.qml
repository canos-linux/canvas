import QtQuick
import Quickshell
import "../core"
import "../services"
import "../ui"

Item {
    id: idle
    property bool hovered: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        anchors.centerIn: parent
        spacing: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: Power.low ? "#ff6b6b" : Theme.accent
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 1400; easing.type: Easing.InOutSine }
            }
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: idle.hovered ? clock.date.toLocaleString(Lang.locale, Lang.t.dateShort) + "   " + Qt.formatTime(clock.date, "HH:mm") : Qt.formatTime(clock.date, "HH:mm")
            size: 15
            weight: Font.DemiBold
        }
    }
}
