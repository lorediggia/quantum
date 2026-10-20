import QtQuick
import qs.core

Flow {
    id: c
    property var options: []
    property var current
    signal picked(var value)
    spacing: 5

    Repeater {
        model: c.options
        Tile {
            id: chip
            required property var modelData
            readonly property var value: modelData.value ?? modelData
            readonly property bool on: Array.isArray(c.current) ? c.current.includes(value) : c.current === value
            width: label.implicitWidth + 20
            height: 28
            color: on ? Theme.accA(0.2) : hovered ? Theme.fgA(0.08) : Theme.fgA(0.04)
            onClicked: c.picked(value)
            T { id: label; anchors.centerIn: parent; text: chip.modelData.label ?? chip.modelData; color: chip.on ? Theme.accent : Theme.fgA(0.55); font.pixelSize: 11 }
        }
    }
}
