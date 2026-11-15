pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property string path: Quickshell.env("HOME") + "/.config/canvas/settings.json"
}
