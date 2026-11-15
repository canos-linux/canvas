import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../core"
import "../services"
import "../ui"

Item {
    id: center
    property var win

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 16

        Item {
            width: parent.width
            height: 56

            Column {
                Txt {
                    text: Qt.formatTime(clock.date, "HH:mm")
                    size: 32
                    weight: Font.Bold
                }
                Txt {
                    text: clock.date.toLocaleString(Qt.locale("de_AT"), "dddd, d. MMMM")
                    size: 13
                    color: Theme.subtext
                }
            }

            Row {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 6
                spacing: 14

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7
                    BatteryIcon { anchors.verticalCenter: parent.verticalCenter }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Power.percent + "%"
                        weight: Font.Medium
                    }
                }

                Icon {
                    id: gear
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰒓"
                    size: 20
                    color: Theme.accent
                    rotation: gearHover.hovered ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                    HoverHandler { id: gearHover }
                    onClicked: Quickshell.execDetached(["xdg-open", Config.path])
                }
            }
        }

        Row {
            width: parent.width
            spacing: 10
            Tile {
                width: (parent.width - 20) / 3
                icon: Net.icon
                title: "WLAN"
                sub: Net.label
                active: Net.connected
                onClicked: Net.openSettings()
            }
            Tile {
                width: (parent.width - 20) / 3
                icon: Bt.icon
                title: "Bluetooth"
                sub: Bt.label
                active: Bt.powered
                onClicked: Bt.toggle()
            }
            Tile {
                width: (parent.width - 20) / 3
                icon: "󰌌"
                title: "Tastatur"
                sub: Hypr.layout
                active: true
                onClicked: Hypr.nextLayout()
            }
        }

        Row {
            width: parent.width
            spacing: 12
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.icon
                size: 21
                color: Audio.muted ? Theme.subtext : Theme.text
                onClicked: Audio.toggleMute()
            }
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 90
                value: Audio.muted ? 0 : Audio.volume
                onMoved: v => Audio.setVolume(v)
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                horizontalAlignment: Text.AlignRight
                text: Math.round(Audio.volume * 100) + "%"
                weight: Font.Medium
            }
        }

        Rectangle {
            visible: Media.player !== null
            width: parent.width
            height: 70
            radius: 22
            color: Theme.surface

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                ClippingRectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 46
                    height: 46
                    radius: 14
                    color: Theme.surfaceHigh
                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Txt {
                        width: 200
                        text: Media.title
                        weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Txt {
                        width: 200
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
                    maxHeight: 24
                }
                Icon { anchors.verticalCenter: parent.verticalCenter; text: "󰒮"; onClicked: Media.previous() }
                Icon { anchors.verticalCenter: parent.verticalCenter; text: Media.playing ? "󰏤" : "󰐊"; size: 24; color: Theme.accent; onClicked: Media.toggle() }
                Icon { anchors.verticalCenter: parent.verticalCenter; text: "󰒭"; onClicked: Media.next() }
            }
        }

        Row {
            width: parent.width
            spacing: 12
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰃠"
                size: 21
                onClicked: Brightness.set(Brightness.value > 0.5 ? 0.3 : 1)
            }
            Slider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 90
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                horizontalAlignment: Text.AlignRight
                text: Math.round(Brightness.value * 100) + "%"
                weight: Font.Medium
            }
        }

        Item {
            width: parent.width
            height: 74

            Row {
                spacing: 6
                Ring { label: "CPU"; value: Sys.cpu; text: Math.round(Sys.cpu * 100) + "%" }
                Ring { label: "RAM"; value: Sys.ram; text: Math.round(Sys.ram * 100) + "%" }
                Ring {
                    label: "Temp"
                    value: (Sys.temp - 30) / 60
                    text: Math.round(Sys.temp) + "°"
                    tint: Sys.temp > 80 ? "#ff6b6b" : Theme.accent
                }
            }

            Column {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                WsDots { anchors.right: parent.right }

                Row {
                    anchors.right: parent.right
                    spacing: 12
                    Repeater {
                        model: SystemTray.items
                        Item {
                            width: 20
                            height: 20
                            IconImage {
                                anchors.fill: parent
                                source: modelData.icon
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                                        modelData.activate()
                                    } else if (modelData.hasMenu) {
                                        const p = mapToItem(null, 0, height)
                                        modelData.display(center.win, p.x, p.y + 8)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: (parent.width - 5 * 64) / 4

            RoundButton {
                icon: "󰹑"
                label: "Screenshot"
                onClicked: {
                    center.win.expanded = false
                    Quickshell.execDetached(["sh", "-c", "sleep 0.6; mkdir -p ~/Pictures/Screenshots; f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png; grim \"$f\" && wl-copy < \"$f\" && notify-send 'Screenshot' 'Gespeichert und kopiert'"])
                }
            }
            RoundButton {
                icon: "󰏘"
                label: "Themes"
                onClicked: {
                    center.win.expanded = false
                    Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme-picker"])
                }
            }
            RoundButton {
                icon: "󰊴"
                label: "Gacha"
                onClicked: {
                    center.win.expanded = false
                    Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme-gacha"])
                }
            }
            RoundButton {
                icon: IslandState.dnd ? "󰂛" : "󰂚"
                label: "Ruhe"
                active: IslandState.dnd
                onClicked: IslandState.dnd = !IslandState.dnd
            }
            RoundButton {
                icon: "󰐥"
                label: "Power"
                onClicked: {
                    center.win.expanded = false
                    Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/power-menu"])
                }
            }
        }
    }
}
