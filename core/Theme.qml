pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../services"

Singleton {
    id: root
    property color base: "#0f0d12"
    property color surface: "#201f24"
    property color surfaceHigh: "#2b292e"
    property color text: "#e6e1e7"
    property color subtext: "#cac4d1"
    property color accent: "#cdbdff"
    property color accent2: "#a897e0"
    property string font: "Google Sans Flex"
    property string iconFont: "Iosevka Nerd Font Propo"

    property real speed: Config.opt.animations === "off" ? 0 : Config.opt.animations === "fast" ? 0.6 : 1
    property color panel: Config.opt.glass ? alpha(base, Config.opt.glassOpacity) : base
    property color card: Config.opt.glass ? alpha(surface, 0.55) : surface

    Behavior on base { ColorAnimation { duration: 600 } }
    Behavior on surface { ColorAnimation { duration: 600 } }
    Behavior on surfaceHigh { ColorAnimation { duration: 600 } }
    Behavior on text { ColorAnimation { duration: 600 } }
    Behavior on subtext { ColorAnimation { duration: 600 } }
    Behavior on accent { ColorAnimation { duration: 600 } }
    Behavior on accent2 { ColorAnimation { duration: 600 } }

    // own color for the current theme (Settings › Themes), empty = from the picture
    readonly property string accentOverride: {
        try { return JSON.parse(Config.opt.themeAccents)[CurrentTheme.name] || "" } catch (e) { return "" }
    }
    onAccentOverrideChanged: if (Config.ownColorsOn && CurrentTheme.dir !== "") matugen.running = true

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function dur(ms) {
        return Math.round(ms * speed)
    }

    function applyColors(c) {
        base = c.base
        surface = c.surface
        surfaceHigh = c.surfaceHigh
        text = c.text
        subtext = c.subtext
        accent = c.accent
        accent2 = c.accent2
    }

    Process {
        id: matugen
        command: ["sh", "-c", "d=\"$1\"; if [ -n \"$2\" ]; then matugen color hex \"$2\" -m dark -t scheme-tonal-spot --json hex --dry-run 2>/dev/null; exit; fi; if [ -f \"$d/matugen.png\" ]; then i=\"$d/matugen.png\"; t=scheme-fidelity; else i=\"$d/lock.png\"; t=scheme-tonal-spot; fi; matugen image \"$i\" -m dark -t $t --json hex --dry-run --prefer saturation 2>/dev/null", "sh", CurrentTheme.dir, root.accentOverride]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text).colors
                    const g = k => c[k].dark.color
                    root.applyColors({
                        base: g("surface_container_lowest"),
                        surface: g("surface_container"),
                        surfaceHigh: g("surface_container_high"),
                        text: g("on_surface"),
                        subtext: g("on_surface_variant"),
                        accent: g("primary"),
                        accent2: g("secondary")
                    })
                } catch (e) {}
            }
        }
    }

    Connections {
        target: CurrentTheme
        function onDirChanged() {
            if (Config.ownColorsOn && CurrentTheme.dir !== "") matugen.running = true
        }
    }

    Connections {
        target: Config
        function onOwnColorsOnChanged() {
            if (Config.ownColorsOn && CurrentTheme.dir !== "") matugen.running = true
        }
    }

    FileView {
        path: Config.ownColorsOn ? "" : Quickshell.env("HOME") + "/.local/state/serpantinum/qs_colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text())
                root.base = c.base
                root.surface = c.surface0
                root.surfaceHigh = c.surface1
                root.text = c.text
                root.subtext = c.subtext0
                root.accent = c.blue
                root.accent2 = c.sapphire
            } catch (e) {}
        }
    }
}
