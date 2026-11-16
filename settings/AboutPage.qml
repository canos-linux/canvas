import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    property var info: ({})
    property int updates: -1
    property bool checking: false

    onVisibleChanged: if (visible && !info.os) query.running = true
    Component.onCompleted: if (visible) query.running = true

    function row(k, v) {
        return { k: k, v: v }
    }

    Process {
        id: query
        command: ["sh", "-c", ". /etc/os-release; echo \"os=${NAME:-Linux} ${VERSION:-}\"; echo \"canvas=$(cat /usr/share/canvas/VERSION 2>/dev/null || cat \"$(dirname \"$(readlink -f \"$(command -v canvas)\")\")/../VERSION\" 2>/dev/null)\"; echo \"device=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null) $(cat /sys/class/dmi/id/product_name 2>/dev/null)\"; echo \"cpu=$(LC_ALL=C lscpu | sed -n 's/^Model name: *//p' | head -1)\"; echo \"gpu=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | sed 's/^[^:]*: [^:]*: //; s/ (rev.*//' | paste -sd '|')\"; echo \"ram=$(awk '/MemTotal/ {printf \"%.1f\", $2/1048576}' /proc/meminfo)\"; echo \"disk=$(df -h --output=used,size / | tail -1 | awk '{print $1\" / \"$2}')\"; echo \"kernel=$(uname -r)\"; echo \"de=Hyprland $(hyprctl version -j 2>/dev/null | sed -n 's/.*\"tag\": *\"\\([^\"]*\\)\".*/\\1/p' | head -1)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i > 0) o[line.slice(0, i)] = line.slice(i + 1).trim()
                }
                page.info = o
            }
        }
    }

    Process {
        id: check
        command: ["sh", "-c", "n=$( (checkupdates 2>/dev/null; flatpak remote-ls --updates 2>/dev/null) | grep -c .); echo $n"]
        stdout: StdioCollector {
            onStreamFinished: page.updates = parseInt(text) || 0
        }
        onExited: page.checking = false
    }

    Row {
        spacing: 18
        bottomPadding: 14
        Rectangle {
            width: 76
            height: 76
            radius: 26
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.accent }
                GradientStop { position: 1; color: Theme.accent2 }
            }
            Txt {
                anchors.centerIn: parent
                text: "C"
                size: 38
                weight: Font.Black
                color: Theme.base
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Txt { text: page.info.os || "CanOS"; size: 26; weight: Font.Bold }
            Txt { text: "Canvas " + (page.info.canvas || "") + "  ·  " + (page.info.de || "Hyprland"); size: 13; color: Theme.subtext }
            Txt { text: Lang.t.slogan; size: 13; color: Theme.accent; weight: Font.Medium }
            Row {
                spacing: 8
                topPadding: 8
                PillButton { text: Lang.t.website; onClicked: Quickshell.execDetached(["xdg-open", "https://tschaki11.github.io/canos/"]) }
                PillButton { text: Lang.t.reportBug; onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/tschaki11/canos-iso/issues"]) }
            }
        }
    }

    Repeater {
        model: [
            page.row(Lang.t.infoDevice, page.info.device),
            page.row(Lang.t.infoCpu, page.info.cpu),
            page.row(Lang.t.infoGpu, (page.info.gpu || "").split("|").join("\n")),
            page.row(Lang.t.infoRam, page.info.ram ? Lang.num(page.info.ram) + " GB" : ""),
            page.row(Lang.t.infoDisk, page.info.disk),
            page.row(Lang.t.infoKernel, page.info.kernel)
        ]
        Item {
            required property var modelData
            visible: (modelData.v || "").trim() !== ""
            width: page.width
            height: visible ? Math.max(40, val.implicitHeight + 18) : 0
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.k
                size: 14
                color: Theme.subtext
            }
            Txt {
                id: val
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 150
                horizontalAlignment: Text.AlignRight
                text: modelData.v || ""
                size: 14
                weight: Font.Medium
                wrapMode: Text.WordWrap
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.alpha(Theme.text, 0.06)
            }
        }
    }

    Txt {
        text: Lang.t.updates
        size: 13
        weight: Font.DemiBold
        color: Theme.accent
        topPadding: 18
    }
    SettingRow {
        title: page.checking ? Lang.t.updatesChecking : page.updates < 0 ? Lang.t.updatesUnknown : page.updates === 0 ? Lang.t.updatesNone : Lang.t.updatesAvail.arg(page.updates)
        sub: Lang.t.updatesSub
        Row {
            spacing: 8
            PillButton {
                text: Lang.t.updatesCheck
                busy: page.checking
                onClicked: {
                    page.checking = true
                    check.running = true
                }
            }
            PillButton {
                text: Lang.t.updatesRun
                primary: page.updates > 0
                onClicked: Quickshell.execDetached(["kitty", "--title", "CanOS Update", "-e", "canos-update"])
            }
        }
    }

    Txt {
        text: Lang.t.aboutShortcuts
        size: 12
        color: Theme.subtext
        topPadding: 18
        width: parent.width
        wrapMode: Text.WordWrap
    }
}
