import QtQuick
import qs.core

Rectangle {
    id: f
    property string hint: ""
    property bool secret: false
    property alias text: input.text
    signal accepted()
    function grab() { input.forceActiveFocus() }

    implicitWidth: 200
    implicitHeight: 36
    radius: 10
    color: input.activeFocus ? Theme.accA(0.06) : Theme.fgA(0.04)
    border { width: 1; color: input.activeFocus ? Theme.accent : Theme.fgA(0.07) }
    Behavior on color { CAnim {} }
    Behavior on border.color { CAnim {} }

    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: Theme.fg
        selectByMouse: true
        selectionColor: Theme.accA(0.3)
        echoMode: f.secret ? TextInput.Password : TextInput.Normal
        font { family: Theme.sans; pixelSize: 12 }
        onAccepted: f.accepted()
        T { anchors.verticalCenter: parent.verticalCenter; visible: !input.text; text: f.hint; color: Theme.fgA(0.3); font.pixelSize: 12 }
    }
}
