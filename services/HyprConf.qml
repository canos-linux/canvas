pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

Singleton {
    id: root
    property var touchpads: []
    property bool ready: false
    readonly property string hypr: Quickshell.env("HOME") + "/.config/hypr"

    function lua() {
        const o = Config.opt
        const de = o.language === "de"
        let l = "-- Written by Canvas Settings\n"
        l += 'hl.env("LANG", "' + (de ? "de_AT.UTF-8" : "en_US.UTF-8") + '")\n'
        l += 'hl.window_rule({ name = "canos-no-auto-maximize", match = { class = ".*" }, suppress_event = "maximize" })\n'
        l += 'hl.env("LANGUAGE", "' + (de ? "de_AT:de" : "en_US:en") + '")\n'
        l += "hl.config({ input = { sensitivity = " + o.mouseSpeed.toFixed(2)
        if (o.kbLayouts !== "") l += ', kb_layout = "' + o.kbLayouts + '", kb_variant = ""'
        l += ", touchpad = { tap_to_click = " + o.tapToClick + ", natural_scroll = " + o.naturalScroll + ", disable_while_typing = " + o.typingBlock + " } } })\n"
        // no Hyprland wallpaper/logo when Canvas is not running (e.g. during shutdown): theme color instead
        l += 'hl.config({ misc = { disable_hyprland_logo = true, disable_splash_rendering = true, force_default_wallpaper = 0, background_color = "rgb(' + String(Theme.base).replace("#", "").slice(-6) + ')" } })\n'
        for (const t of touchpads) l += 'hl.device({ name = "' + t + '", sensitivity = ' + o.touchpadSpeed.toFixed(2) + " })\n"
        return l
    }

    function save() {
        if (ready) saveTimer.restart()
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: {
            const code = root.lua()
            const de = Config.opt.language === "de"
            apply.command = ["sh", "-c", 'mkdir -p "$1/config"; printf "%s" "$2" | cmp -s "$1/config/canvas.lua" - && exit 0; printf "%s" "$2" > "$1/config/canvas.lua"; grep -q "config/canvas" "$1/hyprland.lua" || printf "\\npcall(require, \\"config/canvas\\")\\n" >> "$1/hyprland.lua"; hyprctl eval "$2" >/dev/null; env LANG="$3" LANGUAGE="$4" dbus-update-activation-environment --systemd LANG LANGUAGE 2>/dev/null; true', "sh", root.hypr, code, de ? "de_AT.UTF-8" : "en_US.UTF-8", de ? "de_AT:de" : "en_US:en"]
            apply.running = true
        }
    }

    Process {
        id: apply
    }

    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.touchpads = JSON.parse(text).mice.filter(m => /touchpad|trackpad/i.test(m.name)).map(m => m.name)
                } catch (e) {}
                root.ready = true
                root.save()
            }
        }
    }

    Connections {
        target: Config.opt
        function onLanguageChanged() { root.save() }
    }

    Connections {
        target: Theme
        function onBaseChanged() { root.save() }
    }
}
