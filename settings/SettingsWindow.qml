import QtQuick
import Quickshell
import "../core"
import "../ui"

LazyLoader {
    active: IslandState.settingsOpen

    FloatingWindow {
        id: win
        title: "Canvas Einstellungen"
        implicitWidth: 820
        implicitHeight: 580
        color: Theme.base
        onVisibleChanged: if (!visible) IslandState.settingsOpen = false

        property int page: 0
        property var pages: [
            { icon: "󰏘", name: "Aussehen" },
            { icon: "󱂬", name: "Island" },
            { icon: "󰕮", name: "Control-Center" },
            { icon: "󰒓", name: "Canvas-Teile" },
            { icon: "󰋼", name: "Über" }
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
                        Txt { text: "Einstellungen"; size: 12; color: Theme.subtext }
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
                        title: "Glas-Look"
                        sub: "Island, Control-Center und Launcher werden durchsichtig mit Blur."
                        Toggle { checked: Config.opt.glass; onToggled: v => Config.opt.glass = v }
                    }
                    SettingRow {
                        title: "Glas-Deckkraft"
                        sub: "Wie stark der Hintergrund durchscheint."
                        opacity: Config.opt.glass ? 1 : 0.4
                        Slider {
                            width: 200
                            value: (Config.opt.glassOpacity - 0.15) / 0.8
                            onMoved: v => Config.opt.glassOpacity = Math.round((0.15 + v * 0.8) * 100) / 100
                        }
                    }
                    SettingRow {
                        title: "Animationen"
                        sub: "Geschwindigkeit aller Canvas-Animationen."
                        Segmented {
                            options: ["Normal", "Schnell", "Aus"]
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
                        title: "Datum beim Drüberfahren"
                        sub: "Die kleine Island zeigt zusätzlich das Datum."
                        Toggle { checked: Config.opt.hoverDate; onToggled: v => Config.opt.hoverDate = v }
                    }
                    SettingRow {
                        title: "Musik nach Pause"
                        sub: "Wie lange die Musik-Ansicht nach einer Pause sichtbar bleibt."
                        Segmented {
                            options: ["Aus", "8 s", "30 s"]
                            values: [0, 8, 30]
                            value: Config.opt.musicLinger
                            onPicked: v => Config.opt.musicLinger = v
                        }
                    }
                    SettingRow {
                        title: "Benachrichtigungen"
                        sub: "Wie lange eine Benachrichtigung in der Island bleibt."
                        Segmented {
                            options: ["3 s", "5 s", "8 s"]
                            values: [3, 5, 8]
                            value: Config.opt.notifDuration
                            onPicked: v => Config.opt.notifDuration = v
                        }
                    }
                    SettingRow {
                        title: "Nicht stören"
                        sub: "Benachrichtigungen landen nur im Verlauf."
                        Toggle { checked: Config.opt.dnd; onToggled: v => Config.opt.dnd = v }
                    }
                }

                Column {
                    width: parent.width
                    visible: win.page === 2
                    SettingRow {
                        title: "Musik-Visualizer"
                        sub: "Balken neben dem Song in der Island und im Control-Center."
                        Toggle { checked: Config.opt.visualizer; onToggled: v => Config.opt.visualizer = v }
                    }
                    SettingRow {
                        title: "System-Ringe"
                        sub: "CPU, RAM und Temperatur im Control-Center."
                        Toggle { checked: Config.opt.systemRings; onToggled: v => Config.opt.systemRings = v }
                    }
                }

                Column {
                    width: parent.width
                    visible: win.page === 3
                    Txt {
                        width: parent.width
                        text: "Diese Teile übernehmen Aufgaben von Serpantinum. Erst einschalten, wenn Serpantinum aus ist – sonst kommen sich beide in die Quere."
                        size: 13
                        color: Theme.subtext
                        wrapMode: Text.WordWrap
                        bottomPadding: 8
                    }
                    SettingRow {
                        title: "Wallpaper"
                        sub: "Live-Wallpaper vom aktuellen Theme, pausiert wenn Fenster offen sind."
                        Toggle { checked: Config.opt.wallpaper; onToggled: v => Config.opt.wallpaper = v }
                    }
                    SettingRow {
                        title: "Benachrichtigungen empfangen"
                        sub: "Canvas wird zum Benachrichtigungs-Dienst."
                        Toggle { checked: Config.opt.notifications; onToggled: v => Config.opt.notifications = v }
                    }
                    SettingRow {
                        title: "Eigene Farben"
                        sub: "Canvas berechnet die Theme-Farben selbst (matugen) statt sie von Serpantinum zu übernehmen."
                        Toggle { checked: Config.opt.ownColors; onToggled: v => Config.opt.ownColors = v }
                    }
                    SettingRow {
                        title: "Lockscreen"
                        sub: "Super + L sperrt mit dem Canvas-Lockscreen. Aus = nur Vorschau."
                        Toggle { checked: Config.opt.lockscreen; onToggled: v => Config.opt.lockscreen = v }
                    }
                    SettingRow {
                        title: "Lockscreen-Vorschau"
                        sub: "Zeigt den Lockscreen, ohne wirklich zu sperren. Esc schließt."
                        Rectangle {
                            width: 110
                            height: 34
                            radius: 17
                            color: previewArea.containsMouse ? Theme.accent : Theme.surfaceHigh
                            Txt {
                                anchors.centerIn: parent
                                text: "Anzeigen"
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
                    Txt { text: "Canvas – die Oberfläche von CanOS"; size: 16; weight: Font.DemiBold }
                    Txt { text: "Gebaut mit Quickshell. Einstellungen liegen in ~/.config/canvas/settings.json."; size: 13; color: Theme.subtext }
                    Txt { text: "Shortcuts: Super + Alt + D Launcher · Super + T Themes"; size: 13; color: Theme.subtext }
                }
            }
        }
    }
}
