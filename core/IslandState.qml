pragma Singleton
import Quickshell
import QtQuick
import "../services"

Singleton {
    id: root
    property string temp: ""
    property string notifApp: ""
    property string notifTitle: ""
    property string notifBody: ""
    property var notifEntry: null
    property string overlay: ""
    property string expandedScreen: ""
    property bool settingsOpen: false
    property string settingsPage: ""
    property bool welcomeOpen: false
    property bool shooting: false
    property string launcherPrefix: ""
    property bool locked: false
    property bool lockPreview: false
    property int launcherRows: 0
    property real centerHeight: 400
    property real panelHeight: 300
    property string btPopName: ""
    property string btPopIcon: ""
    property real btPopBattery: -1
    property string powerAction: ""

    // shutdown / restart / logout: Canvas fades out first, then the system takes over (Plymouth)
    function power(action) {
        if (powerAction !== "") return
        closeAll()
        settingsOpen = false
        powerAction = action
        powerTimer.restart()
    }

    Timer {
        id: powerTimer
        interval: 1300
        onTriggered: {
            const a = root.powerAction
            if (a === "off") Quickshell.execDetached(["systemctl", "poweroff"])
            else if (a === "reboot") Quickshell.execDetached(["systemctl", "reboot"])
            else if (a === "logout") Quickshell.execDetached(["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\""])
            // still running after a while (e.g. shutdown blocked): show the desktop again
            powerReset.restart()
        }
    }

    Timer {
        id: powerReset
        interval: 15000
        onTriggered: root.powerAction = ""
    }

    function flash(kind, ms) {
        temp = kind
        timer.interval = ms
        timer.restart()
    }

    function notify(app, title, body) {
        show(Notifs.add(app, title, body))
    }

    function show(e) {
        if (Config.opt.dnd && !e.urgent) return
        notifEntry = e
        notifApp = e.app
        notifTitle = e.title
        notifBody = e.body
        flash("notif", Config.opt.notifDuration * 1000)
    }

    function closeAll() {
        overlay = ""
        expandedScreen = ""
    }

    function openClipboard() {
        launcherPrefix = ";"
        if (overlay === "launcher") overlay = ""
        overlay = "launcher"
    }

    function startShot() {
        closeAll()
        shotTimer.restart()
    }

    Timer {
        id: shotTimer
        interval: 300
        onTriggered: root.shooting = true
    }

    function toggleOverlay(name) {
        overlay = overlay === name ? "" : name
    }

    function lock() {
        if (Config.lockOn) locked = true
        else lockPreview = true
    }

    Timer {
        id: timer
        onTriggered: root.temp = ""
    }

    Connections {
        target: Audio
        function onBumped() {
            if (root.temp !== "notif") root.flash("volume", 1600)
        }
    }

    Connections {
        target: Audio
        function onMicBumped() {
            if (root.temp !== "notif") root.flash("mic", 1400)
        }
    }

    Connections {
        target: Auth
        function onActiveChanged() {
            if (Auth.active) root.overlay = "polkit"
            else if (root.overlay === "polkit") root.overlay = ""
        }
    }

    Connections {
        target: Power
        function onPlugged() {
            if (root.temp !== "notif") root.flash("charge", 2800)
        }
        function onWarn(level) {
            if (Config.opt.batteryWarn) root.notify("Canvas", Lang.t.batteryLow.replace("%1", level), level <= 5 ? Lang.t.batteryCritical : Lang.t.batteryPlug)
        }
        function onFull() {
            if (Config.opt.batteryWarn) root.notify("Canvas", Lang.t.batteryFull, "")
        }
        function onSleeping() {
            if (Config.opt.lockOnSleep) root.lock()
        }
    }

    Connections {
        target: Brightness
        function onBumped() {
            if (root.temp !== "notif") root.flash("brightness", 1600)
        }
    }

    Connections {
        target: Bt
        function onDeviceConnected(d) {
            root.btPopName = d.name
            root.btPopIcon = Bt.glyph(d)
            root.btPopBattery = d.batteryAvailable ? d.battery : -1
            if (root.temp !== "notif") root.flash("btdev", 3200)
        }
    }

    Connections {
        target: Hypr
        function onSwitched() {
            if (root.temp !== "volume" && root.temp !== "notif" && root.temp !== "brightness") root.flash("ws", 1100)
        }
    }
}
