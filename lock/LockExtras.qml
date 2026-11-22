import QtQuick
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"

// lock screen 2.0: music, weather and notifications
Item {
    id: ex

    // weather, top right
    Row {
        visible: Weather.ok && Config.opt.lockWeather
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 36
        spacing: 12
        Icon { anchors.verticalCenter: parent.verticalCenter; text: Weather.icon; size: 34; color: Theme.accent; hoverable: false }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Txt { text: Math.round(Weather.temp) + "°  " + Weather.label; size: 17; weight: Font.DemiBold }
            Txt { text: Weather.place; size: 12; color: Theme.subtext }
        }
    }

    // music, bottom left
    Rectangle {
        visible: Media.player !== null && Config.opt.lockMusic
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 36
        anchors.bottomMargin: 96
        width: 360
        height: 96
        radius: 28
        color: Theme.alpha(Theme.base, 0.6)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.25)
        ClippingRectangle {
            id: art
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 64
            height: 64
            radius: 16
            color: Theme.surfaceHigh
            Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        }
        Column {
            anchors.left: art.right
            anchors.leftMargin: 14
            anchors.right: ctl.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            Txt { width: parent.width; text: Media.title; weight: Font.DemiBold; elide: Text.ElideRight }
            Txt { width: parent.width; text: Media.artist; size: 12; color: Theme.subtext; elide: Text.ElideRight }
        }
        Row {
            id: ctl
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            Icon { text: "󰒮"; size: 20; onClicked: Media.previous() }
            Icon { text: Media.playing ? "󰏤" : "󰐊"; size: 24; color: Theme.accent; onClicked: Media.toggle() }
            Icon { text: "󰒭"; size: 20; onClicked: Media.next() }
        }
    }

    // notifications, bottom right (only app + title, nothing private from the body)
    Column {
        visible: Notifs.history.length > 0 && Config.opt.lockNotifs
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 36
        anchors.bottomMargin: 96
        spacing: 8
        Repeater {
            model: Notifs.sorted.slice(0, 3)
            Rectangle {
                required property var modelData
                width: 300
                height: 52
                radius: 18
                color: Theme.alpha(Theme.base, 0.6)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.2)
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    Txt { width: parent.width; text: modelData.app; size: 11; color: Theme.accent; elide: Text.ElideRight }
                    Txt { width: parent.width; text: modelData.title; size: 13; weight: Font.DemiBold; elide: Text.ElideRight }
                }
            }
        }
        Txt {
            visible: Notifs.history.length > 3
            anchors.right: parent.right
            text: "+" + (Notifs.history.length - 3)
            size: 12
            color: Theme.subtext
        }
    }
}
