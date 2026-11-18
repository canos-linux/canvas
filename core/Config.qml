pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../services"

Singleton {
    id: root
    readonly property string path: Quickshell.env("HOME") + "/.config/canvas/settings.json"
    property alias opt: adapter
    readonly property bool wallpaperOn: !Edition.priv || adapter.wallpaper
    readonly property bool notificationsOn: !Edition.priv || adapter.notifications
    readonly property bool lockOn: !Edition.priv || adapter.lockscreen
    readonly property bool ownColorsOn: !Edition.priv || adapter.ownColors
    readonly property bool clipboardOn: !Edition.priv && adapter.clipboard
    readonly property string timeFmt: adapter.clock24 ? "HH:mm" : "h:mm AP"

    function systemLang() {
        let l = Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG") || ""
        if (!l) {
            const m = (localeConf.text() || "").match(/^LANG="?([^"\s]+)/m)
            if (m) l = m[1]
        }
        return l.startsWith("de") ? "de" : "en"
    }

    FileView {
        id: localeConf
        path: "/etc/locale.conf"
        blockLoading: true
    }

    FileView {
        path: root.path
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                adapter.language = root.systemLang()
                writeAdapter()
            }
        }

        JsonAdapter {
            id: adapter
            property string language: "en"
            property int idleLock: 10
            property bool clipboard: true
            property bool welcomeDone: false
            property bool glass: false
            property real glassOpacity: 0.55
            property string animations: "normal"
            property bool hoverDate: true
            property int musicLinger: 8
            property int notifDuration: 5
            property bool visualizer: true
            property bool systemRings: true
            property bool dnd: false
            property bool wallpaper: false
            property bool notifications: false
            property bool lockscreen: false
            property bool ownColors: false
            property string nightMode: "off"
            property string nightFrom: "20:00"
            property string nightTo: "07:00"
            property int nightTemp: 4500
            property bool batteryWarn: true
            property bool lockOnSleep: true
            property bool clock24: true
            property bool tapToClick: true
            property bool naturalScroll: true
            property bool typingBlock: true
            property real touchpadSpeed: 0
            property real mouseSpeed: 0
            property string kbLayouts: ""
            property string mainDisplay: ""
            property string displays: ""
            property bool displaySetup: false
            property bool termCopyPaste: false
        }
    }
}
