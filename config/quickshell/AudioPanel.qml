import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: audioPanel

    property color themeFg:     "#ffffff"
    property color themeBg:     "#66000000"
    property color themeRawBg:  "#000000"
    property color themeAccent: "#ffffff"
    property color themeSecond: "#ffffff"

    property real   volume: 0.0
    property bool   muted:  false
    property var    sinks:  []

    visible: false
    color:   "transparent"

    signal closed()

    WlrLayershell.namespace:     "quickshell-audio"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    implicitWidth: 320
    implicitHeight: cardContent.implicitHeight + 48

    function show() {
        visible = true
        refreshProc.running = true
    }

    function hide() {
        visible = false
        closed()
    }

    function volIcon() {
        if (muted || volume <= 0) return "󰝟"
        if (volume < 0.33)        return "󰕿"
        if (volume < 0.67)        return "󰖀"
        return "󰕾"
    }

    function setVolume(v) {
        const clamped = Math.max(0.0, Math.min(1.5, v))
        volume = clamped
        volSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", clamped.toFixed(2)]
        volSetProc.running = true
    }

    function toggleMute() {
        muted = !muted
        muteProc.running = true
    }

    function setSink(sinkId) {
        sinkSetProc.command = ["wpctl", "set-default", sinkId]
        sinkSetProc.running = true
        Qt.callLater(() => refreshProc.running = true)
    }

    Process {
        id: refreshProc
        command: ["sh", "-c",
            "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); echo \"VOL:$vol\";" +
            "wpctl status 2>/dev/null | awk '/Audio/,/Video/' | grep -E '^[[:space:]]+\\*?[[:space:]]*[0-9]+\\.' | sed 's/^[[:space:]]*//' | while IFS= read -r line; do echo \"SINK:$line\"; done"
        ]
        property string buf: ""
        stdout: SplitParser { onRead: (d) => refreshProc.buf += d + "\n" }
        onExited: {
            const lines    = refreshProc.buf.split("\n")
            refreshProc.buf = ""
            const newSinks = []
            for (const line of lines) {
                if (line.startsWith("VOL:")) {
                    const parts       = line.replace("VOL:", "").trim().split(" ")
                    audioPanel.volume = parseFloat(parts[1]) || 0
                    audioPanel.muted  = line.includes("[MUTED]")
                } else if (line.startsWith("SINK:")) {
                    const raw      = line.replace("SINK:", "").trim()
                    const isActive = raw.startsWith("*")
                    const clean    = raw.replace(/^\*\s*/, "").trim()
                    const idMatch  = clean.match(/^(\d+)\./)
                    const id       = idMatch ? idMatch[1] : ""
                    const name     = clean.replace(/^\d+\.\s*/, "").replace(/\[vol:.*\]/, "").trim()
                    if (id && name) newSinks.push({ id, name, active: isActive })
                }
            }
            audioPanel.sinks = newSinks
        }
    }

    Process { id: volSetProc }
    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onExited: refreshProc.running = true
    }
    Process { id: sinkSetProc }

    Shortcut {
        sequence: "Escape"
        enabled:  audioPanel.visible
        onActivated: audioPanel.hide()
    }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: 20
            color:  audioPanel.themeBg

            MouseArea { anchors.fill: parent; onClicked: {} }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.08)
            }

            ColumnLayout {
                id: cardContent
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 24; topMargin: 24 }
                spacing: 20

                // header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "󰕾  Audio"
                        color: audioPanel.themeFg
                        opacity: 0.7
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; weight: Font.Medium; letterSpacing: 0.5 }
                    }
                    Item { Layout.fillWidth: true }
                    Item {
                        width: 30; height: 30
                        Rectangle {
                            anchors.fill: parent; radius: 9
                            color: muteHover.containsMouse
                                ? Qt.rgba(audioPanel.themeAccent.r, audioPanel.themeAccent.g, audioPanel.themeAccent.b, 0.20)
                                : Qt.rgba(1, 1, 1, 0.06)
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        Text {
                            anchors.centerIn: parent
                            text:  audioPanel.volIcon()
                            color: audioPanel.muted
                                ? Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.30)
                                : audioPanel.themeAccent
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        HoverHandler { id: muteHover }
                        TapHandler  { onTapped: audioPanel.toggleMute() }
                    }
                }

                // slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        Layout.fillWidth: true
                        height: 32
                        readonly property real pct: Math.min(1.0, audioPanel.volume / 1.5)

                        Rectangle {
                            id: sliderTrack
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: 4; radius: 2
                            color: Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.10)
                            Rectangle {
                                width:  sliderTrack.width * parent.parent.pct
                                height: parent.height; radius: parent.radius
                                color:  audioPanel.muted
                                    ? Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.20)
                                    : audioPanel.themeAccent
                                Behavior on color { ColorAnimation  { duration: 180 } }
                                Behavior on width { NumberAnimation { duration: 55; easing.type: Easing.OutCubic } }
                            }
                        }
                        Rectangle {
                            x: sliderTrack.width * parent.pct - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14; height: 14; radius: 7
                            color: audioPanel.muted
                                ? Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.28)
                                : audioPanel.themeAccent
                            scale: sm.pressed ? 0.80 : (sm.containsMouse ? 1.20 : 1.0)
                            Behavior on x     { NumberAnimation { duration: 55;  easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack  } }
                            Behavior on color { ColorAnimation  { duration: 180 } }
                        }
                        MouseArea {
                            id: sm
                            anchors.fill: parent; anchors.margins: -10
                            hoverEnabled: true; preventStealing: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed:         (m) => audioPanel.setVolume((m.x / width) * 1.5)
                            onPositionChanged: (m) => { if (pressed) audioPanel.setVolume((m.x / width) * 1.5) }
                            onWheel:           (w) => audioPanel.setVolume(audioPanel.volume + (w.angleDelta.y > 0 ? 0.03 : -0.03))
                        }
                    }

                    Text {
                        text: Math.round(audioPanel.volume * 100) + "%"
                        color: Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.45)
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; weight: Font.Medium }
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // sink list
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: audioPanel.sinks.length > 1

                    Rectangle {
                        Layout.fillWidth: true; height: 1
                        color: Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.06)
                    }
                    Item { height: 2 }

                    Repeater {
                        model: audioPanel.sinks.length > 1 ? audioPanel.sinks : []
                        delegate: Item {
                            Layout.fillWidth: true; height: 36
                            readonly property bool isActive: modelData.active
                            Rectangle {
                                anchors.fill: parent; anchors.leftMargin: -8; anchors.rightMargin: -8
                                radius: 10
                                color: isActive
                                    ? Qt.rgba(audioPanel.themeAccent.r, audioPanel.themeAccent.g, audioPanel.themeAccent.b, 0.12)
                                    : (sh.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                                Behavior on color { ColorAnimation { duration: 130 } }
                            }
                            RowLayout {
                                anchors.fill: parent; spacing: 12
                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: isActive ? audioPanel.themeAccent : "transparent"
                                    border.width: 1
                                    border.color: isActive ? audioPanel.themeAccent : Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.20)
                                    Behavior on color        { ColorAnimation { duration: 130 } }
                                    Behavior on border.color { ColorAnimation { duration: 130 } }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: isActive ? audioPanel.themeFg : Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.42)
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; weight: isActive ? Font.Medium : Font.Normal }
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                }
                            }
                            HoverHandler { id: sh }
                            TapHandler  { onTapped: if (!isActive) audioPanel.setSink(modelData.id) }
                        }
                    }
                }
            }
        }
    }
}