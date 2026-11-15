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

    function flash(kind, ms) {
        temp = kind
        timer.interval = ms
        timer.restart()
    }

    function notify(app, title, body) {
        notifApp = app
        notifTitle = title
        notifBody = body
        flash("notif", 5000)
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
        target: Hypr
        function onSwitched() {
            if (root.temp !== "volume" && root.temp !== "notif") root.flash("ws", 1100)
        }
    }
}
