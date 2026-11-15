pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

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

    Behavior on base { ColorAnimation { duration: 600 } }
    Behavior on surface { ColorAnimation { duration: 600 } }
    Behavior on surfaceHigh { ColorAnimation { duration: 600 } }
    Behavior on text { ColorAnimation { duration: 600 } }
    Behavior on subtext { ColorAnimation { duration: 600 } }
    Behavior on accent { ColorAnimation { duration: 600 } }
    Behavior on accent2 { ColorAnimation { duration: 600 } }

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/serpantinum/qs_colors.json"
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
