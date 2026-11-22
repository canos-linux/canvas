import QtQuick
import "../core"
import "../services"
import "../ui"

Item {
    id: quick
    property var win

    component Btn: Rectangle {
        id: b
        property string icon: ""
        property string tip: ""
        property bool on: false
        signal hit()
        width: 46
        height: 46
        radius: 23
        color: on ? Theme.accent : hov.hovered ? Theme.surfaceHigh : Theme.card
        scale: tap.pressed ? 0.88 : hov.hovered ? 1.08 : 1
        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        Icon {
            anchors.centerIn: parent
            text: b.icon
            size: 20
            hoverable: false
            color: b.on ? Theme.base : Theme.text
        }
        HoverHandler { id: hov }
        TapHandler {
            id: tap
            onTapped: {
                Sounds.play("click")
                b.hit()
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 12
        Btn { icon: Net.icon; on: Net.connected; onHit: IslandState.overlay = "wifi" }
        Btn { icon: Bt.icon; on: Bt.powered; onHit: IslandState.overlay = "bt" }
        Btn { icon: Config.opt.dnd ? "󰂛" : "󰂚"; on: Config.opt.dnd; onHit: Config.opt.dnd = !Config.opt.dnd }
        Btn { icon: Night.active ? "󰖔" : "󰖙"; on: Night.mode !== "off"; onHit: Night.cycle() }
        Btn { icon: "󰹑"; onHit: IslandState.startShot() }
        Btn {
            icon: Recorder.active ? "󰓛" : "󰻃"
            on: Recorder.active
            onHit: {
                IslandState.overlay = ""
                Recorder.toggle(false)
            }
        }
        Btn { icon: "󰊴"; on: Gaming.active; onHit: Gaming.toggle() }
        Btn {
            icon: "󰕰"
            onHit: {
                IslandState.overlay = ""
                IslandState.overview = true
            }
        }
    }
}
