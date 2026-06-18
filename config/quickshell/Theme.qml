import QtQuick

Item {
    id: root

    property string style:        "button"  
    property color  tintColor:    "#ffffff"
    property color  panelSecond:  "#ffffff"
    property bool   isHovered:    false
    property bool   isPressed:    false
    property bool   isActive:     false
    property bool   drawActiveBg: true
    property real   radius:       12

    implicitWidth:  parent ? parent.width  : 0
    implicitHeight: parent ? parent.height : 0

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: {
            if (root.isActive && root.drawActiveBg)
                return Qt.rgba(root.tintColor.r, root.tintColor.g, root.tintColor.b, 0.18)
            return Qt.rgba(1, 1, 1, root.style === "panel" ? 0.025 : 0.015)
        }
        border.width: 0
        Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutCubic } }
    }
}