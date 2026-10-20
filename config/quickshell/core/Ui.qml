pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var icons: ({
        launcher: "󰏗", audio: "󰕾", wifi: "󰖩", bluetooth: "󰂯",
        notifications: "󰂚", power: "󰐥", settings: "󰒓", wallpapers: "󰸉",
        overview: "󰖯", sidebar: "󱂬", caffeine: "󰛊",
        stickers: "󰞅", profile: "󰗑", gamemode: "󰊴", update: "󰚰"
    })
    property string open: ""

    function toggle(name) { open = open === name ? "" : name }
    function close() { open = "" }

    property string osd: ""
    property real osdValue: 0
    function show(kind, v) { osd = kind; osdValue = Math.max(0, Math.min(1, v)); hide.restart() }
    Timer { id: hide; interval: 1500; onTriggered: root.osd = "" }
}
