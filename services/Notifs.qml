pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import "../core"

Singleton {
    id: root
    property var history: []
    property bool enabled: false
    property int counter: 0
    property var objects: ({})
    property real now: Date.now()
    signal posted(var entry)

    // newest app group first, newest entry first inside a group
    readonly property var sorted: {
        const order = []
        for (const e of history) if (order.indexOf(e.app) === -1) order.push(e.app)
        let out = []
        for (const a of order) out = out.concat(history.filter(e => e.app === a))
        return out
    }

    function make(app, title, body, extra) {
        counter++
        const e = { uid: counter, app: app || "System", title: title || "", body: body || "", time: Date.now(),
                    icon: "", image: "", actions: [], hasDefault: false, reply: false, replyHint: "", urgent: false }
        for (const k in extra) e[k] = extra[k]
        const list = history.slice()
        list.unshift(e)
        history = list.slice(0, 50)
        return e
    }

    function add(app, title, body) {
        return make(app, title, body, {})
    }

    function drop(uid) {
        const n = objects[uid]
        if (n) {
            try { n.dismiss() } catch (x) {}
            delete objects[uid]
        }
    }

    function remove(uid) {
        drop(uid)
        history = history.filter(e => e.uid !== uid)
    }

    function clearApp(app) {
        for (const e of history) if (e.app === app) drop(e.uid)
        history = history.filter(e => e.app !== app)
    }

    function clear() {
        for (const e of history) drop(e.uid)
        history = []
    }

    function invoke(uid, id) {
        const n = objects[uid]
        if (!n) return
        const a = n.actions.find(x => x.identifier === id)
        if (a) a.invoke()
        if (!n.resident) remove(uid)
    }

    function reply(uid, text) {
        const n = objects[uid]
        if (!n || text === "") return
        n.sendInlineReply(text)
        remove(uid)
    }

    function ago(t) {
        const m = Math.floor((root.now - t) / 60000)
        return m < 1 ? Lang.t.now : m < 60 ? Lang.t.minAgo.replace("%1", m) : Qt.formatTime(new Date(t), "HH:mm")
    }

    function iconSource(icon) {
        if (!icon) return ""
        if (icon.startsWith("/") || icon.indexOf("://") !== -1) return icon
        return Quickshell.iconPath(icon, true)
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    LazyLoader {
        active: root.enabled

        NotificationServer {
            bodySupported: true
            actionsSupported: true
            imageSupported: true
            inlineReplySupported: true
            onNotification: n => {
                n.tracked = true
                root.now = Date.now()
                const acts = n.actions.map(a => ({ id: a.identifier, text: a.text }))
                const e = root.make(n.appName, n.summary, n.body, {
                    icon: n.appIcon || "",
                    image: n.image || "",
                    actions: acts.filter(a => a.id !== "default" && a.text !== ""),
                    hasDefault: acts.some(a => a.id === "default"),
                    reply: n.hasInlineReply,
                    replyHint: n.inlineReplyPlaceholder || "",
                    urgent: n.urgency === NotificationUrgency.Critical
                })
                root.objects[e.uid] = n
                root.posted(e)
            }
        }
    }
}
