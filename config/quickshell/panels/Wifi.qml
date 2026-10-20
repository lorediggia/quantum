import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.core
import qs.services
import qs.widgets

Panel {
    id: wf
    property var asking: null
    property string error: ""

    function join(n) { error = ""; Net.secured(n) && !n.known ? ask(n) : n.connect() }
    function ask(n) { asking = n; pass.text = ""; pass.grab() }
    function submit() { asking.connectWithPsk(pass.text); asking = null }

    Head {
        icon: Net.icon
        title: !Net.on ? "off" : Net.active?.name ?? "disconnected"
        Toggle { checked: Net.on; onClicked: Networking.wifiEnabled = !Net.on }
    }
    RowLayout {
        visible: wf.asking !== null
        spacing: 8
        Field { id: pass; Layout.fillWidth: true; secret: true; hint: "󰌾"; onAccepted: wf.submit() }
        Btn { size: 36; icon: "󰁔"; active: true; enabled: pass.text !== ""; onClicked: wf.submit() }
    }
    Hint { error: true; text: wf.error }

    ListView {
        Layout.fillWidth: true
        Layout.leftMargin: -8
        Layout.rightMargin: -8
        implicitHeight: Math.min(count, 5) * 48
        visible: count > 0
        clip: true
        spacing: 2
        model: ScriptModel { values: Net.nets }
        delegate: ListRow {
            id: row
            required property var modelData
            width: ListView.view.width
            icon: Net.bars(modelData)
            title: modelData.name + (Net.secured(modelData) ? "  󰌾" : "")
            subtitle: modelData.connected ? "connected" : modelData.known ? "saved" : ""
            active: modelData.connected
            busy: modelData.stateChanging
            onClicked: modelData.connected ? modelData.disconnect() : wf.join(modelData)
            onRightClicked: if (modelData.known) modelData.forget()
            Connections {
                target: row.modelData
                function onConnectionFailed(reason) {
                    if (reason === ConnectionFailReason.NoSecrets) wf.ask(row.modelData)
                    else wf.error = "couldn't connect"
                }
            }
        }
    }
}
