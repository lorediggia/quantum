import QtQuick
import qs.core

Item {
    id: lv
    property real value: 0
    property string icon: ""
    property string label: ""
    property bool dimmed: false
    signal moved(real v)
    signal secondary()

    readonly property bool hot: ma.containsMouse || ma.pressed
    implicitHeight: 46

    Rectangle {
        anchors.fill: parent
        radius: height * 0.34
        color: Theme.fgA(lv.hot ? 0.09 : 0.05)
        Behavior on color { CAnim {} }
        Rectangle {
            width: Math.max(parent.height, parent.width * lv.value)
            height: parent.height
            radius: parent.radius
            opacity: Math.min(1, parent.width * lv.value / parent.height)
            color: lv.dimmed ? Theme.fgA(0.1) : Theme.accA(0.22)
            Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
            Behavior on color { CAnim {} }
        }
    }
    T {
        anchors { left: parent.left; leftMargin: lv.height * 0.42; verticalCenter: parent.verticalCenter }
        text: lv.icon
        color: lv.dimmed ? Theme.fgA(0.35) : Theme.accent
        font.pixelSize: lv.height * 0.34
    }
    T {
        anchors { right: parent.right; rightMargin: lv.height * 0.42; verticalCenter: parent.verticalCenter }
        text: lv.label
        color: Theme.fgA(lv.hot ? 0.75 : 0.5)
        font { pixelSize: 11; weight: Font.Medium }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        function set(x) { lv.moved(Util.clamp(x / width, 0, 1)) }
        onPressed: m => m.button === Qt.RightButton ? lv.secondary() : set(m.x)
        onPositionChanged: m => { if (m.buttons & Qt.LeftButton) set(m.x) }
        onWheel: w => lv.moved(Util.clamp(lv.value + (w.angleDelta.y > 0 ? 0.05 : -0.05), 0, 1))
    }
}
