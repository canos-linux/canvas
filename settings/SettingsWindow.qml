import QtQuick
import Quickshell
import "../core"
import "../services"
import "../ui"

LazyLoader {
    active: IslandState.settingsOpen

    FloatingWindow {
        id: win
        title: Lang.t.settingsTitle
        implicitWidth: 820
        implicitHeight: 640
        color: Theme.base
        onVisibleChanged: if (!visible) IslandState.settingsOpen = false

        property string page: IslandState.settingsPage || "look"
        property var pages: [
            { key: "look", icon: "󰏘", name: Lang.t.pageLook },
            { key: "themes", icon: "󰸉", name: Lang.t.pageThemes, community: true },
            { key: "island", icon: "󱂬", name: Lang.t.pageIsland },
            { key: "center", icon: "󰕮", name: Lang.t.pageCenter },
            { key: "widgets", icon: "󰖲", name: Lang.t.pageWidgets },
            { key: "gaming", icon: "󰊴", name: Lang.t.pageGaming },
            { key: "phone", icon: "󰄜", name: Lang.t.pagePhone },
            { key: "recovery", icon: "󰁯", name: Lang.t.pageRecovery, community: true },
            { key: "parts", icon: "󰒓", name: Lang.t.pageParts, priv: true },
            { key: "display", icon: "󰍹", name: Lang.t.pageDisplay },
            { key: "input", icon: "󰌌", name: Lang.t.pageInput },
            { key: "system", icon: "󰒔", name: Lang.t.pageSystem },
            { key: "apps", icon: "󰀻", name: Lang.t.pageApps },
            { key: "account", icon: "󰀄", name: Lang.t.pageAccount },
            { key: "time", icon: "󰥔", name: Lang.t.pageTime },
            { key: "about", icon: "󰋼", name: Lang.t.pageAbout }
        ]
        readonly property var current: pages.find(p => p.key === page) || pages[0]

        Connections {
            target: IslandState
            function onSettingsPageChanged() {
                if (IslandState.settingsPage) win.page = IslandState.settingsPage
            }
        }

        Rectangle {
            id: sidebar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 230
            color: Theme.surface

            Flickable {
                id: sideFlick
                anchors.fill: parent
                anchors.margins: 18
                contentHeight: sideCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

            Column {
                id: sideCol
                width: sideFlick.width
                spacing: 2

                Row {
                    spacing: 10
                    bottomPadding: 14
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
                        height: visible ? 40 : 0
                        visible: (!modelData.priv || Edition.priv) && (!modelData.community || !Edition.priv)
                        radius: 14
                        color: win.page === modelData.key ? Theme.alpha(Theme.accent, 0.2) : navArea.containsMouse ? Theme.surfaceHigh : "transparent"
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
                                color: win.page === modelData.key ? Theme.accent : Theme.text
                            }
                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                weight: win.page === modelData.key ? Font.DemiBold : Font.Normal
                            }
                        }
                        MouseArea {
                            id: navArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: win.page = modelData.key
                        }
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
                    text: win.current.name
                    size: 26
                    weight: Font.Bold
                    bottomPadding: 14
                }

                Column {
                    width: parent.width
                    visible: win.page === "look"
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
                    SettingRow {
                        title: Lang.t.themeCursor
                        sub: Lang.t.themeCursorSub
                        Toggle { checked: Config.opt.themeCursor; onToggled: v => Config.opt.themeCursor = v }
                    }
                    SettingRow {
                        title: Lang.t.sounds
                        sub: Lang.t.soundsSub
                        Toggle { checked: Config.opt.sounds; onToggled: v => { Config.opt.sounds = v; Sounds.play("click") } }
                    }
                    SettingRow {
                        title: Lang.t.soundVolume
                        opacity: Config.opt.sounds ? 1 : 0.4
                        Slider {
                            width: 200
                            value: Config.opt.soundVolume
                            onMoved: v => {
                                Config.opt.soundVolume = Math.round(v * 100) / 100
                                Sounds.play("click")
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    visible: win.page === "island"
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
                    SettingRow {
                        title: Lang.t.dndSchedule
                        sub: Lang.t.dndScheduleSub
                        Segmented {
                            options: [Lang.t.off, Lang.t.dndNight, Lang.t.dndSchool, Lang.t.dndBoth]
                            values: ["off", "night", "school", "both"]
                            value: Config.opt.dndSchedule
                            onPicked: v => Config.opt.dndSchedule = v
                        }
                    }
                    SettingRow {
                        title: Lang.t.lockMusic
                        Toggle { checked: Config.opt.lockMusic; onToggled: v => Config.opt.lockMusic = v }
                    }
                    SettingRow {
                        title: Lang.t.lockNotifs
                        sub: Lang.t.lockNotifsSub
                        Toggle { checked: Config.opt.lockNotifs; onToggled: v => Config.opt.lockNotifs = v }
                    }
                    SettingRow {
                        title: Lang.t.lockWeather
                        Toggle { checked: Config.opt.lockWeather; onToggled: v => Config.opt.lockWeather = v }
                    }
                    SettingRow {
                        title: Lang.t.recordAudio
                        sub: Lang.t.recordAudioSub
                        Toggle { checked: Config.opt.recordAudio; onToggled: v => Config.opt.recordAudio = v }
                    }
                }

                Column {
                    width: parent.width
                    visible: win.page === "center"
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
                    visible: win.page === "parts"
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
                    visible: win.page === "system"
                    SettingRow {
                        title: Lang.t.idleLock
                        sub: Lang.t.idleLockSub
                        opacity: Config.lockOn ? 1 : 0.4
                        Segmented {
                            options: [Lang.t.off, "5 min", "10 min"]
                            values: [0, 5, 10]
                            value: Config.opt.idleLock
                            onPicked: v => Config.opt.idleLock = v
                        }
                    }
                    SettingRow {
                        title: Lang.t.nightLight
                        sub: Lang.t.nightLightSub
                        Segmented {
                            options: [Lang.t.off, Lang.t.on, Lang.t.nightAuto]
                            values: ["off", "on", "auto"]
                            value: Config.opt.nightMode
                            onPicked: v => Config.opt.nightMode = v
                        }
                    }
                    SettingRow {
                        title: Lang.t.nightStrength
                        opacity: Config.opt.nightMode === "off" ? 0.4 : 1
                        Segmented {
                            options: [Lang.t.nightStrong, Lang.t.nightMedium, Lang.t.nightSoft]
                            values: [3500, 4500, 5500]
                            value: Config.opt.nightTemp
                            onPicked: v => Config.opt.nightTemp = v
                        }
                    }
                    SettingRow {
                        title: Lang.t.nightFrom
                        opacity: Config.opt.nightMode === "auto" ? 1 : 0.4
                        Segmented {
                            options: ["19:00", "20:00", "21:00", "22:00"]
                            values: ["19:00", "20:00", "21:00", "22:00"]
                            value: Config.opt.nightFrom
                            onPicked: v => Config.opt.nightFrom = v
                        }
                    }
                    SettingRow {
                        title: Lang.t.nightTo
                        opacity: Config.opt.nightMode === "auto" ? 1 : 0.4
                        Segmented {
                            options: ["06:00", "07:00", "08:00"]
                            values: ["06:00", "07:00", "08:00"]
                            value: Config.opt.nightTo
                            onPicked: v => Config.opt.nightTo = v
                        }
                    }
                    SettingRow {
                        visible: Power.present
                        title: Lang.t.batteryWarn
                        sub: Lang.t.batteryWarnSub
                        Toggle { checked: Config.opt.batteryWarn; onToggled: v => Config.opt.batteryWarn = v }
                    }
                    SettingRow {
                        title: Lang.t.lockOnSleep
                        sub: Lang.t.lockOnSleepSub
                        opacity: Config.lockOn ? 1 : 0.4
                        Toggle { checked: Config.opt.lockOnSleep; onToggled: v => Config.opt.lockOnSleep = v }
                    }
                    SettingRow {
                        visible: !Edition.priv
                        title: Lang.t.clipboard
                        sub: Lang.t.clipboardSub
                        Toggle { checked: Config.opt.clipboard; onToggled: v => Config.opt.clipboard = v }
                    }
                    SettingRow {
                        visible: !Edition.priv
                        title: Lang.t.welcomeAgain
                        sub: Lang.t.welcomeAgainSub
                        Rectangle {
                            width: 110
                            height: 34
                            radius: 17
                            color: tourArea.containsMouse ? Theme.accent : Theme.surfaceHigh
                            Txt {
                                anchors.centerIn: parent
                                text: Lang.t.show
                                weight: Font.Medium
                                color: tourArea.containsMouse ? Theme.base : Theme.text
                            }
                            MouseArea {
                                id: tourArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: IslandState.welcomeOpen = true
                            }
                        }
                    }
                }

                DisplayPage { visible: win.page === "display" }
                WidgetsPage { visible: win.page === "widgets" }
                ThemesPage { visible: win.page === "themes" }
                RecoveryPage { visible: win.page === "recovery" }
                GamingPage { visible: win.page === "gaming" }
                PhonePage { visible: win.page === "phone" }
                InputPage { visible: win.page === "input" }
                AppsPage { visible: win.page === "apps" }
                AccountPage { visible: win.page === "account" }
                TimePage { visible: win.page === "time" }
                AboutPage { visible: win.page === "about" }
            }
        }
    }
}
