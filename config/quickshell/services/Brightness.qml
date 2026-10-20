pragma Singleton
import QtQuick
import Quickshell
import qs.core

Singleton {
    id: root

    property real value: -1
    readonly property bool available: value >= 0
    readonly property string icon: value < 0.4 ? "󰃞" : "󰃠"
    readonly property string pct: Math.round(value * 100) + "%"

    function ctl(args, done) {
        Util.run(["brightnessctl", "-m", "-c", "backlight", ...args], out => {
            const v = parseInt(out.split(",")[3])
            value = isNaN(v) ? -1 : v / 100
            if (done) done()
        })
    }
    function step(dir) { ctl(["set", dir > 0 ? "10%+" : "10%-"], () => { if (available) Ui.show("brightness", value) }) }
    function set(v) {
        value = Util.clamp(v, 0.01, 1)
        Ui.show("brightness", value)
        apply.start()
    }

    Timer { id: apply; interval: 60; onTriggered: root.ctl(["set", root.pct]) }
    Component.onCompleted: ctl([])
}
