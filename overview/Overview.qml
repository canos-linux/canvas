import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import "../core"
import "../services"
import "../ui"

PanelWindow {
    id: ov
    property bool focusedScreen: Hypr.focusedMonitor === "" || screen.name === Hypr.focusedMonitor
    property bool shown: IslandState.overview && focusedScreen
    property var clients: []
    property var mon: ({ x: 0, y: 0, width: screen.width, height: screen.height, scale: 1, active: 1 })
    property var spaces: []
    readonly property real cardW: Math.min(420, (width - 120 - 24 * (Math.min(spaces.length, 4) - 1)) / Math.max(1, Math.min(spaces.length, 4)))
    readonly property real ratio: mon.width / Math.max(1, mon.height)
    readonly property real cardH: cardW / ratio
    readonly property real k: cardW / Math.max(1, mon.width)
    property int sel: 0

    visible: shown || fade.opacity > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "canvas-overview"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onShownChanged: {
        if (shown) {
            query.running = true
            Sounds.play("open")
        }
    }

    function close() {
        IslandState.overview = false
    }

    function preview(addr) {
        const list = Hyprland.toplevels.values
        const a = addr.replace(/^0x/, "")
        for (let i = 0; i < list.length; i++)
            if (String(list[i].address).replace(/^0x/, "") === a) return list[i].wayland
        return null
    }

    function focusWindow(addr) {
        Hyprland.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })')
        close()
    }

    function focusSpace(id) {
        Hypr.focus(id)
        close()
    }

    function moveWindow(addr, ws) {
        Hyprland.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })')
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + ws + " })")
        refresh.restart()
    }

    Timer {
        id: refresh
        interval: 250
        onTriggered: query.running = true
    }

    Process {
        id: query
        command: ["sh", "-c", "hyprctl -j monitors; echo '|||'; hyprctl -j clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const p = text.split("|||")
                    const m = JSON.parse(p[0]).find(x => x.name === ov.screen.name)
                    if (m) ov.mon = { x: m.x, y: m.y, width: m.width / m.scale, height: m.height / m.scale, active: m.activeWorkspace.id }
                    const all = JSON.parse(p[1]).filter(c => c.workspace.id > 0 && c.monitor === (m ? m.id : c.monitor) && c.mapped !== false)
                    ov.clients = all
                    const ids = all.map(c => c.workspace.id)
                    ids.push(ov.mon.active)
                    const uniq = ids.filter((v, i) => ids.indexOf(v) === i).sort((a, b) => a - b)
                    uniq.push((uniq.length ? uniq[uniq.length - 1] : 0) + 1)
                    ov.spaces = uniq
                    ov.sel = Math.max(0, uniq.indexOf(ov.mon.active))
                } catch (e) {}
            }
        }
    }

    Rectangle {
        id: fade
        anchors.fill: parent
        color: Theme.alpha(Theme.base, 0.72)
        opacity: ov.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(220) } }

        MouseArea {
            anchors.fill: parent
            onClicked: ov.close()
        }

        Item {
            anchors.fill: parent
            focus: ov.shown
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) ov.close()
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) ov.sel = (ov.sel + 1) % ov.spaces.length
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) ov.sel = (ov.sel - 1 + ov.spaces.length) % ov.spaces.length
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) ov.focusSpace(ov.spaces[ov.sel])
                else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) ov.focusSpace(event.key - Qt.Key_0)
                else return
                event.accepted = true
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: grid.top
            anchors.bottomMargin: 26
            text: Lang.t.overview
            size: 22
            weight: Font.Bold
        }

        Flow {
            id: grid
            anchors.centerIn: parent
            width: Math.min(ov.spaces.length, 4) * (ov.cardW + 24) - 24
            spacing: 24
            scale: ov.shown ? 1 : 0.92
            Behavior on scale { NumberAnimation { duration: Theme.dur(320); easing.type: Easing.OutBack } }

            Repeater {
                model: ov.spaces
                Item {
                    id: card
                    required property int modelData
                    required property int index
                    readonly property bool current: modelData === ov.mon.active
                    width: ov.cardW
                    height: ov.cardH + 30

                    Rectangle {
                        id: frame
                        width: ov.cardW
                        height: ov.cardH
                        radius: 16
                        clip: true
                        color: drop.containsDrag ? Theme.alpha(Theme.accent, 0.25) : Theme.surface
                        border.width: ov.sel === card.index || card.current ? 2 : 1
                        border.color: ov.sel === card.index ? Theme.accent : Theme.alpha(Theme.accent, card.current ? 0.6 : 0.2)

                        Image {
                            anchors.fill: parent
                            visible: Config.wallpaperOn && CurrentTheme.dir !== ""
                            source: visible ? "file://" + CurrentTheme.dir + "/lock.png" : ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 480
                            asynchronous: true
                            opacity: 0.55
                        }

                        Icon {
                            anchors.centerIn: parent
                            visible: !ov.clients.some(c => c.workspace.id === card.modelData)
                            text: "󰐕"
                            size: 30
                            color: Theme.subtext
                            hoverable: false
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: ov.sel = card.index
                            onClicked: ov.focusSpace(card.modelData)
                        }

                        DropArea {
                            id: drop
                            anchors.fill: parent
                            keys: ["canvas-window"]
                            onDropped: drag => ov.moveWindow(drag.source.addr, card.modelData)
                        }

                        Repeater {
                            model: ov.clients.filter(c => c.workspace.id === card.modelData)
                            Item {
                                id: winItem
                                required property var modelData
                                readonly property string addr: modelData.address
                                readonly property real homeX: (modelData.at[0] - ov.mon.x) * ov.k
                                readonly property real homeY: (modelData.at[1] - ov.mon.y) * ov.k
                                x: homeX
                                y: homeY
                                width: Math.max(24, modelData.size[0] * ov.k)
                                height: Math.max(18, modelData.size[1] * ov.k)
                                z: dragArea.drag.active ? 10 : 1
                                Drag.active: dragArea.drag.active
                                Drag.keys: ["canvas-window"]
                                Drag.source: winItem
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: Theme.surfaceHigh
                                    border.width: 1
                                    border.color: dragArea.containsMouse ? Theme.accent : Theme.alpha(Theme.text, 0.12)

                                    ScreencopyView {
                                        id: shot
                                        anchors.fill: parent
                                        captureSource: ov.shown ? ov.preview(winItem.addr) : null
                                        live: ov.shown
                                        paintCursor: false
                                    }

                                    IconImage {
                                        anchors.centerIn: parent
                                        visible: !shot.hasContent
                                        implicitSize: Math.min(36, parent.height * 0.6)
                                        source: Quickshell.iconPath(DesktopEntries.heuristicLookup(winItem.modelData.class)?.icon ?? winItem.modelData.class, "application-x-executable")
                                    }
                                }

                                MouseArea {
                                    id: dragArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    drag.target: winItem
                                    onEntered: ov.sel = card.index
                                    onReleased: {
                                        const moved = Math.abs(winItem.x - winItem.homeX) + Math.abs(winItem.y - winItem.homeY) > 12
                                        if (moved) winItem.Drag.drop()
                                        winItem.x = Qt.binding(() => winItem.homeX)
                                        winItem.y = Qt.binding(() => winItem.homeY)
                                        if (!moved) ov.focusWindow(winItem.addr)
                                    }
                                }
                            }
                        }
                    }

                    Txt {
                        anchors.horizontalCenter: frame.horizontalCenter
                        anchors.top: frame.bottom
                        anchors.topMargin: 8
                        text: card.modelData
                        size: 13
                        weight: card.current ? Font.Bold : Font.Normal
                        color: card.current ? Theme.accent : Theme.subtext
                    }
                }
            }
        }
    }
}
