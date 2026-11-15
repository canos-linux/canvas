import QtQuick
import "../core"
import "../services"
import "../ui"

Item {
    Row {
        anchors.centerIn: parent
        spacing: 12

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: Brightness.value > 0.66 ? "󰃠" : Brightness.value > 0.33 ? "󰃟" : "󰃞"
            size: 20
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: 180
            value: Brightness.value
            onMoved: v => Brightness.set(v)
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            horizontalAlignment: Text.AlignRight
            text: Math.round(Brightness.value * 100) + "%"
            weight: Font.Medium
        }
    }
}
