import QtQuick
import Quickshell
import "../core"

Text {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    anchors.verticalCenter: parent.verticalCenter
    text: Qt.formatDateTime(clock.date, "ddd dd.MM.   HH:mm")
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: 14
    font.weight: Font.DemiBold
}
