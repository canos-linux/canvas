pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import "../core"

Singleton {
    id: root
    property bool manual: false
    property bool auto: false
    readonly property bool active: manual || auto
    readonly property bool hidesIsland: active && Config.opt.gameHideIsland
    readonly property bool blocksNotifs: active && Config.opt.gameDnd
    readonly property bool mutes: active && Config.opt.gameMuteSounds
    property int savedProfile: -1

    function toggle() {
        if (active) {
            manual = false
            auto = false
            autoOff = true
        } else {
            manual = true
        }
    }

    // user turned it off while a game runs: no automatic re-enable until the game is closed
    property bool autoOff: false

    onActiveChanged: {
        if (active) {
            if (Config.opt.gamePerformance) {
                savedProfile = PowerProfiles.profile
                PowerProfiles.profile = PowerProfile.Performance
            }
            if (Config.opt.gameNoAnim) Quickshell.execDetached(["hyprctl", "eval", "hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false } } })"])
        } else {
            if (savedProfile >= 0) PowerProfiles.profile = savedProfile
            savedProfile = -1
            if (Config.opt.gameNoAnim) Quickshell.execDetached(["hyprctl", "reload"])
        }
    }

    Process {
        id: scan
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                let found = false
                try {
                    found = JSON.parse(text).some(c => /^steam_app_|^gamescope$|\.exe$/i.test(c.class || "") || (c.fullscreen > 0 && /^(steam_app|lutris|heroic)/i.test(c.class || "")))
                } catch (e) {}
                if (!found) root.autoOff = false
                root.auto = found && !root.autoOff
            }
        }
    }

    Timer {
        interval: 4000
        repeat: true
        running: Config.opt.gameAuto
        onTriggered: scan.running = true
        onRunningChanged: if (!running) root.auto = false
    }
}
