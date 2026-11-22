import QtQuick
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"

Item {
    id: big

    function fmt(s) {
        s = Math.max(0, Math.floor(s))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    ClippingRectangle {
        id: cover
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.top: parent.top
        anchors.topMargin: 18
        width: 84
        height: 84
        radius: 18
        color: Theme.surfaceHigh
        Image {
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Icon {
            anchors.centerIn: parent
            visible: Media.art === ""
            text: "󰎆"
            size: 34
            color: Theme.accent
            hoverable: false
        }
    }

    Column {
        anchors.left: cover.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.top: cover.top
        anchors.topMargin: 6
        spacing: 2
        Txt {
            width: parent.width - 50
            text: Media.title
            size: 16
            weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Txt {
            width: parent.width - 50
            text: Media.artist
            size: 13
            color: Theme.subtext
            elide: Text.ElideRight
        }
    }

    Visualizer {
        visible: Config.opt.visualizer
        anchors.right: parent.right
        anchors.rightMargin: 22
        anchors.top: parent.top
        anchors.topMargin: 30
        maxHeight: 20
    }

    Row {
        anchors.left: cover.right
        anchors.leftMargin: 14
        anchors.bottom: cover.bottom
        anchors.bottomMargin: -2
        spacing: 22
        Icon { text: "󰒮"; size: 24; onClicked: { Sounds.play("click"); Media.previous() } }
        Icon { text: Media.playing ? "󰏤" : "󰐊"; size: 28; color: Theme.accent; onClicked: { Sounds.play("click"); Media.toggle() } }
        Icon { text: "󰒭"; size: 24; onClicked: { Sounds.play("click"); Media.next() } }
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 18
        anchors.bottomMargin: 16
        height: 30
        visible: Media.length > 0

        Txt {
            id: posTxt
            anchors.left: parent.left
            anchors.verticalCenter: bar.verticalCenter
            text: big.fmt(Media.position)
            size: 11
            color: Theme.subtext
        }
        Rectangle {
            id: bar
            anchors.left: posTxt.right
            anchors.right: lenTxt.left
            anchors.margins: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 5
            radius: 3
            color: Theme.surfaceHigh
            Rectangle {
                width: parent.width * Math.min(1, Media.length > 0 ? Media.position / Media.length : 0)
                height: parent.height
                radius: 3
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 380 } }
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                onClicked: mouse => Media.seek(Math.max(0, Math.min(1, (mouse.x - 8) / bar.width)))
            }
        }
        Txt {
            id: lenTxt
            anchors.right: parent.right
            anchors.verticalCenter: bar.verticalCenter
            text: big.fmt(Media.length)
            size: 11
            color: Theme.subtext
        }
    }
}
