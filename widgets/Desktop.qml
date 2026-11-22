import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../core"
import "../services"
import "../ui"

PanelWindow {
    id: desk
    readonly property bool onLeft: Config.opt.widgetSide === "left"

    visible: Config.opt.widgets && !Gaming.active
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "canvas-widgets"
    mask: Region {
        Region { item: clockW }
        Region { item: weatherW }
        Region { item: systemW }
        Region { item: cal }
        Region { item: music }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // saved positions per theme, as fractions of the screen: { theme: { key: [fx, fy] } }
    readonly property var saved: {
        try { return (JSON.parse(Config.opt.widgetPos)[CurrentTheme.name]) || {} } catch (e) { return {} }
    }
    readonly property real colX: onLeft ? 24 : width - 356

    function save(key, x, y) {
        let all = {}
        try { all = JSON.parse(Config.opt.widgetPos) } catch (e) {}
        const t = Object.assign({}, all[CurrentTheme.name] || {})
        t[key] = [Math.round(x / width * 1000) / 1000, Math.round(y / height * 1000) / 1000]
        all[CurrentTheme.name] = t
        Config.opt.widgetPos = JSON.stringify(all)
    }

    Binding {
        target: Sys
        property: "widget"
        value: desk.visible && Config.opt.wSystem
    }

    // a widget you can drag anywhere; without a saved position it sits in the column on the side
    component Movable: Item {
        id: mv
        required property string key
        property Item prev: null
        readonly property real defY: prev ? prev.defY + (prev.visible ? prev.height + 16 : 0) : 80
        readonly property var pos: desk.saved[key] || null
        width: 332
        x: pos ? Math.min(desk.width - width, pos[0] * desk.width) : desk.colX
        y: pos ? Math.min(desk.height - height, pos[1] * desk.height) : defY
        Behavior on x { enabled: !drag.active; NumberAnimation { duration: Theme.dur(300); easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !drag.active; NumberAnimation { duration: Theme.dur(300); easing.type: Easing.OutCubic } }
        scale: drag.active ? 1.03 : 1
        Behavior on scale { NumberAnimation { duration: 150 } }
        z: drag.active ? 5 : 1
        DragHandler {
            id: drag
            target: mv
            xAxis.minimum: 0
            xAxis.maximum: desk.width - mv.width
            yAxis.minimum: 0
            yAxis.maximum: desk.height - mv.height
            onActiveChanged: {
                if (!active) {
                    desk.save(mv.key, mv.x, mv.y)
                    mv.x = Qt.binding(() => mv.pos ? Math.min(desk.width - mv.width, mv.pos[0] * desk.width) : desk.colX)
                    mv.y = Qt.binding(() => mv.pos ? Math.min(desk.height - mv.height, mv.pos[1] * desk.height) : mv.defY)
                }
            }
        }
    }

    component Card: Rectangle {
        width: 332
        radius: 28
        color: Theme.alpha(Theme.base, 0.62)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.18)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Item {
        id: col
        anchors.fill: parent

        // clock
        Movable {
            id: clockW
            key: "clock"
            visible: Config.opt.wClock
            height: 130
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(clock.date, Config.opt.clock24 ? "HH:mm" : "h:mm")
                    size: 82
                    weight: Font.Bold
                    color: Theme.text
                    style: Text.Raised
                    styleColor: Theme.alpha(Theme.base, 0.5)
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.date.toLocaleString(Lang.locale, Lang.t.dateLong)
                    size: 17
                    weight: Font.DemiBold
                    color: Theme.accent
                    style: Text.Raised
                    styleColor: Theme.alpha(Theme.base, 0.5)
                }
            }
        }

        // weather
        Movable {
            id: weatherW
            key: "weather"
            prev: clockW
            visible: Config.opt.wWeather && Weather.ok
            height: 96
        Card {
            anchors.fill: parent
            Icon {
                id: wIcon
                anchors.left: parent.left
                anchors.leftMargin: 22
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.icon
                size: 44
                color: Theme.accent
                hoverable: false
            }
            Column {
                anchors.left: wIcon.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                Txt { text: Math.round(Weather.temp) + "°"; size: 30; weight: Font.Bold }
                Txt { text: Weather.label; size: 13; color: Theme.subtext }
            }
            Column {
                anchors.right: parent.right
                anchors.rightMargin: 22
                anchors.verticalCenter: parent.verticalCenter
                Txt { anchors.right: parent.right; text: Weather.place; size: 13; weight: Font.DemiBold }
                Txt { anchors.right: parent.right; text: "↑ " + Math.round(Weather.high) + "°   ↓ " + Math.round(Weather.low) + "°"; size: 12; color: Theme.subtext }
            }
        }

        }

        // system
        Movable {
            id: systemW
            key: "system"
            prev: weatherW
            visible: Config.opt.wSystem
            height: 112
        Card {
            anchors.fill: parent
            Row {
                anchors.centerIn: parent
                spacing: 26
                Repeater {
                    model: [
                        { label: "CPU", v: Sys.cpu, t: Math.round(Sys.cpu * 100) + "%" },
                        { label: "RAM", v: Sys.ram, t: Math.round(Sys.ram * 100) + "%" },
                        { label: Lang.t.temp, v: Math.min(1, Sys.temp / 100), t: Sys.temp > 0 ? Math.round(Sys.temp) + "°" : "–" }
                    ]
                    Ring {
                        value: modelData.v
                        label: modelData.label
                        text: modelData.t
                    }
                }
            }
        }

        }

        // calendar
        Movable {
            id: cal
            key: "calendar"
            prev: systemW
            visible: Config.opt.wCalendar
            height: calCol.implicitHeight + 32
            readonly property date first: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
            readonly property int offset: (first.getDay() + 6) % 7
            readonly property int days: new Date(clock.date.getFullYear(), clock.date.getMonth() + 1, 0).getDate()
            Card { anchors.fill: parent }
            Column {
                id: calCol
                anchors.centerIn: parent
                spacing: 8
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.date.toLocaleString(Lang.locale, "MMMM yyyy")
                    size: 15
                    weight: Font.Bold
                }
                Grid {
                    columns: 7
                    spacing: 4
                    Repeater {
                        model: 7
                        Txt {
                            width: 40
                            horizontalAlignment: Text.AlignHCenter
                            text: Lang.locale.dayName((index + 1) % 7, Locale.NarrowFormat)
                            size: 11
                            color: Theme.subtext
                        }
                    }
                    Repeater {
                        model: cal.offset + cal.days
                        Rectangle {
                            readonly property int day: index - cal.offset + 1
                            readonly property bool today: day === clock.date.getDate()
                            width: 40
                            height: 30
                            radius: 15
                            color: today ? Theme.accent : "transparent"
                            Txt {
                                anchors.centerIn: parent
                                visible: parent.day > 0
                                text: parent.day
                                size: 13
                                weight: parent.today ? Font.Bold : Font.Normal
                                color: parent.today ? Theme.base : Theme.text
                            }
                        }
                    }
                }
            }
        }

        // music
        Movable {
            id: music
            key: "music"
            prev: cal
            visible: Config.opt.wMusic && Media.player !== null
            height: musicCol.implicitHeight + 36
            readonly property bool vinyl: Config.opt.musicStyle === "vinyl"
            Card { anchors.fill: parent }

            Column {
                id: musicCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 14

                Row {
                    spacing: 16
                    Item {
                        width: 112
                        height: 112
                        // vinyl record: grooves + cover as label
                        Rectangle {
                            id: disc
                            visible: music.vinyl
                            anchors.fill: parent
                            radius: width / 2
                            color: "#0d0d0f"
                            border.width: 1
                            border.color: Theme.alpha(Theme.text, 0.15)
                            Repeater {
                                model: 5
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: disc.width - 14 - index * 12
                                    height: width
                                    radius: width / 2
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.05 + (index % 2) * 0.03)
                                }
                            }
                            ClippingRectangle {
                                anchors.centerIn: parent
                                width: 46
                                height: 46
                                radius: 23
                                color: Theme.accent
                                Image {
                                    anchors.fill: parent
                                    source: Media.art
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 6
                                height: 6
                                radius: 3
                                color: "#0d0d0f"
                            }
                            Rectangle {
                                x: parent.width * 0.62
                                y: parent.height * 0.14
                                width: 18
                                height: 4
                                radius: 2
                                rotation: 40
                                color: Qt.rgba(1, 1, 1, 0.12)
                            }
                            RotationAnimation on rotation {
                                running: Media.playing && music.vinyl && music.visible
                                loops: Animation.Infinite
                                from: disc.rotation
                                to: disc.rotation + 360
                                duration: 4000
                            }
                        }
                        ClippingRectangle {
                            visible: !music.vinyl
                            anchors.fill: parent
                            radius: 20
                            color: Theme.surfaceHigh
                            Image {
                                anchors.fill: parent
                                source: Media.art
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }
                    }

                    Column {
                        width: musicCol.width - 128
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Txt { width: parent.width; text: Media.title; size: 16; weight: Font.Bold; elide: Text.ElideRight }
                        Txt { width: parent.width; text: Media.artist; size: 13; color: Theme.subtext; elide: Text.ElideRight }
                        Row {
                            topPadding: 10
                            spacing: 20
                            Icon { text: "󰒮"; size: 22; onClicked: Media.previous() }
                            Icon { text: Media.playing ? "󰏤" : "󰐊"; size: 26; color: Theme.accent; onClicked: Media.toggle() }
                            Icon { text: "󰒭"; size: 22; onClicked: Media.next() }
                        }
                    }
                }

                // visualizer: 8 cava levels mirrored to 16 bars
                Row {
                    visible: Config.opt.wVisualizer
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 40
                    spacing: 5
                    Repeater {
                        model: 16
                        Rectangle {
                            readonly property real lv: Media.levels[index < 8 ? 7 - index : index - 8] || 0
                            anchors.bottom: parent.bottom
                            width: 13
                            height: 4 + lv / 100 * 36
                            radius: 4
                            color: Theme.alpha(Theme.accent, 0.5 + lv / 200)
                            Behavior on height { NumberAnimation { duration: 90 } }
                        }
                    }
                }

                Column {
                    visible: Config.opt.wLyrics && Lyrics.lines.length > 0
                    width: parent.width
                    spacing: 4
                    Txt {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Lyrics.current || "♪"
                        size: 16
                        weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }
                    Txt {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Lyrics.next
                        size: 13
                        color: Theme.subtext
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
