import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: leftEdge

    property color themeRawBg: "#000000"
    readonly property color barColor: Qt.rgba(themeRawBg.r, themeRawBg.g, themeRawBg.b, 0.86)

    readonly property int thickness: 12

    WlrLayershell.namespace: "quickshell-leftedge"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true }
    exclusiveZone: 0   
    implicitWidth: thickness
    color: "transparent"

    mask: Region {}   

    Rectangle {
        anchors.fill: parent
        color: leftEdge.barColor
    }
}
