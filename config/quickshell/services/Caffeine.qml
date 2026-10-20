pragma Singleton
import QtQuick
import Quickshell
import qs.core

Singleton {
    readonly property bool low: Power.hasBattery && !Power.charging && Power.percent <= 10
    readonly property bool active: Cfg.caffeine && !low
    readonly property string icon: active ? "󰅶" : "󰛊"

    function toggle() { Cfg.caffeine = !Cfg.caffeine }
}
