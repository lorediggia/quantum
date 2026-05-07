import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property color themeAccent: "#ffffff"
    property color themeFg:     "#ffffff"
    property color themeRawBg:  "#000000"
    property color themeBg:     Qt.rgba(themeRawBg.r, themeRawBg.g, themeRawBg.b, 0.6)

    visible: false

    function show() {
        visible = true
        loadProc.running = true
    }
    function hide()   { visible = false }
    function toggle() { visible ? hide() : show() }

    WlrLayershell.namespace: "wallpicker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    implicitWidth: 740
    implicitHeight: 480
    color: "transparent"

    ListModel { id: wallModel }

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
            if (running) {
                collected = []
                return
            }
            const current = []
            for (let i = 0; i < wallModel.count; i++) current.push(wallModel.get(i).path)

            if (JSON.stringify(current) === JSON.stringify(collected)) return

            wallModel.clear()
            for (const p of collected) wallModel.append({ path: p })
        }
    }

    Process { id: applyProc }

    function applyWall(path) {
        applyProc.command = ["sh", "-c", "awww img '" + path + "' --transition-type outer --transition-fps 144 && \"$HOME/.local/bin/wal-sync.sh\" '" + path + "'"]
        applyProc.running = true
        hide()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.hide()

        Rectangle {
            anchors.fill: parent
            color: root.themeRawBg
            opacity: 0.6
            radius: 15
            antialiasing: true
        }

        Flickable {
            id: flick
            anchors.fill: parent; anchors.margins: 15
            topMargin: 15; bottomMargin: 15
            clip: true; contentHeight: grid.implicitHeight
            flickDeceleration: 2500; pixelAligned: true

            Grid {
                id: grid
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 3; spacing: 15

                Repeater {
                    model: wallModel
                    delegate: Item {
                        width: 220; height: 130
                        scale: thumbMouse.pressed ? 0.96 : (thumbMouse.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Image {
                            id: img
                            anchors.fill: parent
                            source: "file://" + path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize: Qt.size(440, 260)  
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: img; maskSource: Rectangle { width: 220; height: 130; radius: 14 }
                            opacity: img.status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                        }


                        MouseArea {
                            id: thumbMouse
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: applyWall(path)
                        }
                    }
                }
            }
        }
    }
}
