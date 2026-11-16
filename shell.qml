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

ShellRoot {
    Variants {
        model: Quickshell.screens
        Scope {
            id: screenScope
            required property var modelData
            Wallpaper { screen: screenScope.modelData }
            Catcher { screen: screenScope.modelData }
            Island { screen: screenScope.modelData }
            RegionShot { screen: screenScope.modelData }
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
        function onReceived(app, title, body) {
            IslandState.notify(app, title, body)
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
            IslandState.settingsOpen = !IslandState.settingsOpen
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
        function clipboard(): void {
            IslandState.openClipboard()
        }
        function screenshot(): void {
            IslandState.startShot()
        }
        function welcome(): void {
            IslandState.welcomeOpen = true
        }
        function lockpreview(): void {
            IslandState.lockPreview = true
        }
    }
}
