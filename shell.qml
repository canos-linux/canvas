//@ pragma UseQApplication
import Quickshell
import QtQuick
import "bar"

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
