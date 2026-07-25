import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color themeFg
    property color themeAccent
    property color themeSecond
    property color themeWarm
    property color themeFresh

    property real size:      36
    property real cornerRad: 11
    property real glyphSize: 15

    signal poweroff()
    signal reboot()
    signal suspend()

    implicitHeight: size
    implicitWidth:  size

    property int idx: 0
    readonly property var glyphs: ["󰐥", "󰜉", "󰤄"]

    IconButton {
        anchors.centerIn: parent
        boxSize: root.size; boxRadius: root.cornerRad; iconSize: root.glyphSize
        icon: root.glyphs[root.idx]
        tint: themeAccent
        baseFg: themeFg
        onActivated: {
            if (root.idx === 0)      root.poweroff()
            else if (root.idx === 1) root.reboot()
            else                     root.suspend()
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        hoverEnabled: false
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.idx = (root.idx + 1) % 3
            }
        }
    }
}
