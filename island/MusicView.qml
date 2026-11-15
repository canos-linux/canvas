import QtQuick
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"

Item {
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        ClippingRectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: 18
            color: Theme.surfaceHigh
            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                RotationAnimation on rotation {
                    running: Media.playing
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 12000
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            Txt {
                width: 180
                text: Media.title
                weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Txt {
                width: 180
                text: Media.artist
                size: 12
                color: Theme.subtext
                elide: Text.ElideRight
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Visualizer {
            anchors.verticalCenter: parent.verticalCenter
            maxHeight: 22
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: Media.playing ? "󰏤" : "󰐊"
            size: 22
            color: Theme.accent
            onClicked: Media.toggle()
        }
    }
}
