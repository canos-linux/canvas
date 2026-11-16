import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    property string zone: ""
    property bool ntp: true
    property var zones: []
    property date now: new Date()

    onVisibleChanged: if (visible) query.running = true
    Component.onCompleted: if (visible) query.running = true

    Timer {
        interval: 1000
        repeat: true
        running: page.visible
        triggeredOnStart: true
        onTriggered: page.now = new Date()
    }

    Process {
        id: query
        command: ["sh", "-c", "timedatectl show -p Timezone -p NTP; echo '|||'; timedatectl list-timezones"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split("|||")
                const z = p[0].match(/Timezone=(\S+)/)
                page.zone = z ? z[1] : ""
                page.ntp = /NTP=yes/.test(p[0])
                page.zones = (p[1] || "").split("\n").filter(x => x !== "")
            }
        }
    }

    Process {
        id: run
        onExited: query.running = true
    }

    function exec(args) {
        run.command = args
        run.running = true
    }

    Item {
        width: parent.width
        height: 96
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Txt {
                text: Qt.formatTime(page.now, Config.opt.clock24 ? "HH:mm:ss" : "h:mm:ss AP")
                size: 40
                weight: Font.Bold
                font.features: { "tnum": 1 }
            }
            Txt {
                text: page.now.toLocaleDateString(Lang.locale, Lang.t.dateLong) + (page.zone ? "  ·  " + page.zone.replace(/_/g, " ") : "")
                size: 14
                color: Theme.subtext
            }
        }
    }

    SettingRow {
        title: Lang.t.autoTime
        sub: Lang.t.autoTimeSub
        Toggle {
            checked: page.ntp
            onToggled: v => page.exec(["timedatectl", "set-ntp", v ? "true" : "false"])
        }
    }
    ChoiceRow {
        title: Lang.t.timezone
        sub: Lang.t.timezoneSub
        searchable: true
        options: page.zones.map(z => z.replace(/_/g, " "))
        values: page.zones
        value: page.zone
        onPicked: v => page.exec(["timedatectl", "set-timezone", v])
    }
    SettingRow {
        title: Lang.t.clock24
        sub: Lang.t.clock24Sub
        Toggle { checked: Config.opt.clock24; onToggled: v => Config.opt.clock24 = v }
    }
}
