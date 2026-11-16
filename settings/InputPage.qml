import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    property var touchpads: []
    property var layouts: []
    property var layoutCodes: []
    property var layoutNames: []
    readonly property string hypr: Quickshell.env("HOME") + "/.config/hypr"

    onVisibleChanged: if (visible) query.running = true
    Component.onCompleted: if (visible) query.running = true

    function nameOf(code) {
        const i = layoutCodes.indexOf(code)
        return i >= 0 ? layoutNames[i] : code.toUpperCase()
    }

    function lua() {
        const o = Config.opt
        let l = "-- Written by Canvas Settings\nhl.config({ input = { sensitivity = " + o.mouseSpeed.toFixed(2)
        if (o.kbLayouts !== "") l += ', kb_layout = "' + o.kbLayouts + '", kb_variant = ""'
        l += ", touchpad = { tap_to_click = " + o.tapToClick + ", natural_scroll = " + o.naturalScroll + ", disable_while_typing = " + o.typingBlock + " } } })\n"
        for (const t of touchpads) l += 'hl.device({ name = "' + t + '", sensitivity = ' + o.touchpadSpeed.toFixed(2) + " })\n"
        return l
    }

    function save() {
        const code = lua()
        apply.command = ["sh", "-c", 'mkdir -p "$1/config" && printf "%s" "$2" > "$1/config/canvas.lua" && { grep -q "config/canvas" "$1/hyprland.lua" || printf "\\npcall(require, \\"config/canvas\\")\\n" >> "$1/hyprland.lua"; } && hyprctl eval "$2"', "sh", hypr, code]
        apply.running = true
    }

    function set(key, val) {
        Config.opt[key] = val
        saveTimer.restart()
    }

    function setLayouts(list) {
        layouts = list
        set("kbLayouts", list.join(","))
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: page.save()
    }

    Process {
        id: apply
    }

    Process {
        id: query
        command: ["sh", "-c", "hyprctl devices -j; echo '|||'; sed -n '/^! layout/,/^!/p' /usr/share/X11/xkb/rules/base.lst 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("|||")
                try {
                    const d = JSON.parse(parts[0])
                    page.touchpads = d.mice.filter(m => /touchpad|trackpad/i.test(m.name)).map(m => m.name)
                    if (Config.opt.kbLayouts !== "") page.layouts = Config.opt.kbLayouts.split(",")
                    else {
                        const kb = d.keyboards.find(k => k.main) || d.keyboards[0]
                        page.layouts = kb && kb.layout ? kb.layout.split(",") : ["us"]
                    }
                } catch (e) {}
                const codes = [], names = []
                for (const line of (parts[1] || "").split("\n")) {
                    const m = line.match(/^\s+(\S+)\s+(.+)$/)
                    if (m) { codes.push(m[1]); names.push(m[2].trim()) }
                }
                page.layoutCodes = codes
                page.layoutNames = names
            }
        }
    }

    Txt {
        text: Lang.t.touchpad
        size: 13
        weight: Font.DemiBold
        color: Theme.accent
        topPadding: 4
        visible: page.touchpads.length > 0
    }
    SettingRow {
        visible: page.touchpads.length > 0
        title: Lang.t.tapToClick
        sub: Lang.t.tapToClickSub
        Toggle { checked: Config.opt.tapToClick; onToggled: v => page.set("tapToClick", v) }
    }
    SettingRow {
        visible: page.touchpads.length > 0
        title: Lang.t.naturalScroll
        sub: Lang.t.naturalScrollSub
        Toggle { checked: Config.opt.naturalScroll; onToggled: v => page.set("naturalScroll", v) }
    }
    SettingRow {
        visible: page.touchpads.length > 0
        title: Lang.t.typingBlock
        sub: Lang.t.typingBlockSub
        Toggle { checked: Config.opt.typingBlock; onToggled: v => page.set("typingBlock", v) }
    }
    SettingRow {
        visible: page.touchpads.length > 0
        title: Lang.t.touchpadSpeed
        Slider {
            width: 200
            value: (Config.opt.touchpadSpeed + 1) / 2
            onMoved: v => page.set("touchpadSpeed", Math.round((v * 2 - 1) * 20) / 20)
        }
    }

    Txt {
        text: Lang.t.mouse
        size: 13
        weight: Font.DemiBold
        color: Theme.accent
        topPadding: 14
    }
    SettingRow {
        title: Lang.t.mouseSpeed
        sub: Lang.t.mouseSpeedSub
        Slider {
            width: 200
            value: (Config.opt.mouseSpeed + 1) / 2
            onMoved: v => page.set("mouseSpeed", Math.round((v * 2 - 1) * 20) / 20)
        }
    }

    Txt {
        text: Lang.t.kbSection
        size: 13
        weight: Font.DemiBold
        color: Theme.accent
        topPadding: 14
    }
    SettingRow {
        title: Lang.t.kbLayouts
        sub: Lang.t.kbLayoutsSub
        Row {
            spacing: 6
            Repeater {
                model: page.layouts
                Rectangle {
                    required property string modelData
                    required property int index
                    width: chip.implicitWidth + (page.layouts.length > 1 ? 44 : 28)
                    height: 32
                    radius: 16
                    color: index === 0 ? Theme.alpha(Theme.accent, 0.25) : Theme.surfaceHigh
                    Txt {
                        id: chip
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.toUpperCase()
                        weight: Font.DemiBold
                        size: 13
                    }
                    Icon {
                        visible: page.layouts.length > 1
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅖"
                        size: 14
                        color: Theme.subtext
                        onClicked: page.setLayouts(page.layouts.filter((x, i) => i !== index))
                    }
                }
            }
        }
    }
    ChoiceRow {
        title: Lang.t.kbAdd
        searchable: true
        options: page.layoutNames.map((n, i) => n + " (" + page.layoutCodes[i] + ")")
        values: page.layoutCodes
        value: ""
        placeholder: Lang.t.kbAddHint
        onPicked: v => {
            if (page.layouts.indexOf(v) === -1 && page.layouts.length < 4) page.setLayouts(page.layouts.concat([v]))
        }
    }
}
