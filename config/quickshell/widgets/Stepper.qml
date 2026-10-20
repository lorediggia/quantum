import QtQuick
import qs.core

Rectangle {
    id: s
    property real value: 0
    property real from: 0
    property real to: 100
    property real step: 1
    property string suffix: ""
    signal moved(real v)

    function nudge(dir) { const v = Math.round(Util.clamp(value + dir * step, from, to) * 100) / 100; if (v !== value) moved(v) }

    implicitWidth: 108
    implicitHeight: 28
    radius: 10
    color: Theme.fgA(0.04)

    T { anchors.centerIn: parent; text: s.value + s.suffix; font { pixelSize: 11; weight: Font.Medium } }
    Btn { plain: true; size: 28; icon: "−"; enabled: s.value > s.from; onClicked: s.nudge(-1) }
    Btn { plain: true; size: 28; icon: "+"; enabled: s.value < s.to; onClicked: s.nudge(1); anchors.right: parent.right }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: w => s.nudge(Math.sign(w.angleDelta.y)) }
}
