pragma Singleton
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    property real raw: UPower.displayDevice.percentage
    property int percent: Math.round(raw > 1 ? raw : raw * 100)
    property bool charging: !UPower.onBattery
    property bool low: percent <= 15 && !charging
}
