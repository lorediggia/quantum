pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.core

Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property string icon: on ? "󰂯" : "󰂲"
    readonly property var devices: [...(adapter?.devices.values ?? [])].filter(d => d.name)
        .sort((a, b) => b.connected - a.connected || b.paired - a.paired || a.name.localeCompare(b.name))
    readonly property int connected: devices.filter(d => d.connected).length

    Binding { target: root.adapter; property: "discovering"; value: Ui.open === "bluetooth"; when: root.on }

    function setPower(enable) {
        if (enable) Util.spawn(["rfkill", "unblock", "bluetooth"])
        if (adapter) adapter.enabled = enable
    }
    function busy(d) { return d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting }
    function activate(d) {
        if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else { d.trusted = true; d.pair() }
    }
    function glyph(d) {
        const t = d.icon
        return /head|audio/.test(t) ? "󰋋" : /keyboard/.test(t) ? "󰌌" : /mouse/.test(t) ? "󰍽"
             : /phone/.test(t) ? "󰏲" : /computer/.test(t) ? "󰍹" : /gaming/.test(t) ? "󰊴" : "󰂯"
    }
}
