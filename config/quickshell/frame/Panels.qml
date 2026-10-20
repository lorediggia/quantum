import QtQuick
import qs.core
import qs.widgets

Notch {
    id: host
    required property var names
    property string last: ""
    property bool dismiss: true
    Connections { target: Ui; function onOpenChanged() { if (host.names.includes(Ui.open)) host.last = Ui.open } }
    readonly property Item current: {
        for (let i = 0; i < stack.count; i++) if (stack.itemAt(i)?.shown) return stack.itemAt(i).item
        return null
    }

    open: names.includes(Ui.open)
    bodyW: current?.implicitWidth ?? 0
    bodyH: current?.implicitHeight ?? 0

    MouseArea { anchors.fill: parent; z: 1; enabled: host.dismiss; acceptedButtons: Qt.RightButton; onClicked: Ui.close() }
    Repeater {
        id: stack
        model: host.names
        Loader {
            required property string modelData
            readonly property bool shown: Ui.open === modelData
            anchors.horizontalCenter: parent.horizontalCenter
            width: item?.implicitWidth || host.w
            height: item?.implicitHeight || host.h
            source: `../panels/${modelData[0].toUpperCase() + modelData.slice(1)}.qml`
            active: shown || opacity > 0
            enabled: shown
            opacity: shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
