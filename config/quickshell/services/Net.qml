pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
import qs.core

Singleton {
    id: root
    readonly property WifiDevice wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool on: Networking.wifiEnabled
    readonly property var nets: [...(wifi?.networks.values ?? [])].filter(n => n.name)
        .sort((a, b) => b.connected - a.connected || b.known - a.known || level(b) - level(a) || a.name.localeCompare(b.name))
    readonly property var active: nets.find(n => n.connected) ?? null
    readonly property string icon: active ? bars(active) : "󰖪"

    Binding { target: root.wifi; property: "scannerEnabled"; value: Ui.open === "wifi"; when: root.wifi !== null }

    function level(n) { return Math.min(4, Math.floor(n.signalStrength * 5)) }
    function bars(n) { return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][level(n)] }
    function secured(n) { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }
}
