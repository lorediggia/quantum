import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services
import qs.widgets

Panel {
    Head {
        icon: Bt.icon
        title: !Bt.adapter ? "no adapter" : !Bt.on ? "off" : Bt.connected ? Bt.connected + " connected" : "on"
        Toggle { visible: Bt.adapter !== null; checked: Bt.on; onClicked: Bt.setPower(!Bt.on) }
    }

    ListView {
        Layout.fillWidth: true
        Layout.leftMargin: -8
        Layout.rightMargin: -8
        implicitHeight: Math.min(count, 5) * 48
        visible: count > 0
        clip: true
        spacing: 2
        model: ScriptModel { values: Bt.on ? Bt.devices : [] }
        delegate: ListRow {
            id: row
            required property var modelData
            width: ListView.view.width
            icon: Bt.glyph(modelData)
            title: modelData.name
            subtitle: modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "connected") : modelData.paired ? "paired" : ""
            active: modelData.connected
            busy: Bt.busy(modelData)
            onClicked: if (!busy) Bt.activate(modelData)
            onRightClicked: if (modelData.paired) modelData.forget()
            Connections { target: row.modelData; function onPairedChanged() { if (row.modelData.paired) row.modelData.connect() } }
        }
    }
}
