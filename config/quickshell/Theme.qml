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
            if (root.isPressed) return Qt.rgba(1, 1, 1, 0.09)
            if (root.isHovered) return Qt.rgba(1, 1, 1, 0.05)
            return Qt.rgba(1, 1, 1, root.style === "panel" ? 0.025 : 0.015)
        }
        border.width: 1
        border.color: root.isActive
            ? Qt.rgba(root.tintColor.r, root.tintColor.g, root.tintColor.b, 0.40)
            : (root.isHovered ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08))

        Behavior on color        { ColorAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 280; easing.type: Easing.OutCubic } }
    }
}
