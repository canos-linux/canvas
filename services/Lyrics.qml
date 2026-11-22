pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../core"

// synced lyrics from lrclib.net (free, no account)
Singleton {
    id: root
    readonly property bool wanted: Config.opt.widgets && Config.opt.wMusic && Config.opt.wLyrics
    property var lines: []   // [{ t: seconds, text }]
    property string key: ""
    readonly property int index: {
        const p = Media.position
        let i = -1
        for (let k = 0; k < lines.length; k++) {
            if (lines[k].t <= p + 0.3) i = k
            else break
        }
        return i
    }
    readonly property string current: index >= 0 ? lines[index].text : ""
    readonly property string next: index + 1 < lines.length ? lines[index + 1].text : ""

    function load() {
        const k = Media.artist + "|" + Media.title
        if (!wanted || Media.title === "" || k === key) return
        key = k
        lines = []
        // YouTube & co: "Artist - Title (Official Video)" from some channel -> artist + clean title
        let artist = Media.artist.replace(/ - Topic$/, "").replace(/VEVO$/i, "")
        let title = Media.title
        const dash = title.match(/^(.+?)\s+[-–—]\s+(.+)$/)
        if (dash) {
            artist = dash[1]
            title = dash[2]
        }
        title = title.replace(/\s*[\(\[][^\)\]]*[\)\]]/g, "").replace(/\s+(ft\.?|feat\.?)\s.*$/i, "").trim()
        artist = artist.replace(/\s*[\(\[][^\)\]]*[\)\]]/g, "").split(/,| & | x | feat/i)[0].trim()
        q.command = ["sh", "-c", "curl -fsGm 10 'https://lrclib.net/api/get' --data-urlencode \"artist_name=$1\" --data-urlencode \"track_name=$2\" -H 'User-Agent: Canvas (CanOS)' || curl -fsGm 10 'https://lrclib.net/api/search' --data-urlencode \"q=$1 $2\" -H 'User-Agent: Canvas (CanOS)'", "sh", artist, title]
        q.running = true
    }

    Process {
        id: q
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text)
                    if (Array.isArray(d)) d = d.find(x => x.syncedLyrics) || {}
                    const s = d.syncedLyrics || ""
                    const out = []
                    for (const l of s.split("\n")) {
                        const m = l.match(/^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/)
                        if (m) out.push({ t: parseInt(m[1]) * 60 + parseFloat(m[2]), text: m[3] })
                    }
                    root.lines = out
                } catch (e) {
                    root.lines = []
                }
            }
        }
    }

    Timer {
        id: debounce
        interval: 600
        onTriggered: root.load()
    }

    Connections {
        target: Media
        function onTitleChanged() { debounce.restart() }
        function onArtistChanged() { debounce.restart() }
    }

    onWantedChanged: if (wanted) debounce.restart()
}
