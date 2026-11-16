import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../ui"

Column {
    id: page
    width: parent ? parent.width : 400
    readonly property string user: Quickshell.env("USER")
    readonly property string face: Quickshell.env("HOME") + "/.face"
    property string fullName: ""
    property var pictures: []
    property int faceRev: 0
    property bool hasFace: false
    property string msg: ""
    property bool msgOk: true

    onVisibleChanged: if (visible) query.running = true
    Component.onCompleted: if (visible) query.running = true

    function say(text, ok) {
        msg = text
        msgOk = ok
        msgTimer.restart()
    }

    Timer {
        id: msgTimer
        interval: 4000
        onTriggered: page.msg = ""
    }

    Process {
        id: query
        command: ["sh", "-c", "test -f \"$HOME/.face\" && echo face; echo '||'; getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1; echo '|||'; find \"$HOME/Pictures\" \"$HOME/Bilder\" /usr/share/canvas/wallpaper /usr/share/backgrounds -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | head -24"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.split("|||")
                const q = p[0].split("||")
                page.hasFace = q[0].trim() === "face"
                page.fullName = (q[1] || "").trim()
                nameField.text = page.fullName
                page.pictures = (p[1] || "").split("\n").filter(x => x !== "")
            }
        }
    }

    Process {
        id: setFace
        onExited: (code) => {
            page.hasFace = code === 0 || page.hasFace
            page.faceRev++
            page.say(code === 0 ? Lang.t.avatarSaved : Lang.t.failed, code === 0)
        }
    }

    Process {
        id: setName
        onExited: (code) => {
            if (code === 0) page.fullName = nameField.text
            page.say(code === 0 ? Lang.t.nameSaved : Lang.t.failed, code === 0)
        }
    }

    Process {
        id: setPw
        stdinEnabled: true
        onStarted: {
            write(page.user + ":" + pw1.text + "\n")
            stdinEnabled = false
        }
        onExited: (code) => {
            stdinEnabled = true
            pw1.text = ""
            pw2.text = ""
            page.say(code === 0 ? Lang.t.pwSaved : Lang.t.failed, code === 0)
        }
    }

    Row {
        spacing: 18
        bottomPadding: 10
        Rectangle {
            width: 84
            height: 84
            radius: 42
            color: Theme.accent
            clip: true
            Txt {
                anchors.centerIn: parent
                visible: avatar.status !== Image.Ready
                text: (page.fullName || page.user).charAt(0).toUpperCase()
                size: 36
                weight: Font.Bold
                color: Theme.base
            }
            Image {
                id: avatar
                anchors.fill: parent
                source: page.hasFace ? "file://" + page.face + "?" + page.faceRev : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                sourceSize.width: 168
                sourceSize.height: 168
                layer.enabled: false
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Txt { text: page.fullName || page.user; size: 20; weight: Font.Bold }
            Txt { text: page.user; size: 13; color: Theme.subtext }
        }
    }

    Rectangle {
        width: parent.width
        height: page.msg !== "" ? 40 : 0
        visible: height > 0
        radius: 14
        color: page.msgOk ? Theme.alpha(Theme.accent, 0.18) : Theme.alpha("#ff6b6b", 0.2)
        Behavior on height { NumberAnimation { duration: Theme.dur(200) } }
        Txt {
            anchors.centerIn: parent
            text: page.msg
            weight: Font.Medium
        }
    }

    SettingRow {
        title: Lang.t.accountName
        sub: Lang.t.accountNameSub
        Row {
            spacing: 8
            Field {
                id: nameField
                width: 200
                onAccepted: saveName.clicked()
            }
            PillButton {
                id: saveName
                text: Lang.t.save
                enabled: nameField.text.trim() !== "" && nameField.text !== page.fullName && nameField.text.indexOf(":") === -1
                onClicked: {
                    setName.command = ["pkexec", "chfn", "-f", nameField.text.trim(), page.user]
                    setName.running = true
                }
            }
        }
    }

    Txt {
        text: Lang.t.avatar
        size: 15
        weight: Font.DemiBold
        topPadding: 14
    }
    Txt {
        text: page.pictures.length ? Lang.t.avatarSub : Lang.t.avatarNone
        size: 12
        color: Theme.subtext
        bottomPadding: 8
    }
    Flow {
        width: parent.width
        spacing: 8
        bottomPadding: 10
        Repeater {
            model: page.pictures
            Rectangle {
                required property string modelData
                width: 58
                height: 58
                radius: 29
                clip: true
                color: Theme.surfaceHigh
                border.width: picArea.containsMouse ? 2 : 0
                border.color: Theme.accent
                scale: picArea.containsMouse ? 1.08 : 1
                Behavior on scale { NumberAnimation { duration: Theme.dur(180); easing.type: Easing.OutBack } }
                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 116
                    sourceSize.height: 116
                    asynchronous: true
                }
                MouseArea {
                    id: picArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        setFace.command = ["sh", "-c", 'if command -v magick >/dev/null; then magick "$1" -resize 256x256^ -gravity center -extent 256x256 "$2.png" && mv "$2.png" "$2"; else cp "$1" "$2"; fi', "sh", modelData, page.face]
                        setFace.running = true
                    }
                }
            }
        }
    }

    Txt {
        text: Lang.t.password
        size: 15
        weight: Font.DemiBold
        topPadding: 10
    }
    Txt {
        width: parent.width
        text: Lang.t.passwordSub
        size: 12
        color: Theme.subtext
        wrapMode: Text.WordWrap
        bottomPadding: 8
    }
    Row {
        spacing: 8
        Field { id: pw1; width: 170; password: true; placeholder: Lang.t.pwNew }
        Field { id: pw2; width: 170; password: true; placeholder: Lang.t.pwRepeat; onAccepted: pwBtn.clicked() }
        PillButton {
            id: pwBtn
            text: Lang.t.change
            busy: setPw.running
            enabled: pw1.text.length >= 4 && pw1.text === pw2.text
            onClicked: {
                setPw.command = ["pkexec", "chpasswd"]
                setPw.running = true
            }
        }
    }
    Txt {
        visible: pw2.text !== "" && pw1.text !== pw2.text
        text: Lang.t.pwMismatch
        size: 12
        color: "#ff8a8a"
        topPadding: 6
    }
}
