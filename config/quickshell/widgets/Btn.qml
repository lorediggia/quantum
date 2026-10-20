import QtQuick
import qs.core

Tile {
    id: b
    property string icon: ""
    property string label: ""
    property bool active: false
    property bool lit: false
    property bool plain: false
    property real size: 26
    property real iconSize: 15
    readonly property color ink: active ? Theme.fg : hovered || lit ? Theme.accent : Theme.fgA(0.6)

    implicitWidth: label ? row.implicitWidth + 16 : size
    implicitHeight: size
    radius: size * 0.36
    color: plain ? "transparent" : active ? Theme.accA(0.22) : hovered ? Theme.accA(0.12) : Theme.fgA(0.05)
    opacity: enabled ? 1 : 0.35

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        scale: b.pressed ? 0.85 : 1
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        T { visible: text !== ""; text: b.icon; color: b.ink; font.pixelSize: b.iconSize; anchors.verticalCenter: parent.verticalCenter; Behavior on color { CAnim {} } }
        T { visible: text !== ""; text: b.label; color: b.ink; font.pixelSize: 11; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter; Behavior on color { CAnim {} } }
    }
}
