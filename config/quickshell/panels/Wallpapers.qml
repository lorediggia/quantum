import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Widgets
import qs.core
import qs.widgets

Item {
    id: wp
    readonly property int gap: 16
    implicitWidth: 3 * grid.cellWidth + gap
    implicitHeight: 2 * grid.cellHeight + gap

    GridView {
        id: grid
        anchors { fill: parent; margins: wp.gap / 2 }
        clip: true
        cellWidth: 220 + wp.gap
        cellHeight: 130 + wp.gap
        model: FolderListModel {
            folder: "file://" + Util.expand(Cfg.wallDir)
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
            caseSensitive: false
            showDirs: false
        }
        delegate: Tile {
            id: cell
            required property string filePath
            required property url fileUrl
            width: grid.cellWidth
            height: grid.cellHeight
            onClicked: { Util.spawn(["wallpaper", filePath]); Ui.close() }

            ClippingRectangle {
                anchors { fill: parent; margins: wp.gap / 2 }
                radius: 14
                color: Theme.fgA(0.05)
                scale: cell.pressed ? 0.96 : cell.hovered ? 1.04 : 1
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Image { anchors.fill: parent; source: cell.fileUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize: Qt.size(width, height) }
            }
        }
    }
    Hint { anchors.centerIn: parent; text: grid.count ? "" : "󱇑  " + Cfg.wallDir }
}
