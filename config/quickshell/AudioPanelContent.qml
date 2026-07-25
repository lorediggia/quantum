import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: audioPanel

    property color themeFg:     "#ffffff"
    property color themeAccent: "#ffffff"
    property color themeSecond: "#ffffff"

    property real   volume:  0.0
    property bool   muted:   false
    property var    sinks:   []   
    property var    sources: []  

    signal requestClose()

    implicitWidth:  320
    implicitHeight: cardContent.implicitHeight + 44

    function open() { refreshProc.running = true }

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

    function setDevice(id) {
        devSetProc.command = ["wpctl", "set-default", id]
        devSetProc.running = true
        Qt.callLater(() => refreshProc.running = true)
    }

    Process {
        id: refreshProc
        command: ["sh", "-c",
            "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); echo \"VOL:$vol\";" +
            "wpctl status 2>/dev/null | awk '" +
            "/^Audio/{a=1;next} /^Video|^Settings/{a=0} " +
            "a && /Sinks:/{s=\"SINK\";next} " +
            "a && /Sources:/{s=\"SOURCE\";next} " +
            "a && /Devices:|Filters:|Streams:/{s=\"\";next} " +
            "a && s!=\"\" && /[0-9]+\\./{l=$0; sub(/^[^*0-9A-Za-z]*/,\"\",l); print s \":\" l}" +
            "'"
        ]
        property string buf: ""
        stdout: SplitParser { onRead: (d) => refreshProc.buf += d + "\n" }
        onExited: {
            const lines = refreshProc.buf.split("\n")
            refreshProc.buf = ""
            const outs = [], ins = []

            for (const line of lines) {
                if (line.startsWith("VOL:")) {
                    const parts = line.replace("VOL:", "").trim().split(" ")
                    audioPanel.volume = parseFloat(parts[1]) || 0
                    audioPanel.muted  = line.includes("[MUTED]")
                    continue
                }

                const isSink   = line.startsWith("SINK:")
                const isSource = line.startsWith("SOURCE:")
                if (!isSink && !isSource) continue

                const raw      = line.replace(isSink ? "SINK:" : "SOURCE:", "").trim()
                const isActive = raw.startsWith("*")
                const clean    = raw.replace(/^\*\s*/, "").trim()
                const idMatch  = clean.match(/^(\d+)\./)
                const id       = idMatch ? idMatch[1] : ""
                const name     = clean.replace(/^\d+\.\s*/, "").replace(/\[vol:.*\]/, "").trim()
                if (!id || !name) continue

                ;(isSink ? outs : ins).push({ id, name, active: isActive })
            }

            audioPanel.sinks   = outs
            audioPanel.sources = ins
        }
    }

    Process { id: volSetProc }
    Process {
        id: muteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onExited: refreshProc.running = true
    }
    Process { id: devSetProc }

    component DeviceRow: Item {
        id: row
        property string devName: ""
        property bool   isActive: false
        signal picked()

        height: 34

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -8; anchors.rightMargin: -8
            radius: 10
            color: row.isActive
                ? Qt.rgba(audioPanel.themeAccent.r, audioPanel.themeAccent.g, audioPanel.themeAccent.b, 0.12)
                : (rowHover.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
            Behavior on color { ColorAnimation { duration: 130 } }
        }
        RowLayout {
            anchors.fill: parent
            spacing: 12
            Rectangle {
                width: 6; height: 6; radius: 3
                color: row.isActive ? audioPanel.themeAccent : "transparent"
                border.width: 1
                border.color: row.isActive
                    ? audioPanel.themeAccent
                    : Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.20)
                Behavior on color        { ColorAnimation { duration: 130 } }
                Behavior on border.color { ColorAnimation { duration: 130 } }
            }
            Text {
                Layout.fillWidth: true
                text: row.devName
                color: row.isActive
                    ? audioPanel.themeFg
                    : Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.42)
                font {
                    family: "JetBrainsMono Nerd Font"; pixelSize: 11
                    weight: row.isActive ? Font.Medium : Font.Normal
                }
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: 130 } }
            }
        }
        HoverHandler { id: rowHover }
        TapHandler  { onTapped: if (!row.isActive) row.picked() }
    }

    component SectionLabel: Text {
        color: Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.30)
        font {
            family: "JetBrainsMono Nerd Font"; pixelSize: 9
            weight: Font.Medium; letterSpacing: 1.0
        }
    }

    ColumnLayout {
        id: cardContent
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 22; topMargin: 20 }
        spacing: 18

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

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: audioPanel.sinks.length > 0

            Rectangle {
                Layout.fillWidth: true; height: 1
                color: Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.06)
            }
            Item { height: 6 }
            SectionLabel { text: "USCITA" }
            Item { height: 2 }

            Repeater {
                model: audioPanel.sinks
                delegate: DeviceRow {
                    Layout.fillWidth: true
                    devName:  modelData.name
                    isActive: modelData.active
                    onPicked: audioPanel.setDevice(modelData.id)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: audioPanel.sources.length > 0

            Rectangle {
                Layout.fillWidth: true; height: 1
                color: Qt.rgba(audioPanel.themeFg.r, audioPanel.themeFg.g, audioPanel.themeFg.b, 0.06)
            }
            Item { height: 6 }
            SectionLabel { text: "INGRESSO" }
            Item { height: 2 }

            Repeater {
                model: audioPanel.sources
                delegate: DeviceRow {
                    Layout.fillWidth: true
                    devName:  modelData.name
                    isActive: modelData.active
                    onPicked: audioPanel.setDevice(modelData.id)
                }
            }
        }

        Item { height: 2 }
    }
}
