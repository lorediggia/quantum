import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

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
    implicitHeight: 450
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
        }

        Rectangle {
            id: scrollMask
            anchors.fill: parent
            radius: 15
            visible: false
        }

        Flickable {
            anchors.fill: parent
            clip: true
            contentHeight: grid.implicitHeight
            flickDeceleration: 2500
            pixelAligned: true

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: scrollMask
            }

            Grid {
                id: grid
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 3
                spacing: 15
                topPadding: 15
                bottomPadding: 15

                Repeater {
                    model: wallModel

                    Item {
                        id: wrapper
                        width: 220
                        height: 130
                        opacity: 0

                        transform: Translate { id: slideTrans; y: 20 }

                        scale: thumbMouse.pressed ? 0.96 : (thumbMouse.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Component.onCompleted: introAnim.start()

                        ParallelAnimation {
                            id: introAnim
                            SequentialAnimation {
                                PauseAnimation { duration: index * 35 }
                                NumberAnimation { target: wrapper; property: "opacity"; to: 1.0; duration: 400; easing.type: Easing.OutCubic }
                            }
                            SequentialAnimation {
                                PauseAnimation { duration: index * 35 }
                                NumberAnimation { target: slideTrans; property: "y"; to: 0; duration: 500; easing.type: Easing.OutCubic }
                            }
                        }

                        Image {
                            id: wallImg
                            anchors.fill: parent
                            source: "file://" + path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: false
                            cache: true
                            sourceSize: Qt.size(440, 260)
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
}