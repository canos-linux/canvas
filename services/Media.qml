pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    property var player: {
        const list = Mpris.players.values
        for (let i = 0; i < list.length; i++)
            if (list[i].isPlaying) return list[i]
        if (lastPlayer && list.indexOf(lastPlayer) !== -1) return lastPlayer
        return list.length > 0 ? list[0] : null
    }
    property var lastPlayer: null
    property int linger: 8
    property bool recent: playing || (linger > 0 && pauseTimer.running)
    onPlayingChanged: {
        if (playing) lastPlayer = player
        else pauseTimer.restart()
    }

    Timer {
        id: pauseTimer
        interval: Math.max(1, root.linger) * 1000
    }
    property bool playing: player !== null && player.isPlaying
    property string title: player ? player.trackTitle : ""
    property string artist: player ? player.trackArtist : ""
    property string art: player ? player.trackArtUrl : ""
    property var levels: [0, 0, 0, 0, 0, 0, 0, 0]
    property real position: 0
    // some players (Firefox) drop the length for a moment after seeking: keep the last known one for this track
    readonly property real liveLength: player && player.lengthSupported && player.length > 0 ? player.length : 0
    property real knownLength: 0
    property string knownTrack: ""
    onLiveLengthChanged: if (liveLength > 0) { knownLength = liveLength; knownTrack = title }
    property real length: liveLength > 0 ? liveLength : (knownTrack === title ? knownLength : 0)

    function seek(fraction) {
        if (player && player.canSeek && length > 0) {
            player.position = fraction * length
            position = fraction * length
        }
    }

    Timer {
        interval: 400
        repeat: true
        running: root.playing
        triggeredOnStart: true
        onTriggered: {
            if (!root.player) return
            root.player.positionChanged()
            if (root.player.positionSupported) root.position = root.player.position
        }
    }

    function toggle() { if (player) player.togglePlaying() }
    function next() { if (player) player.next() }
    function previous() { if (player) player.previous() }

    Process {
        running: root.playing
        command: ["cava", "-p", Quickshell.shellDir + "/core/cava.conf"]
        stdout: SplitParser {
            onRead: data => root.levels = data.split(";").filter(s => s !== "").map(Number)
        }
        onRunningChanged: if (!running) root.levels = [0, 0, 0, 0, 0, 0, 0, 0]
    }
}
