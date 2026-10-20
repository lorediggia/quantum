import QtQuick
import qs.core

Tile {
    id: tg
    property bool checked: false

    implicitWidth: 40
    implicitHeight: 22
    radius: Math.round(height * 0.36)
    color: checked ? Theme.accent : Theme.fgA(0.1)

    Rectangle {
        x: tg.checked ? tg.width - width - 3 : 3
        anchors.verticalCenter: parent.verticalCenter
        width: tg.height - 6
        height: width
        radius: Math.round(width * 0.36)
        color: tg.checked ? Theme.bg : Theme.fgA(0.55)
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on color { CAnim {} }
    }
}
