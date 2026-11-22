//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "core"
import "services"
import "island"
import "settings"
import "wallpaper"
import "lock"
import "shot"
import "welcome"
import "overlay"
import "overview"
import "widgets"

ShellRoot {
    readonly property bool hyprConfReady: HyprConf.ready
    // first start with several displays, main display focus
    readonly property bool displaysReady: Displays.ready
    // singletons that must run from the start (login sound, KDE Connect daemon)
    readonly property bool soundsOn: Sounds.on
    readonly property bool phoneOn: Phone.installed

    Variants {
        model: Quickshell.screens
        Scope {
            id: screenScope
            required property var modelData
            Wallpaper { screen: screenScope.modelData }
            LazyLoader {
                active: screenScope.modelData.name === (Displays.mainName || screenScope.modelData.name)
                Desktop { screen: screenScope.modelData }
            }
            Catcher { screen: screenScope.modelData }
            Island { screen: screenScope.modelData }
            RegionShot { screen: screenScope.modelData }
            Identify { screen: screenScope.modelData }
            PowerFade { screen: screenScope.modelData }
            Overview { screen: screenScope.modelData }
        }
    }

    SettingsWindow {}
    Lock {}
    Welcome {}

    // Recreated when the setting changes: IdleMonitor does not pick up later
    // changes of enabled/timeout reliably.
    Instantiator {
        model: Config.lockOn && Config.opt.idleLock > 0 ? [Config.opt.idleLock] : []
        delegate: IdleMonitor {
            required property int modelData
            timeout: modelData * 60
            respectInhibitors: true
            onIsIdleChanged: if (isIdle) IslandState.lock()
        }
    }

    Process {
        running: Config.clipboardOn
        command: ["wl-paste", "--watch", "cliphist", "store"]
    }

    Binding {
        target: Media
        property: "linger"
        value: Config.opt.musicLinger
    }

    Binding {
        target: Notifs
        property: "enabled"
        value: Config.notificationsOn
    }

    Connections {
        target: Notifs
        function onPosted(e) {
            IslandState.show(e)
        }
    }

    IpcHandler {
        target: "island"
        function notify(app: string, title: string, body: string): void {
            IslandState.notify(app, title, body)
        }
        function launcher(): void {
            IslandState.toggleOverlay("launcher")
        }
        function themes(): void {
            IslandState.toggleOverlay("themes")
        }
        function center(): void {
            IslandState.expandedScreen = IslandState.expandedScreen !== "" ? "" : (Hypr.focusedMonitor || Quickshell.screens[0].name)
        }
        function settings(): void {
            IslandState.settingsPage = ""
            IslandState.settingsOpen = !IslandState.settingsOpen
        }
        function settingspage(page: string): void {
            IslandState.settingsPage = page
            IslandState.settingsOpen = true
        }
        function lock(): void {
            IslandState.lock()
        }
        function power(): void {
            IslandState.toggleOverlay("power")
        }
        function wifi(): void {
            IslandState.toggleOverlay("wifi")
        }
        function bluetooth(): void {
            IslandState.toggleOverlay("bt")
        }
        function audio(): void {
            IslandState.toggleOverlay("audio")
        }
        function micmute(): void {
            Audio.toggleMic()
        }
        function nightlight(): void {
            Night.cycle()
        }
        function profile(): void {
            Power.cycleProfile()
        }
        function charge(): void {
            IslandState.flash("charge", 2800)
        }
        function clipboard(): void {
            IslandState.openClipboard()
        }
        function screenshot(): void {
            IslandState.startShot()
        }
        function welcome(): void {
            IslandState.welcomeOpen = true
        }
        function powerpreview(): void {
            IslandState.powerPreview()
        }
        function identify(): void {
            Displays.identify()
        }
        function overview(): void {
            IslandState.overlay = ""
            IslandState.expandedScreen = ""
            IslandState.overview = !IslandState.overview
        }
        function record(): void {
            Recorder.toggle(false)
        }
        function recordregion(): void {
            Recorder.toggle(true)
        }
        function gaming(): void {
            Gaming.toggle()
        }
        function timer(seconds: int): void {
            IslandState.startTimer(seconds)
        }
        function quick(): void {
            IslandState.toggleOverlay("quick")
        }
        function lockpreview(): void {
            IslandState.lockPreview = true
        }
    }
}
