pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.core

Singleton {
    id: root

    readonly property UPowerDevice bat: UPower.displayDevice
    readonly property bool hasBattery: bat?.isLaptopBattery ?? false
    readonly property int percent: hasBattery ? Math.round(bat.percentage * 100) : -1
    readonly property bool charging: hasBattery && (bat.state === UPowerDeviceState.Charging || bat.state === UPowerDeviceState.FullyCharged)
    readonly property string pct: hasBattery ? percent + "%" : ""
    readonly property string icon: !hasBattery ? "󰐥" : charging ? "󰂄"
        : ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.round(percent / 10)]

    property int warned: 100
    onChargingChanged: warned = 100
    onPercentChanged: {
        const lvl = [5, 10, 20].find(l => percent <= l && l < warned)
        if (lvl === undefined || charging || !hasBattery) return
        warned = lvl
        Util.notify(lvl <= 5 ? "Battery critically low" : "Battery low", pct + " remaining", lvl <= 10 ? "critical" : "normal", "󰂃")
    }

    readonly property var profiles: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
    readonly property string profileIcon: ["󰌪", "󰗑", "󰓅"][profiles.indexOf(PowerProfiles.profile)] ?? "󰗑"
    function cycleProfile() {
        const avail = PowerProfiles.hasPerformanceProfile ? profiles : profiles.slice(0, 2)
        PowerProfiles.profile = avail[(avail.indexOf(PowerProfiles.profile) + 1) % avail.length]
    }

    function lock()     { Util.spawn(["hyprlock"]) }
    function suspend()  { Util.spawn(["systemctl", "suspend"]) }
    function logout()   { Hypr.exit() }
    function reboot()   { Util.spawn(["systemctl", "reboot"]) }
    function poweroff() { Util.spawn(["systemctl", "poweroff"]) }
}
