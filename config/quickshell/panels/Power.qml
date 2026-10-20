import QtQuick
import qs.core
import qs.services
import qs.widgets

Panel {
    id: pw
    property int asking: -1
    Timer { interval: 3000; running: pw.asking >= 0; onTriggered: pw.asking = -1 }

    Row {
        spacing: 10
        Repeater {
            model: [
                { icon: "󰌾", run: () => Power.lock() },
                { icon: "󰤄", run: () => Power.suspend() },
                { icon: "󰍃", run: () => Power.logout(),   confirm: true },
                { icon: "󰜉", run: () => Power.reboot(),   confirm: true },
                { icon: "󰐥", run: () => Power.poweroff(), confirm: true }
            ]
            Btn {
                required property var modelData
                required property int index
                size: 52
                iconSize: 18
                active: pw.asking === index
                icon: active ? "󰄬" : modelData.icon
                onClicked: {
                    if (modelData.confirm && !active) return pw.asking = index
                    modelData.run()
                    Ui.close()
                }
            }
        }
    }
}
