import Quickshell
import Quickshell.Wayland
import QtQuick
import "../core"
import "../services"

Scope {
    WlSessionLock {
        locked: IslandState.locked

        WlSessionLockSurface {
            color: "black"
            LockContent {
                anchors.fill: parent
                onUnlocked: IslandState.locked = false
            }
        }
    }

    LazyLoader {
        active: IslandState.lockPreview

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor) || Quickshell.screens[0]
            color: "black"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "canvas-lock"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            LockContent {
                anchors.fill: parent
                preview: true
                onUnlocked: IslandState.lockPreview = false
            }
        }
    }
}
