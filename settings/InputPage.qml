import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../services"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    readonly property var touchpads: HyprConf.touchpads
    property var layouts: []
    property var layoutCodes: []
    property var layoutNames: []

    onVisibleChanged: if (visible) query.running = true
    Component.onCompleted: if (visible) query.running = true

    function nameOf(code) {
        const i = layoutCodes.indexOf(code)
        return (i >= 0 && layoutNames[i]) || String(code || "").toUpperCase()
    }

    function set(key, val) {
        Config.opt[key] = val
        HyprConf.save()
    }

    function setTermKeys(on) {
        Config.opt.termCopyPaste = on
        Quickshell.execDetached(["sh", "-c", 'd="$HOME/.config/kitty"; mkdir -p "$d"; if [ "$1" = 1 ]; then printf "map ctrl+c copy_or_interrupt\\nmap ctrl+v paste_from_clipboard\\n" > "$d/canvas-keys.conf"; else : > "$d/canvas-keys.conf"; fi; grep -qx "include canvas-keys.conf" "$d/kitty.conf" 2>/dev/null || echo "include canvas-keys.conf" >> "$d/kitty.conf"; pkill -USR1 -x kitty; true', "sh", on ? "1" : "0"])
    }

    function setLayouts(list) {
        layouts = list
        set("kbLayouts", list.join(","))
    }

    Process {
        id: query
        command: ["sh", "-c", "hyprctl devices -j; echo '|||'; sed -n '/^! layout/,/^!/p' /usr/share/X11/xkb/rules/base.lst 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("|||")
                try {
                    const d = JSON.parse(parts[0])
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
    ChoiceRow {
        title: Lang.t.kbLayouts
        sub: Lang.t.kbLayoutsSub
        searchable: true
        options: page.layoutNames.map((n, i) => n + " (" + page.layoutCodes[i] + ")")
        values: page.layoutCodes
        value: ""
        placeholder: Lang.t.kbAdd
        onPicked: v => {
            if (page.layouts.indexOf(v) === -1 && page.layouts.length < 4) page.setLayouts(page.layouts.concat([v]))
        }
    }
    Flow {
        width: parent.width
        spacing: 6
        topPadding: 8
        bottomPadding: 8
        Repeater {
            model: page.layouts
            Rectangle {
                required property string modelData
                required property int index
                width: chip.implicitWidth + (page.layouts.length > 1 ? 46 : 28)
                height: 34
                radius: 17
                color: index === 0 ? Theme.alpha(Theme.accent, 0.25) : Theme.surfaceHigh
                Txt {
                    id: chip
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.nameOf(modelData)
                    weight: Font.Medium
                    size: 13
                }
                Icon {
                    visible: page.layouts.length > 1
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰅖"
                    size: 14
                    color: Theme.subtext
                    onClicked: page.setLayouts(page.layouts.filter((x, i) => i !== index))
                }
            }
        }
    }
    SettingRow {
        title: Lang.t.termCopyPaste
        sub: Lang.t.termCopyPasteSub
        height: 76
        Toggle { checked: Config.opt.termCopyPaste; onToggled: v => page.setTermKeys(v) }
    }
}
