import QtQuick
import Quickshell
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"

FocusScope {
    id: av
    property var win
    property bool active: false

    Binding {
        target: IslandState
        property: "panelHeight"
        value: Math.min(600, body.implicitHeight + 40)
        when: av.active
    }

    onActiveChanged: if (active) focusTimer.restart()
    Timer { id: focusTimer; interval: 60; onTriggered: keys.forceActiveFocus() }

    function back() {
        IslandState.overlay = ""
        if (win) win.setExpanded(true)
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key !== Qt.Key_Escape) return
            IslandState.overlay = ""
            event.accepted = true
        }
    }

    component Head: Txt {
        size: 13
        weight: Font.DemiBold
        color: Theme.subtext
    }

    component DeviceRow: Rectangle {
        id: dr
        required property var modelData
        property bool current: false
        property string glyph: "󰓃"
        signal picked()
        width: parent ? parent.width : 0
        height: 48
        radius: 18
        color: current ? Theme.alpha(Theme.accent, hov.hovered ? 0.26 : 0.18) : hov.hovered ? Theme.surfaceHigh : Theme.card
        scale: tap.pressed ? 0.97 : 1
        Behavior on color { ColorAnimation { duration: Theme.dur(200) } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(160); easing.type: Easing.OutBack } }
        HoverHandler { id: hov }
        TapHandler { id: tap; gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: dr.picked() }
        Icon {
            id: g
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: dr.glyph
            size: 18
            hoverable: false
            color: dr.current ? Theme.accent : Theme.text
        }
        Txt {
            anchors.left: g.right
            anchors.leftMargin: 12
            anchors.right: check.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.label(dr.modelData)
            weight: dr.current ? Font.Bold : Font.Medium
            elide: Text.ElideRight
        }
        Icon {
            id: check
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            visible: dr.current
            text: "󰄬"
            size: 17
            hoverable: false
            color: Theme.accent
        }
    }

    component VolRow: Row {
        id: vr
        property string glyph: ""
        property bool muted: false
        property real value: 0
        signal moved(real v)
        signal toggled()
        width: parent ? parent.width : 0
        spacing: 12
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: vr.glyph
            size: 20
            color: vr.muted ? Theme.subtext : Theme.text
            onClicked: vr.toggled()
        }
        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 90
            value: vr.muted ? 0 : vr.value
            onMoved: v => vr.moved(v)
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignRight
            text: Math.round(vr.value * 100) + "%"
            weight: Font.Medium
        }
    }

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 14

        Item {
            width: parent.width
            height: 34
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Icon { anchors.verticalCenter: parent.verticalCenter; text: "󰁍"; size: 20; onClicked: av.back() }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: "Audio"; size: 17; weight: Font.Bold }
            }
        }

        Flickable {
            width: parent.width
            height: Math.min(lists.implicitHeight, 470)
            contentHeight: lists.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: lists
                width: parent.width
                spacing: 8

                Head { text: Lang.t.audioOutput }
                VolRow {
                    glyph: Audio.icon
                    muted: Audio.muted
                    value: Audio.volume
                    onMoved: v => Audio.setVolume(v)
                    onToggled: Audio.toggleMute()
                }
                Repeater {
                    model: Audio.outputs.length > 1 ? Audio.outputs : []
                    DeviceRow {
                        current: modelData === Audio.sink
                        glyph: Audio.outGlyph(modelData)
                        onPicked: Audio.setOutput(modelData)
                    }
                }

                Item { width: 1; height: 6 }
                Head { text: Lang.t.audioInput }
                VolRow {
                    visible: Audio.source !== null
                    glyph: Audio.micIcon
                    muted: Audio.micMuted
                    value: Audio.micVolume
                    onMoved: v => Audio.setMic(v)
                    onToggled: Audio.toggleMic()
                }
                Txt {
                    visible: Audio.source === null
                    text: Lang.t.audioNoMic
                    size: 13
                    color: Theme.subtext
                }
                Repeater {
                    model: Audio.inputs.length > 1 ? Audio.inputs : []
                    DeviceRow {
                        current: modelData === Audio.source
                        glyph: "󰍬"
                        onPicked: Audio.setInput(modelData)
                    }
                }

                Item { width: 1; height: 6 }
                Head { text: Lang.t.audioApps }
                Txt {
                    visible: Audio.apps.length === 0
                    text: Lang.t.audioNoApps
                    size: 13
                    color: Theme.subtext
                }
                Repeater {
                    model: Audio.apps
                    Column {
                        required property var modelData
                        width: lists.width
                        spacing: 4
                        Row {
                            spacing: 8
                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 18
                                source: Quickshell.iconPath(Audio.appIcon(modelData), "audio-x-generic")
                            }
                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Audio.appName(modelData)
                                size: 13
                                weight: Font.Medium
                            }
                        }
                        VolRow {
                            glyph: modelData.audio && modelData.audio.muted ? "󰝟" : "󰕾"
                            muted: modelData.audio ? modelData.audio.muted : false
                            value: modelData.audio ? modelData.audio.volume : 0
                            onMoved: v => Audio.setNode(modelData, v)
                            onToggled: Audio.toggleNode(modelData)
                        }
                    }
                }
            }
        }
    }
}
