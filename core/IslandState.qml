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
    property string overlay: ""
    property string expandedScreen: ""
    property bool settingsOpen: false
    property bool locked: false
    property bool lockPreview: false
    property int launcherRows: 0
    property real centerHeight: 400

    function flash(kind, ms) {
        temp = kind
        timer.interval = ms
        timer.restart()
    }

    function notify(app, title, body) {
        Notifs.add(app, title, body)
        if (Config.opt.dnd) return
        notifApp = app
        notifTitle = title
        notifBody = body
        flash("notif", Config.opt.notifDuration * 1000)
    }

    function closeAll() {
        overlay = ""
        expandedScreen = ""
    }

    function toggleOverlay(name) {
        overlay = overlay === name ? "" : name
    }

    function lock() {
        if (Config.opt.lockscreen) locked = true
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
        target: Brightness
        function onBumped() {
            if (root.temp !== "notif") root.flash("brightness", 1600)
        }
    }

    Connections {
        target: Hypr
        function onSwitched() {
            if (root.temp !== "volume" && root.temp !== "notif" && root.temp !== "brightness") root.flash("ws", 1100)
        }
    }
}
