import QtQuick

Rectangle {
    id: t
    readonly property alias hovered: ma.containsMouse
    readonly property alias pressed: ma.pressed
    signal clicked()
    signal rightClicked()

    radius: 10
    color: "transparent"
    Behavior on color { CAnim {} }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? t.rightClicked() : t.clicked()
    }
}
