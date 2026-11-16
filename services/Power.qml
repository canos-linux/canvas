pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root
    property real raw: UPower.displayDevice.percentage
    property int percent: Math.round(raw > 1 ? raw : raw * 100)
    property bool charging: !UPower.onBattery
    property bool present: UPower.displayDevice.isLaptopBattery
    property bool low: present && percent <= 15 && !charging

    readonly property int profile: PowerProfiles.profile
    readonly property string profileIcon: profile === PowerProfile.PowerSaver ? "󰌪" : profile === PowerProfile.Performance ? "󰓅" : "󰾅"

    property bool ready: false
    property int warned: 101
    property bool fullSent: false

    signal plugged()
    signal warn(int level)
    signal full()
    signal sleeping()

    function cycleProfile() {
        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced]
        if (PowerProfiles.hasPerformanceProfile) order.push(PowerProfile.Performance)
        const i = order.indexOf(profile)
        PowerProfiles.profile = order[(i + 1) % order.length]
    }

    function evaluate() {
        if (!ready || !present) return
        if (charging) {
            warned = 101
            if (percent >= 100 && !fullSent) {
                fullSent = true
                full()
            }
            return
        }
        fullSent = false
        for (const lv of [5, 10, 20]) {
            if (percent <= lv && warned > lv) {
                warned = lv
                warn(lv)
                break
            }
        }
    }

    onChargingChanged: {
        if (ready && present && charging) plugged()
        evaluate()
    }
    onPercentChanged: evaluate()

    Timer {
        interval: 4000
        running: true
        onTriggered: {
            root.ready = true
            root.evaluate()
        }
    }

    // lid close / suspend: logind announces PrepareForSleep(true)
    Process {
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("PrepareForSleep (true") !== -1) root.sleeping()
            }
        }
    }
}
