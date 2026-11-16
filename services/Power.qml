pragma Singleton
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    property real raw: UPower.displayDevice.percentage
    property int percent: Math.round(raw > 1 ? raw : raw * 100)
    property bool charging: !UPower.onBattery
    property bool present: UPower.displayDevice.isLaptopBattery
    property bool low: present && percent <= 15 && !charging
}
