//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import "core"
import "services"
import "island"
import "settings"
import "wallpaper"
import "lock"

ShellRoot {
    Variants {
        model: Quickshell.screens
        Scope {
            id: screenScope
            required property var modelData
            Wallpaper { screen: screenScope.modelData }
            Catcher { screen: screenScope.modelData }
            Island { screen: screenScope.modelData }
        }
    }

    SettingsWindow {}
    Lock {}

    Binding {
        target: Media
        property: "linger"
        value: Config.opt.musicLinger
    }

    Binding {
        target: Notifs
        property: "enabled"
        value: Config.opt.notifications
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
        function lockpreview(): void {
            IslandState.lockPreview = true
        }
    }
}
