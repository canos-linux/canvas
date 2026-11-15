pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root
    property var history: []
    property bool enabled: false
    signal received(string app, string title, string body)

    function add(app, title, body) {
        const list = history.slice()
        list.unshift({ app: app, title: title, body: body, time: Qt.formatTime(new Date(), "HH:mm") })
        history = list.slice(0, 30)
    }

    function clear() {
        history = []
    }

    LazyLoader {
        active: root.enabled

        NotificationServer {
            bodySupported: true
            actionsSupported: false
            imageSupported: false
            onNotification: n => {
                n.tracked = true
                root.received(n.appName || "System", n.summary, n.body)
            }
        }
    }
}
