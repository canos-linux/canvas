import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"

// Super+V: clipboard history with image previews and pins, Super+. : emoji
FocusScope {
    id: cv
    property bool active: false
    property string tab: "clip"
    property var clips: []          // { id, line, text, image }
    property var pins: []           // texts
    property var emojis: []
    property var recent: []
    property int sel: 0
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/canvas"
    readonly property string q: input.text.trim().toLowerCase()
    readonly property var shownClips: {
        const p = pins.filter(t => q === "" || t.toLowerCase().indexOf(q) !== -1).map(t => ({ id: "", line: "", text: t, image: "", pinned: true }))
        const c = clips.filter(c => pins.indexOf(c.text) === -1 && (q === "" || c.text.toLowerCase().indexOf(q) !== -1))
        return p.concat(c).slice(0, 40)
    }
    readonly property var shownEmojis: q === "" ? recent.map(e => [e, ""]).concat(emojis.filter(e => recent.indexOf(e[0]) === -1)) : emojis.filter(e => e[1].indexOf(q) !== -1)

    onActiveChanged: {
        if (active) {
            tab = IslandState.clipTab
            input.text = ""
            sel = 0
            loader.running = true
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: input.forceActiveFocus()
    }

    FileView {
        path: cv.stateDir + "/emoji.json"
        onLoaded: { try { cv.recent = JSON.parse(text()) } catch (e) {} }
    }
    FileView {
        path: cv.stateDir + "/clip-pins.json"
        onLoaded: { try { cv.pins = JSON.parse(text()) } catch (e) {} }
    }
    FileView {
        path: Quickshell.shellDir + "/core/emoji.json"
        onLoaded: { try { cv.emojis = JSON.parse(text()) } catch (e) {} }
    }

    function store(file, data) {
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", file, JSON.stringify(data)])
    }

    function togglePin(text) {
        pins = pins.indexOf(text) === -1 ? [text].concat(pins).slice(0, 20) : pins.filter(t => t !== text)
        store(stateDir + "/clip-pins.json", pins)
    }

    function copyClip(c) {
        if (c.line !== "") Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", c.line])
        else Quickshell.execDetached(["wl-copy", "--", c.text])
        Sounds.play("click")
        IslandState.overlay = ""
    }

    function copyEmoji(e) {
        Quickshell.execDetached(["wl-copy", "--", e])
        recent = [e].concat(recent.filter(x => x !== e)).slice(0, 20)
        store(stateDir + "/emoji.json", recent)
        Sounds.play("click")
        IslandState.overlay = ""
    }

    // cliphist list; images are decoded once into /tmp for the preview
    Process {
        id: loader
        command: ["sh", "-c", "d=/tmp/canvas-clip; mkdir -p $d; cliphist list 2>/dev/null | head -60 | while IFS= read -r l; do id=$(printf '%s' \"$l\" | cut -f1); case \"$l\" in *'[[ binary data'*) [ -f $d/$id.img ] || printf '%s' \"$l\" | cliphist decode > $d/$id.img 2>/dev/null; echo \"I|$id|$d/$id.img|$l\";; *) echo \"T|$id||$l\";; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                cv.clips = text.split("\n").filter(l => l !== "").map(l => {
                    const f = l.split("|")
                    const line = f.slice(3).join("|")
                    return { id: f[1], line: line, text: f[0] === "I" ? "" : line.replace(/^[0-9]+\t/, ""), image: f[0] === "I" ? f[2] : "" }
                })
            }
        }
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 62
        Icon {
            id: hIcon
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: cv.tab === "clip" ? "󰅌" : "󰞅"
            size: 22
            color: Theme.accent
            hoverable: false
        }
        TextInput {
            id: input
            anchors.left: hIcon.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 17
            clip: true
            onTextChanged: cv.sel = 0
            Keys.onPressed: event => {
                const n = cv.tab === "clip" ? cv.shownClips.length : cv.shownEmojis.length
                const step = cv.tab === "clip" ? 1 : 10
                if (event.key === Qt.Key_Escape) IslandState.overlay = ""
                else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) { cv.tab = cv.tab === "clip" ? "emoji" : "clip"; cv.sel = 0 }
                else if (event.key === Qt.Key_Down) cv.sel = Math.min(n - 1, cv.sel + step)
                else if (event.key === Qt.Key_Up) cv.sel = Math.max(0, cv.sel - step)
                else if (event.key === Qt.Key_Right && cv.tab === "emoji") cv.sel = Math.min(n - 1, cv.sel + 1)
                else if (event.key === Qt.Key_Left && cv.tab === "emoji") cv.sel = Math.max(0, cv.sel - 1)
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (cv.tab === "clip" && cv.shownClips[cv.sel]) cv.copyClip(cv.shownClips[cv.sel])
                    else if (cv.tab === "emoji" && cv.shownEmojis[cv.sel]) cv.copyEmoji(cv.shownEmojis[cv.sel][0])
                }
                else return
                event.accepted = true
            }
            Txt {
                visible: input.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: cv.tab === "clip" ? Lang.t.clipSearch : Lang.t.emojiSearch
                size: 15
                color: Theme.subtext
                opacity: 0.7
            }
        }
    }

    ListView {
        id: clipList
        visible: cv.tab === "clip"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: tabs.top
        anchors.margins: 8
        anchors.topMargin: 0
        clip: true
        model: cv.shownClips
        currentIndex: cv.sel
        highlightMoveDuration: Theme.dur(150)
        highlight: Rectangle { radius: 16; color: Theme.alpha(Theme.accent, 0.18); border.width: 1; border.color: Theme.alpha(Theme.accent, 0.4) }
        delegate: Item {
            required property var modelData
            required property int index
            width: clipList.width
            height: modelData.image !== "" ? 92 : 50
            Icon {
                id: pinIcon
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                visible: modelData.image === ""
                text: modelData.pinned ? "󰐃" : "󰤱"
                size: 17
                color: modelData.pinned ? Theme.accent : Theme.subtext
                z: 2
                onClicked: cv.togglePin(modelData.text)
            }
            ClippingRectangle {
                visible: modelData.image !== ""
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 130
                height: 76
                radius: 10
                color: Theme.surfaceHigh
                Image {
                    anchors.fill: parent
                    source: modelData.image !== "" ? "file://" + modelData.image : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 260
                    asynchronous: true
                    cache: false
                }
            }
            Txt {
                visible: modelData.image === ""
                x: 18
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 70
                text: modelData.text.replace(/\s+/g, " ")
                elide: Text.ElideRight
            }
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 44
                hoverEnabled: true
                onEntered: cv.sel = index
                onClicked: cv.copyClip(modelData)
            }
        }
        Txt {
            anchors.centerIn: parent
            visible: cv.shownClips.length === 0
            text: Lang.t.clipEmpty
            color: Theme.subtext
        }
    }

    GridView {
        id: emojiGrid
        visible: cv.tab === "emoji"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: tabs.top
        anchors.margins: 12
        anchors.topMargin: 0
        clip: true
        cellWidth: width / 10
        cellHeight: 52
        model: cv.shownEmojis
        currentIndex: cv.sel
        highlightMoveDuration: Theme.dur(120)
        highlight: Rectangle { radius: 14; color: Theme.alpha(Theme.accent, 0.25) }
        delegate: Item {
            required property var modelData
            required property int index
            width: emojiGrid.cellWidth
            height: emojiGrid.cellHeight
            Text {
                anchors.centerIn: parent
                text: modelData[0]
                font.family: "Noto Color Emoji"
                font.pixelSize: 28
                scale: emHov.hovered ? 1.25 : 1
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }
            HoverHandler { id: emHov; onHoveredChanged: if (hovered) cv.sel = index }
            TapHandler { onTapped: cv.copyEmoji(modelData[0]) }
        }
    }

    Row {
        id: tabs
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        height: 40
        spacing: 6
        Repeater {
            model: [{ key: "clip", name: Lang.t.tabClipboard, icon: "󰅌" }, { key: "emoji", name: "Emoji", icon: "󰞅" }]
            Rectangle {
                width: (tabs.width - 6) / 2
                height: 40
                radius: 20
                color: cv.tab === modelData.key ? Theme.alpha(Theme.accent, 0.85) : tHov.hovered ? Theme.surfaceHigh : "transparent"
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Icon { anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; size: 16; hoverable: false; color: cv.tab === modelData.key ? Theme.base : Theme.text }
                    Txt { anchors.verticalCenter: parent.verticalCenter; text: modelData.name; weight: Font.DemiBold; color: cv.tab === modelData.key ? Theme.base : Theme.text }
                }
                HoverHandler { id: tHov }
                TapHandler {
                    onTapped: {
                        Sounds.play("click")
                        cv.tab = modelData.key
                        cv.sel = 0
                        input.forceActiveFocus()
                    }
                }
            }
        }
    }
}
