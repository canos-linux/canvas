import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../core"

Row {
    id: music
    spacing: 12

    property var player: {
        const list = Mpris.players.values
        for (let i = 0; i < list.length; i++)
            if (list[i].isPlaying) return list[i]
        return list.length > 0 ? list[0] : null
    }
    property bool shown: player !== null
    property bool playing: player !== null && player.isPlaying
    property var levels: [0, 0, 0, 0, 0, 0, 0, 0]

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        Repeater {
            model: 8
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 4 + music.levels[index] * 0.18
                radius: 1.5
                color: Theme.accent
                Behavior on height { NumberAnimation { duration: 80 } }
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 240)
        elide: Text.ElideRight
        text: music.player ? (music.player.trackTitle + (music.player.trackArtist ? "  ·  " + music.player.trackArtist : "")) : ""
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 14
        font.weight: Font.Medium
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Repeater {
            model: ["󰒮", music.playing ? "󰏤" : "󰐊", "󰒭"]
            Text {
                text: modelData
                color: index === 1 ? Theme.accent : Theme.text
                font.family: Theme.iconFont
                font.pixelSize: index === 1 ? 22 : 18
                scale: btnHover.hovered ? 1.25 : 1
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                HoverHandler { id: btnHover }
                TapHandler {
                    onTapped: {
                        if (!music.player) return
                        if (index === 0) music.player.previous()
                        else if (index === 1) music.player.togglePlaying()
                        else music.player.next()
                    }
                }
            }
        }
    }

    Process {
        running: music.playing
        command: ["cava", "-p", Quickshell.shellDir + "/core/cava.conf"]
        stdout: SplitParser {
            onRead: data => music.levels = data.split(";").filter(s => s !== "").map(Number)
        }
        onRunningChanged: if (!running) music.levels = [0, 0, 0, 0, 0, 0, 0, 0]
    }
}
