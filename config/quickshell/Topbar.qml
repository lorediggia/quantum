import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

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

    function show()   { visible = true }
    function hide()   { visible = false }
    function toggle() { visible = !visible }

    function hyprDispatch(dispatcher, arg) {
        hyprProc.command = arg !== undefined
            ? ["hyprctl", "dispatch", dispatcher, arg]
            : ["hyprctl", "dispatch", dispatcher]
        hyprProc.running = true
    }

    function spawn(args) {
        cmdProc.command = args
        cmdProc.running = true
    }

    WlrLayershell.namespace:     "quickshell-topbar"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; left: true; right: true }
    margins { top: 10; left: 10; right: 10 }
    implicitHeight: 50
    visible: false
    color: "transparent"

    Process { id: hyprProc; running: false }
    Process { id: cmdProc;  running: false }

    Process {
        id: statsProc
        command: ["sh", "-c",
            "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2; printf \"%.1fG\", (t-a)/1048576}' /proc/meminfo);" +
            "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}');" +
            "net=$(nmcli -t -f STATE general 2>/dev/null);" +
            "bt=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}');" +
            "echo \"$mem|$vol|$net|$bt\""
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
                            onClicked: Hyprland.dispatch('hl.dsp.focus({ workspace = ' + (index + 1) + ' })')
                        }
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
                color: topbarWindow.themeAccent
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
                color: topbarWindow.themeSecond
                opacity: 0.6
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 8; letterSpacing: 0.8; weight: Font.Medium }
            }
        }

        // stats
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 12
            spacing: 10

            IconButton {
                boxSize: 36; boxRadius: 11; iconSize: 15
                icon: "󰍛"; value: topbarWindow.ramUsage
                tint: topbarWindow.themeFresh; baseFg: topbarWindow.themeFg
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
                tint: topbarWindow.themeSecond; baseFg: topbarWindow.themeFg
                onActivated: topbarWindow.spawn(["kitty", "nmtui"])
            }
            IconButton {
                boxSize: 36; boxRadius: 11; iconSize: 15
                icon: topbarWindow.bluetoothIcon
                tint: topbarWindow.bluetoothOn ? topbarWindow.themeAccent : topbarWindow.themeSecond
                baseFg: topbarWindow.themeFg
                onActivated: topbarWindow.spawn(["blueman-manager"])
            }
            IconButton {
                boxSize: 36; boxRadius: 11; iconSize: 15
                icon: topbarWindow.batteryIcon
                value: topbarWindow.batteryPercent === "AC" ? "" : topbarWindow.batteryPercent
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
                visible: topbarWindow.batteryPercent !== ""
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
