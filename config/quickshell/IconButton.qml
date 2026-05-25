import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string icon:    ""
    property string value:   ""
    property color  tint:    "#ffffff"
    property color  baseFg:  "#ffffff"
    property color  rawBg:   "#000000"

    property bool active:       false
    property bool drawActiveBg: true

    property real boxSize:   48
    property real boxRadius: 12
    property real iconSize:  18
    property real valueSize: 12
    property real hPadding:  16

    signal activated()

    function fgColor() {
        if (root.active || btnMouse.pressed) return root.baseFg
        return btnMouse.containsMouse
            ? root.tint
            : Qt.rgba(root.baseFg.r, root.baseFg.g, root.baseFg.b, 0.75)
    }

    implicitWidth:  (value === "") ? boxSize : content.implicitWidth + hPadding
    implicitHeight: boxSize

    Theme {
        anchors.fill: parent
        radius:       root.boxRadius
        style:        "button"
        tintColor:    root.tint
        isActive:     root.active
        isHovered:    btnMouse.containsMouse
        isPressed:    btnMouse.pressed
        drawActiveBg: root.drawActiveBg

        scale: btnMouse.pressed ? 0.95 : 1.0
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.icon
                color: root.fgColor()
                font {
                    family:    "JetBrainsMono Nerd Font"
                    pixelSize: root.iconSize
                    weight:    root.active ? Font.Bold : Font.Medium
                }
                Behavior on color { ColorAnimation { duration: 220 } }
            }

            Text {
                visible: root.value !== ""
                text:    root.value
                color: root.fgColor()
                font {
                    family:    "JetBrainsMono Nerd Font"
                    pixelSize: root.valueSize
                    weight:    Font.Medium
                }
                Behavior on color { ColorAnimation { duration: 220 } }
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill:  parent
            hoverEnabled:  true
            cursorShape:   Qt.PointingHandCursor
            onClicked:     root.activated()
        }
    }
}
