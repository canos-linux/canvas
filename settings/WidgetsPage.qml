import QtQuick
import "../core"
import "../services"
import "../ui"

Column {
    width: parent ? parent.width : 400

    SettingRow {
        title: Lang.t.widgetsOn
        sub: Lang.t.widgetsOnSub
        Toggle { checked: Config.opt.widgets; onToggled: v => Config.opt.widgets = v }
    }

    Column {
        width: parent.width
        opacity: Config.opt.widgets ? 1 : 0.4
        enabled: Config.opt.widgets

        SettingRow {
            title: Lang.t.widgetsMove
            sub: Lang.t.widgetsMoveSub
            PillButton {
                text: Lang.t.widgetsReset
                onClicked: {
                    let all = {}
                    try { all = JSON.parse(Config.opt.widgetPos) } catch (e) {}
                    delete all[CurrentTheme.name]
                    Config.opt.widgetPos = JSON.stringify(all)
                }
            }
        }
        SettingRow {
            title: Lang.t.widgetSide
            Segmented {
                options: [Lang.t.sideLeft, Lang.t.sideRight]
                values: ["left", "right"]
                value: Config.opt.widgetSide
                onPicked: v => {
                    // new side = widgets line up in the column again (moved ones of this theme too)
                    let all = {}
                    try { all = JSON.parse(Config.opt.widgetPos) } catch (e) {}
                    delete all[CurrentTheme.name]
                    delete all["*"]
                    Config.opt.widgetPos = JSON.stringify(all)
                    Config.opt.widgetSide = v
                }
            }
        }
        SettingRow {
            title: Lang.t.wClock
            Toggle { checked: Config.opt.wClock; onToggled: v => Config.opt.wClock = v }
        }
        SettingRow {
            title: Lang.t.wWeather
            sub: Lang.t.wWeatherSub
            Toggle { checked: Config.opt.wWeather; onToggled: v => Config.opt.wWeather = v }
        }
        SettingRow {
            title: Lang.t.weatherCity
            sub: Lang.t.weatherCitySub
            opacity: Config.opt.wWeather ? 1 : 0.4
            Field {
                width: 200
                text: Config.opt.weatherCity
                placeholder: Lang.t.weatherAuto
                onAccepted: Config.opt.weatherCity = text.trim()
            }
        }
        SettingRow {
            title: Lang.t.wSystem
            sub: Lang.t.wSystemSub
            Toggle { checked: Config.opt.wSystem; onToggled: v => Config.opt.wSystem = v }
        }
        SettingRow {
            title: Lang.t.wCalendar
            Toggle { checked: Config.opt.wCalendar; onToggled: v => Config.opt.wCalendar = v }
        }
        SettingRow {
            title: Lang.t.wMusic
            sub: Lang.t.wMusicSub
            Toggle { checked: Config.opt.wMusic; onToggled: v => Config.opt.wMusic = v }
        }
        Column {
            width: parent.width
            opacity: Config.opt.wMusic ? 1 : 0.4
            enabled: Config.opt.wMusic
            SettingRow {
                title: Lang.t.musicStyle
                Segmented {
                    options: [Lang.t.styleVinyl, Lang.t.styleCover]
                    values: ["vinyl", "cover"]
                    value: Config.opt.musicStyle
                    onPicked: v => Config.opt.musicStyle = v
                }
            }
            SettingRow {
                title: Lang.t.wVisualizer
                Toggle { checked: Config.opt.wVisualizer; onToggled: v => Config.opt.wVisualizer = v }
            }
            SettingRow {
                title: Lang.t.wLyrics
                sub: Lang.t.wLyricsSub
                Toggle { checked: Config.opt.wLyrics; onToggled: v => Config.opt.wLyrics = v }
            }
        }
    }
}
