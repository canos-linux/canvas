import QtQuick
import Quickshell
import "../core"
import "../ui"

LazyLoader {
    active: IslandState.settingsOpen

    FloatingWindow {
        id: win
        title: Lang.t.settingsTitle
        implicitWidth: 820
        implicitHeight: 580
        color: Theme.base
        onVisibleChanged: if (!visible) IslandState.settingsOpen = false

        property int page: 0
        property var pages: [
            { icon: "󰏘", name: Lang.t.pageLook },
            { icon: "󱂬", name: Lang.t.pageIsland },
            { icon: "󰕮", name: Lang.t.pageCenter },
            { icon: "󰒓", name: Lang.t.pageParts },
            { icon: "󰋼", name: Lang.t.pageAbout }
        ]

        Rectangle {
            id: sidebar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 230
            color: Theme.surface

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 6

                Row {
                    spacing: 10
                    bottomPadding: 18
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: Theme.accent
                        Txt {
                            anchors.centerIn: parent
                            text: "C"
                            size: 18
                            weight: Font.Bold
                            color: Theme.base
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Txt { text: "Canvas"; size: 17; weight: Font.Bold }
                        Txt { text: Lang.t.settings; size: 12; color: Theme.subtext }
                    }
                }

                Repeater {
                    model: win.pages
                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 14
                        color: win.page === index ? Theme.alpha(Theme.accent, 0.2) : navArea.containsMouse ? Theme.surfaceHigh : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.dur(150) } }
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                size: 18
                                hoverable: false
                                color: win.page === index ? Theme.accent : Theme.text
                            }
                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                weight: win.page === index ? Font.DemiBold : Font.Normal
                            }
                        }
                        MouseArea {
                            id: navArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: win.page = index
                        }
                    }
                }
            }
        }

        Flickable {
            id: content
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 30
            contentHeight: pageCol.implicitHeight
            clip: true

            Column {
                id: pageCol
                width: content.width
                spacing: 0

                Txt {
                    text: win.pages[win.page].name
                    size: 26
                    weight: Font.Bold
                    bottomPadding: 14
                }

                Column {
                    width: parent.width
                    visible: win.page === 0
                    SettingRow {
                        title: Lang.t.language
                        sub: Lang.t.languageSub
                        Segmented {
                            options: ["English", "Deutsch"]
                            values: ["en", "de"]
                            value: Lang.code
                            onPicked: v => Config.opt.language = v
                        }
                    }
                    SettingRow {
                        title: Lang.t.glass
                        sub: Lang.t.glassSub
                        Toggle { checked: Config.opt.glass; onToggled: v => Config.opt.glass = v }
                    }
                    SettingRow {
                        title: Lang.t.glassOpacity
                        sub: Lang.t.glassOpacitySub
                        opacity: Config.opt.glass ? 1 : 0.4
                        Slider {
                            width: 200
                            value: (Config.opt.glassOpacity - 0.15) / 0.8
                            onMoved: v => Config.opt.glassOpacity = Math.round((0.15 + v * 0.8) * 100) / 100
                        }
                    }
                    SettingRow {
                        title: Lang.t.animations
                        sub: Lang.t.animationsSub
                        Segmented {
                            options: Lang.t.animOptions
                            values: ["normal", "fast", "off"]
                            value: Config.opt.animations
                            onPicked: v => Config.opt.animations = v
                        }
                    }
                }

                Column {
                    width: parent.width
                    visible: win.page === 1
                    SettingRow {
                        title: Lang.t.hoverDate
                        sub: Lang.t.hoverDateSub
                        Toggle { checked: Config.opt.hoverDate; onToggled: v => Config.opt.hoverDate = v }
                    }
                    SettingRow {
                        title: Lang.t.musicLinger
                        sub: Lang.t.musicLingerSub
                        Segmented {
                            options: [Lang.t.off, "8 s", "30 s"]
                            values: [0, 8, 30]
                            value: Config.opt.musicLinger
                            onPicked: v => Config.opt.musicLinger = v
                        }
                    }
                    SettingRow {
                        title: Lang.t.notifications
                        sub: Lang.t.notifDurationSub
                        Segmented {
                            options: ["3 s", "5 s", "8 s"]
                            values: [3, 5, 8]
                            value: Config.opt.notifDuration
                            onPicked: v => Config.opt.notifDuration = v
                        }
                    }
                    SettingRow {
                        title: Lang.t.dnd
                        sub: Lang.t.dndSub
                        Toggle { checked: Config.opt.dnd; onToggled: v => Config.opt.dnd = v }
                    }
                }

                Column {
                    width: parent.width
                    visible: win.page === 2
                    SettingRow {
                        title: Lang.t.visualizer
                        sub: Lang.t.visualizerSub
                        Toggle { checked: Config.opt.visualizer; onToggled: v => Config.opt.visualizer = v }
                    }
                    SettingRow {
                        title: Lang.t.rings
                        sub: Lang.t.ringsSub
                        Toggle { checked: Config.opt.systemRings; onToggled: v => Config.opt.systemRings = v }
                    }
                }

                Column {
                    width: parent.width
                    visible: win.page === 3
                    Txt {
                        width: parent.width
                        text: Lang.t.partsInfo
                        size: 13
                        color: Theme.subtext
                        wrapMode: Text.WordWrap
                        bottomPadding: 8
                    }
                    SettingRow {
                        title: Lang.t.wallpaper
                        sub: Lang.t.wallpaperSub
                        Toggle { checked: Config.opt.wallpaper; onToggled: v => Config.opt.wallpaper = v }
                    }
                    SettingRow {
                        title: Lang.t.notifReceive
                        sub: Lang.t.notifReceiveSub
                        Toggle { checked: Config.opt.notifications; onToggled: v => Config.opt.notifications = v }
                    }
                    SettingRow {
                        title: Lang.t.ownColors
                        sub: Lang.t.ownColorsSub
                        Toggle { checked: Config.opt.ownColors; onToggled: v => Config.opt.ownColors = v }
                    }
                    SettingRow {
                        title: Lang.t.lockscreen
                        sub: Lang.t.lockscreenSub
                        Toggle { checked: Config.opt.lockscreen; onToggled: v => Config.opt.lockscreen = v }
                    }
                    SettingRow {
                        title: Lang.t.lockPreview
                        sub: Lang.t.lockPreviewSub
                        Rectangle {
                            width: 110
                            height: 34
                            radius: 17
                            color: previewArea.containsMouse ? Theme.accent : Theme.surfaceHigh
                            Txt {
                                anchors.centerIn: parent
                                text: Lang.t.show
                                weight: Font.Medium
                                color: previewArea.containsMouse ? Theme.base : Theme.text
                            }
                            MouseArea {
                                id: previewArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: IslandState.lockPreview = true
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    visible: win.page === 4
                    spacing: 8
                    Txt { text: Lang.t.aboutTitle; size: 16; weight: Font.DemiBold }
                    Txt { text: Lang.t.aboutBuilt; size: 13; color: Theme.subtext }
                    Txt { text: Lang.t.aboutShortcuts; size: 13; color: Theme.subtext }
                }
            }
        }
    }
}
