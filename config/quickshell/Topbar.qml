import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

PanelWindow {
    id: topbarWindow

    property color themeFg
    property color themeBg
    property color themeRawBg
    property color themeAccent
    property color themeSecond
    property color themeWarm
    property color themeFresh

    property string batteryPercent: ""
    property string batteryIcon:    "󰁹"

    property string ramUsage:     "—"
    property string volumeLevel:  "—"
    property string volumeIcon:   "󰕾"
    property string networkIcon:  "󰖪"
    property string bluetoothIcon: "󰂲"
    property bool   bluetoothOn:   false
    property string activeAppName: ""

    readonly property var mprisList:
        (typeof Mpris !== "undefined" && Mpris.players) ? Mpris.players.values : []

    readonly property var activePlayer: {
        const l = mprisList
        if (!l || l.length === 0) return null
        for (const p of l) if (p.isPlaying) return p
        for (const p of l) if ((("" + (p.identity || "")).toLowerCase()).indexOf("spotify") !== -1) return p
        return l[0]
    }

    readonly property bool hasPlayer:       activePlayer !== null && activePlayer !== undefined
    readonly property bool playerIsPlaying: hasPlayer && activePlayer.isPlaying

    function show()   { visible = true }
    function hide()   { visible = false }
    function toggle() { visible = !visible }

    function spawn(args) {
        cmdProc.command = args
        cmdProc.running = true
    }

    function batIcon(cap, charging) {
        if (charging) return "󰂄"
        if (cap >= 95) return "󰁹"
        if (cap >= 85) return "󰂂"
        if (cap >= 75) return "󰂁"
        if (cap >= 65) return "󰂀"
        if (cap >= 55) return "󰁿"
        if (cap >= 45) return "󰁾"
        if (cap >= 35) return "󰁽"
        if (cap >= 25) return "󰁼"
        if (cap >= 15) return "󰁻"
        if (cap >= 5)  return "󰁺"
        return "󰂎"
    }

    WlrLayershell.namespace:     "quickshell-topbar"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; left: true; right: true }
    margins { top: 14; left: 14; right: 14 }
    implicitHeight: 50
    visible: false
    color: "transparent"

    Process { id: cmdProc; running: false }

    Process {
        id: activeWinProc
        command: ["sh", "-c", "hyprctl activewindow -j | tr -d '\\n'"]
        property string buf: ""
        stdout: SplitParser { onRead: (d) => activeWinProc.buf += d }
        onExited: {
            const raw = activeWinProc.buf
            activeWinProc.buf = ""
            const m = raw.match(/"class"\s*:\s*"([^"]*)"/)
            const cls = m ? m[1].trim() : ""
            topbarWindow.activeAppName = cls === ""
                ? "" : cls.charAt(0).toUpperCase() + cls.slice(1)
        }
    }

    Timer {
        interval: 1000
        running: topbarWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: activeWinProc.running = true
    }

    Process {
        id: statsProc
        command: ["sh", "-c",
            "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2; printf \"%.1fG\", (t-a)/1048576}' /proc/meminfo);" +
            "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}');" +
            "net=$(nmcli -t -f STATE general 2>/dev/null);" +
            "bt=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}');" +
            "bat=''; for b in /sys/class/power_supply/BAT*; do if [ -d \"$b\" ]; then bat=\"$(cat $b/capacity 2>/dev/null):$(cat $b/status 2>/dev/null)\"; break; fi; done;" +
            "echo \"$mem|$vol|$net|$bt|$bat\""
        ]
        property string buffer: ""
        stdout: SplitParser { onRead: (d) => statsProc.buffer += d }
        onExited: {
            const p = statsProc.buffer.trim().split("|")
            statsProc.buffer = ""
            if (p.length < 1) return

            if (p[0]) topbarWindow.ramUsage = p[0]
            if (p[1]) {
                topbarWindow.volumeLevel = p[1] + "%"
                const v = parseInt(p[1])
                topbarWindow.volumeIcon =
                    isNaN(v) || v <= 0 ? "󰝟" :
                    v < 33 ? "󰕿" :
                    v < 67 ? "󰖀" : "󰕾"
            }
            if (p[2]) topbarWindow.networkIcon = p[2].trim() === "connected" ? "󰖩" : "󰖪"
            if (p[3] !== undefined) {
                topbarWindow.bluetoothOn   = p[3].trim() === "yes"
                topbarWindow.bluetoothIcon = topbarWindow.bluetoothOn ? "󰂯" : "󰂲"
            }
            if (p[4] !== undefined && p[4].trim() !== "" && p[4].indexOf(":") !== -1) {
                const seg = p[4].trim().split(":")
                const cap = parseInt(seg[0])
                const st  = (seg[1] || "").trim()
                if (!isNaN(cap)) {
                    topbarWindow.batteryPercent = cap + "%"
                    topbarWindow.batteryIcon = topbarWindow.batIcon(cap, st === "Charging")
                } else {
                    topbarWindow.batteryPercent = ""
                }
            } else {
                topbarWindow.batteryPercent = ""
            }
        }
    }
    Timer {
        interval: 4000
        running: topbarWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    Rectangle {
        anchors.fill: parent
        radius: 15
        color: topbarWindow.themeBg
        clip: true

        // workspaces left
        Item {
            id: workspacesArea
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            width: wsRow.implicitWidth
            height: 28

            readonly property int boxSize:    28
            readonly property int boxSpacing: 8
            readonly property int step:       boxSize + boxSpacing

            readonly property int activeIdx: {
                const list = Hyprland.workspaces.values
                for (let i = 0; i < list.length; i++)
                    if (list[i].active) return list[i].id - 1
                return -1
            }

            readonly property real targetX: activeIdx >= 0 ? activeIdx * step : 0

            QtObject {
                id: motion
                property real fast: workspacesArea.targetX
                property real slow: workspacesArea.targetX
                Behavior on fast { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
                Behavior on slow { NumberAnimation { duration: 540; easing.type: Easing.OutExpo } }
            }

            Rectangle {
                x: activeIndicator.x - 4
                y: activeIndicator.y - 4
                width:  activeIndicator.width + 8
                height: activeIndicator.height + 8
                radius: activeIndicator.radius + 4
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(topbarWindow.themeAccent.r,
                                      topbarWindow.themeAccent.g,
                                      topbarWindow.themeAccent.b, 0.14)
                opacity: activeIndicator.opacity * 0.85
            }

            Rectangle {
                id: activeIndicator
                y: 0
                height: workspacesArea.boxSize
                radius: 9

                readonly property real edgeA: motion.fast
                readonly property real edgeB: motion.slow

                x:     Math.min(edgeA, edgeB)
                width: Math.abs(edgeA - edgeB) + workspacesArea.boxSize

                color: Qt.rgba(topbarWindow.themeAccent.r,
                               topbarWindow.themeAccent.g,
                               topbarWindow.themeAccent.b, 0.22)
                border.width: 1
                border.color: Qt.rgba(topbarWindow.themeAccent.r,
                                      topbarWindow.themeAccent.g,
                                      topbarWindow.themeAccent.b, 0.50)

                opacity: workspacesArea.activeIdx >= 0 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 220 } }
                Behavior on color   { ColorAnimation  { duration: 320 } }
            }

            // nums
            Row {
                id: wsRow
                spacing: workspacesArea.boxSpacing

                Repeater {
                    model: 10
                    delegate: Item {
                        id: wsItem
                        width:  workspacesArea.boxSize
                        height: workspacesArea.boxSize

                        readonly property var wsObj: Hyprland.workspaces.values
                            .find(w => w.id === index + 1) || null
                        readonly property bool isActive: wsObj !== null && wsObj.active
                        readonly property bool isEmpty:  wsObj === null

                        opacity: isEmpty ? 0.35 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                        Text {
                            anchors.centerIn: parent
                            text: String(index + 1)
                            color: wsItem.isActive
                                ? topbarWindow.themeFg
                                : (wsMouse.containsMouse
                                    ? topbarWindow.themeAccent
                                    : Qt.rgba(topbarWindow.themeFg.r,
                                              topbarWindow.themeFg.g,
                                              topbarWindow.themeFg.b, 0.65))
                            font {
                                family:    "JetBrainsMono Nerd Font"
                                pixelSize: 11
                                weight:    wsItem.isActive ? Font.Bold : Font.Medium
                            }
                            scale: wsMouse.pressed
                                ? 0.82
                                : (wsItem.isActive ? 1.10 : 1.0)

                            Behavior on color { ColorAnimation  { duration: 240 } }
                            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                        }

                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${index + 1} })`)
                        }
                    }
                }
            }
        }

        Rectangle {
            id: activeWinPill
            anchors.left: workspacesArea.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            height: 36
            radius: 11
            width: winRow.width + 24

            color: Qt.rgba(1, 1, 1, 0.015)

            Row {
                id: winRow
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: topbarWindow.activeAppName === "" ? "󰋜" : topbarWindow.activeAppName
                    color: topbarWindow.activeAppName === "" ? topbarWindow.themeAccent : topbarWindow.themeFg
                    font {
                        family: "JetBrainsMono Nerd Font"
                        pixelSize: topbarWindow.activeAppName === "" ? 15 : 11
                        weight: Font.Medium
                        letterSpacing: 0.3
                    }
                }
            }
        }

        // clock
        ColumnLayout {
            id: clockArea
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: -3

            Text {
                id: clockTime
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(new Date(), "hh:mm")
                color: topbarWindow.themeFg
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 19; weight: Font.Light; letterSpacing: 1.2 }
                Timer {
                    interval: 10000
                    running: topbarWindow.visible
                    repeat: true
                    triggeredOnStart: true
                    property string last: ""
                    onTriggered: {
                        const t = Qt.formatTime(new Date(), "hh:mm")
                        if (t !== last) {
                            clockTime.text = t
                            clockDate.text = Qt.formatDate(new Date(), "ddd d MMM").toUpperCase()
                            last = t
                        }
                    }
                }
            }
            Text {
                id: clockDate
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(new Date(), "ddd d MMM").toUpperCase()
                color: topbarWindow.themeFg
                opacity: 0.6
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 8; letterSpacing: 0.8; weight: Font.Medium }
            }
        }

        // media player 
        MediaPill {
            id: mediaPill
            anchors.right: statsRow.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 38
            activePlayer: topbarWindow.activePlayer
            hasPlayer:    topbarWindow.hasPlayer
            isPlaying:    topbarWindow.playerIsPlaying

            themeFg:     topbarWindow.themeFg
            themeAccent: topbarWindow.themeAccent
            themeSecond: topbarWindow.themeSecond
        }

        // stats
        Row {
            id: statsRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 12
            spacing: 10

            IconButton {
                boxSize: 36; boxRadius: 11; iconSize: 15
                icon: "󰍛"; value: topbarWindow.ramUsage
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
            }
            IconButton {
                boxSize: 36; boxRadius: 11; iconSize: 15
                icon: topbarWindow.volumeIcon; value: topbarWindow.volumeLevel
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
                onActivated: topbarWindow.spawn(["pavucontrol"])
            }
            IconButton {
                boxSize: 36; boxRadius: 11; iconSize: 15
                icon: topbarWindow.networkIcon
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
                onActivated: topbarWindow.spawn(["kitty", "nmtui"])
            }
            IconButton {
                boxSize: 36; boxRadius: 11; iconSize: 15
                icon: topbarWindow.bluetoothIcon
                tint: topbarWindow.themeAccent
                baseFg: topbarWindow.themeFg
                onActivated: topbarWindow.spawn(["blueman-manager"])
            }
            IconButton {
                boxSize: 36; boxRadius: 11; iconSize: 15
                icon: topbarWindow.batteryIcon
                value: topbarWindow.batteryPercent
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
            }
            PowerPill {
                themeFg:     topbarWindow.themeFg
                themeAccent: topbarWindow.themeAccent
                themeSecond: topbarWindow.themeSecond
                themeWarm:   topbarWindow.themeWarm
                themeFresh:  topbarWindow.themeFresh
                onPoweroff: topbarWindow.spawn(["systemctl", "poweroff"])
                onReboot:   topbarWindow.spawn(["systemctl", "reboot"])
                onSuspend:  topbarWindow.spawn(["systemctl", "suspend"])
            }
            IconButton {
                boxSize: 36; boxRadius: 11; iconSize: 15
                icon: "󱂬"
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
                onActivated: topbarWindow.spawn(["sidebar"])
            }
        }
    }
}