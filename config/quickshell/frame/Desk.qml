import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services
import qs.widgets

PanelWindow {
    id: desk
    readonly property real size: Cfg.desktop.size
    readonly property real cs: size + 32
    readonly property int cols: Math.max(1, Math.floor((width - 16) / cs))
    readonly property int lines: Math.max(1, Math.floor((height - 16) / cs))
    readonly property real px: Math.round((width - cols * cs) / 2)
    readonly property real py: Math.round((height - lines * cs) / 2)
    function cell(x, y) {
        return { col: Util.clamp(Math.floor((x - px) / cs), 0, cols - 1), row: Util.clamp(Math.floor((y - py) / cs), 0, lines - 1) }
    }
    function cx(c) { return px + Math.min(c, cols - 1) * cs }
    function cy(r) { return py + Math.min(r, lines - 1) * cs }

    WlrLayershell.namespace: "quickshell-desktop"
    WlrLayershell.layer: WlrLayer.Bottom
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: Cfg.desktop.show

    MouseArea {
        id: bg
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => {
            if (m.button === Qt.RightButton) return Desktop.back()
            if (!Desktop.editing) return
            const c = desk.cell(m.x, m.y)
            Desktop.select(Desktop.at(c.col, c.row), c.col, c.row)
        }
    }
    Repeater {
        model: Desktop.editing ? desk.cols * desk.lines : 0
        Rectangle {
            required property int index
            x: desk.px + (index % desk.cols + 0.5) * desk.cs - 1.5
            y: desk.py + (Math.floor(index / desk.cols) + 0.5) * desk.cs - 1.5
            width: 3
            height: 3
            radius: 1.5
            color: Theme.fgA(0.35)
        }
    }

    Repeater {
        model: Desktop.icons
        Item {
            id: it
            required property var modelData
            required property int index
            property bool dragged: false
            x: desk.cx(modelData.col)
            y: desk.cy(modelData.row)
            z: ma.drag.active ? 2 : 1
            width: desk.cs
            height: desk.cs

            Icon {
                anchors.centerIn: parent
                size: desk.size
                source: Desktop.iconOf(it.modelData)
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                drag { target: Desktop.editing ? it : null; smoothed: false }
                onPressed: it.dragged = false
                onPositionChanged: if (drag.active) it.dragged = true
                onReleased: if (it.dragged) { const c = desk.cell(it.x + desk.cs / 2, it.y + desk.cs / 2); Desktop.move(it.index, c.col, c.row) }
                onClicked: m => {
                    if (it.dragged) return
                    if (m.button === Qt.RightButton && Desktop.editing) Desktop.back()
                    else if (m.button === Qt.RightButton || Desktop.editing) Desktop.select(it.index, it.modelData.col, it.modelData.row)
                    else Desktop.launch(it.modelData)
                }
            }
        }
    }
}
