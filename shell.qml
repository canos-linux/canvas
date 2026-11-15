//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick
import "core"
import "island"

ShellRoot {
    Variants {
        model: Quickshell.screens
        Island {
            required property var modelData
            screen: modelData
        }
    }

    IpcHandler {
        target: "island"
        function notify(app: string, title: string, body: string): void {
            IslandState.notify(app, title, body)
        }
    }
}
