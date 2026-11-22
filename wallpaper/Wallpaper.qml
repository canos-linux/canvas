import Quickshell
import Quickshell.Wayland
import QtQuick
import QtMultimedia
import "../core"
import "../services"

PanelWindow {
    id: wall
    property bool busy: Hypr.busy[screen.name] === true

    visible: Config.wallpaperOn
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "canvas-wallpaper"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Loader {
        anchors.fill: parent
        active: wall.visible && CurrentTheme.dir !== ""

        sourceComponent: Item {
            Image {
                anchors.fill: parent
                source: "file://" + CurrentTheme.dir + "/lock.png"
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Video {
                id: video
                anchors.fill: parent
                visible: CurrentTheme.hasVideo
                source: CurrentTheme.hasVideo ? "file://" + CurrentTheme.dir + "/wallpaper.mp4" : ""
                fillMode: VideoOutput.PreserveAspectCrop
                loops: MediaPlayer.Infinite
                muted: true
                autoPlay: true
                opacity: playbackState === MediaPlayer.StoppedState ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 400 } }

                property bool shouldPlay: !wall.busy && !Gaming.active
                onShouldPlayChanged: shouldPlay ? play() : pause()
            }
        }
    }
}
