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

    Binding {
        target: IslandState
        property: "centerHeight"
        value: col.implicitHeight + 44
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
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
                    text: clock.date.toLocaleString(Lang.locale, Lang.t.dateLong)
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
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰒓"
                    size: 20
                    color: Theme.accent
                    rotation: gearHover.hovered ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: Theme.dur(400); easing.type: Easing.OutBack } }
                    HoverHandler { id: gearHover }
                    onClicked: {
                        center.win.setExpanded(false)
                        IslandState.settingsOpen = true
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 10
            Tile {
                width: (parent.width - 20) / 3
                icon: Net.icon
                title: Lang.t.wifi
                sub: Net.label
                active: Net.connected
                onClicked: Net.openSettings()
            }
            Tile {
                width: (parent.width - 20) / 3
                icon: Bt.icon
                title: "Bluetooth"
                sub: !Bt.powered ? Lang.t.off : Bt.device !== "" ? Bt.device : Lang.t.on
                active: Bt.powered
                onClicked: Bt.toggle()
            }
            Tile {
                width: (parent.width - 20) / 3
                icon: "󰌌"
                title: Lang.t.keyboard
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

        Rectangle {
            visible: Media.player !== null
            width: parent.width
            height: 70
            radius: 22
            color: Theme.card

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
                    visible: Config.opt.visualizer
                    anchors.verticalCenter: parent.verticalCenter
                    maxHeight: 24
                }
                Icon { anchors.verticalCenter: parent.verticalCenter; text: "󰒮"; onClicked: Media.previous() }
                Icon { anchors.verticalCenter: parent.verticalCenter; text: Media.playing ? "󰏤" : "󰐊"; size: 24; color: Theme.accent; onClicked: Media.toggle() }
                Icon { anchors.verticalCenter: parent.verticalCenter; text: "󰒭"; onClicked: Media.next() }
            }
        }

        Column {
            visible: Notifs.history.length > 0
            width: parent.width
            spacing: 8

            Item {
                width: parent.width
                height: 20
                Txt {
                    text: Lang.t.notifications
                    size: 13
                    weight: Font.DemiBold
                    color: Theme.subtext
                }
                Txt {
                    id: clearText
                    anchors.right: parent.right
                    text: Lang.t.clearAll
                    size: 12
                    color: clearArea.containsMouse ? Theme.accent : Theme.subtext
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Notifs.clear()
                    }
                }
            }

            Repeater {
                model: Notifs.history.slice(0, 3)
                Rectangle {
                    width: parent.width
                    height: 54
                    radius: 16
                    color: Theme.card

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰂚"
                            size: 18
                            color: Theme.accent
                            hoverable: false
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Txt {
                                width: 380
                                text: modelData.title
                                size: 13
                                weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Txt {
                                width: 380
                                text: modelData.app + " · " + modelData.time + (modelData.body ? "  —  " + modelData.body : "")
                                size: 11
                                color: Theme.subtext
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: Config.opt.systemRings ? 74 : 30

            Row {
                visible: Config.opt.systemRings
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
            spacing: (parent.width - (Edition.priv ? 5 : 4) * 64) / (Edition.priv ? 4 : 3)

            RoundButton {
                icon: "󰹑"
                label: "Screenshot"
                onClicked: {
                    center.win.setExpanded(false)
                    if (!Edition.priv) { IslandState.startShot(); return }
                    Quickshell.execDetached(["sh", "-c", "sleep 0.6; mkdir -p ~/Pictures/Screenshots; f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png; grim \"$f\" && wl-copy < \"$f\" && notify-send 'Screenshot' 'Gespeichert und kopiert'"])
                }
            }
            RoundButton {
                icon: "󰏘"
                label: "Themes"
                onClicked: IslandState.overlay = "themes"
            }
            RoundButton {
                icon: "󰊴"
                label: "Gacha"
                visible: Edition.priv
                onClicked: {
                    center.win.setExpanded(false)
                    Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme-gacha"])
                }
            }
            RoundButton {
                icon: Config.opt.dnd ? "󰂛" : "󰂚"
                label: Lang.t.quiet
                active: Config.opt.dnd
                onClicked: Config.opt.dnd = !Config.opt.dnd
            }
            RoundButton {
                icon: "󰐥"
                label: "Power"
                onClicked: {
                    if (!Edition.priv) { IslandState.overlay = "power"; return }
                    center.win.setExpanded(false)
                    Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/power-menu"])
                }
            }
        }
    }
}
