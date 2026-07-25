import QtQuick
import Quickshell.Io
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property color themeAccent: "#ffffff"
    property color themeFg:     "#ffffff"

    signal requestClose()

    readonly property int pad:      16   
    readonly property int cols:     3
    readonly property int rows:     2   
    readonly property int gap:      15
    readonly property int thumbW:   220
    readonly property int thumbH:   130

    implicitWidth:  pad * 2 + cols * thumbW + (cols - 1) * gap
    implicitHeight: pad * 2 + rows * thumbH + (rows - 1) * gap

    ListModel { id: wallModel }

    function open() { loadProc.running = true }

    Process {
        id: loadProc
        command: ["sh", "-c", "find ~/Pictures/Wallpaper* -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        property var collected: []
        stdout: SplitParser {
            onRead: (data) => {
                const t = data.trim()
                if (t !== "") loadProc.collected.push(t)
            }
        }
        onRunningChanged: {
            if (running) { collected = []; return }
            const current = []
            for (let i = 0; i < wallModel.count; i++) current.push(wallModel.get(i).path)
            if (JSON.stringify(current) === JSON.stringify(collected)) return
            wallModel.clear()
            for (const p of collected) wallModel.append({ path: p })
        }
    }

    Process { id: applyProc }

    function applyWall(path) {
        applyProc.command = [
            "sh", "-c",
            'awww img "$1" --transition-type fade --transition-duration 1.5 && "$HOME/.local/bin/theme-sync" "$1"',
            "_", path
        ]
        applyProc.running = true
        requestClose()
    }

    Rectangle {
        id: scrollMask
        anchors.fill: parent
        radius: 18
        visible: false
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: root.pad
        clip: true

        contentWidth:  grid.implicitWidth
        contentHeight: grid.implicitHeight
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragAndOvershootBounds
        flickDeceleration: 2500
        pixelAligned: true

        layer.enabled: true
        layer.effect: OpacityMask { maskSource: scrollMask }

        Grid {
            id: grid
            columns: root.cols
            spacing: root.gap

            Repeater {
                model: wallModel

                Item {
                    id: wrapper
                    width:  root.thumbW
                    height: root.thumbH

                    scale: thumbMouse.pressed ? 0.96 : (thumbMouse.containsMouse ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Image {
                        id: wallImg
                        anchors.fill: parent
                        source: "file://" + path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize: Qt.size(root.thumbW * 2, root.thumbH * 2)
                        visible: false
                    }

                    Rectangle {
                        id: wallMask
                        anchors.fill: parent
                        radius: 14
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: wallImg
                        maskSource: wallMask
                    }

                    MouseArea {
                        id: thumbMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: applyWall(path)
                    }
                }
            }
        }
    }
}
