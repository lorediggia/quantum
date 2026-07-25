import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bottomEdge

    property color themeRawBg:  "#000000"
    property color themeAccent: "#ffffff"
    property color themeFg:     "#ffffff"
    readonly property color barColor: Qt.rgba(themeRawBg.r, themeRawBg.g, themeRawBg.b, 0.86)

    readonly property int thickness: 12
    property bool expanded: false

    function toggle() { expanded = !expanded }
    function close()  { expanded = false }

    WlrLayershell.namespace: "quickshell-bottomedge"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { bottom: true; left: true; right: true }
    exclusiveZone: 0
    implicitHeight: thickness + 420
    color: "transparent"

    mask: Region {
        item: strip
        Region { item: grower }
    }

    Shortcut {
        sequence: "Escape"
        enabled: bottomEdge.expanded
        onActivated: bottomEdge.close()
    }

    Item {
        id: grower
        anchors.bottom: parent.bottom
        anchors.bottomMargin: bottomEdge.thickness
        anchors.horizontalCenter: parent.horizontalCenter
        clip: true

        readonly property Item currentItem: pop.shouldBeActive ? pop.item : null

        implicitWidth:  currentItem ? currentItem.implicitWidth  : 0
        implicitHeight: currentItem ? currentItem.implicitHeight : 0
        width:  implicitWidth
        height: implicitHeight

        Behavior on implicitWidth  { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
        Behavior on implicitHeight { NumberAnimation { duration: 380; easing.type: Easing.OutExpo } }

        Rectangle {
            width: parent.width; height: parent.height + 18
            y: -18
            radius: 20
            color: bottomEdge.barColor
        }

        RevealLoader {
            id: pop
            anchors.fill: parent
            shouldBeActive: bottomEdge.expanded
            sourceComponent: Component {
                WallpaperGridContent {
                    themeFg:     bottomEdge.themeFg
                    themeAccent: bottomEdge.themeAccent
                    onRequestClose: bottomEdge.close()
                }
            }
        }
    }

    Rectangle {
        id: strip
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: bottomEdge.thickness
        color: bottomEdge.barColor
    }
}
