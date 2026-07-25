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

    property var allApps: []

    readonly property int barHeight: 34
    readonly property color barColor:
        Qt.rgba(themeRawBg.r, themeRawBg.g, themeRawBg.b, 0.86)

    property string expandedPanel: ""

    function togglePanel(name) {
        if (expandedPanel === name) { expandedPanel = ""; return }
        if (!visible) visible = true
        expandedPanel = name
    }
    function closePanel() { expandedPanel = "" }

    property string batteryPercent: ""
    property string batteryIcon:    "󰁹"

    property string ramUsage:      "—"
    property string volumeLevel:   "—"
    property string volumeIcon:    "󰕾"
    property string networkIcon:   "󰖪"
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
    function hide()   { expandedPanel = ""; visible = false }
    function toggle() { visible ? hide() : show() }

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

    WlrLayershell.namespace: "quickshell-topbar"
    WlrLayershell.layer:     WlrLayer.Top
    WlrLayershell.keyboardFocus: expandedPanel !== ""
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    anchors { top: true; left: true; right: true }
    exclusiveZone: barHeight
    implicitHeight: barHeight + 620  
    visible: true
    color: "transparent"

    mask: Region {
        item: bar
        Region { item: sideSlot }
        Region { item: centerSlot }
    }

    Shortcut {
        sequence: "Escape"
        enabled:  topbarWindow.expandedPanel !== ""
        onActivated: topbarWindow.closePanel()
    }

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
            "net=$(nmcli -t -f STATE general 2>/dev/null | head -1);" +
            "bt=$(timeout 1 bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2; exit}');" +
            "bat=''; for b in /sys/class/power_supply/BAT*; do [ -d \"$b\" ] || continue; bat=\"$(cat $b/capacity 2>/dev/null):$(cat $b/status 2>/dev/null)\"; break; done;" +
            "printf '%s|%s|%s|%s|%s\\n' \"$mem\" \"$vol\" \"$net\" \"$bt\" \"$bat\""
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

    Item {
        id: sideSlot
        anchors.top:   parent.top
        anchors.right: parent.right
        anchors.topMargin: topbarWindow.barHeight
        clip: true

        readonly property Item currentItem:
            [audioPop, wifiPop, btPop].find(p => p.shouldBeActive)?.item ?? null

        implicitWidth:  currentItem ? currentItem.implicitWidth  : 0
        implicitHeight: currentItem ? currentItem.implicitHeight : 0
        width:  implicitWidth
        height: implicitHeight

        Behavior on implicitWidth  { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
        Behavior on implicitHeight { NumberAnimation { duration: 380; easing.type: Easing.OutExpo } }

        Rectangle {
            width: parent.width; height: parent.height + 18
            y: -18
            radius: 18
            color: topbarWindow.barColor
        }

        RevealLoader {
            id: audioPop
            anchors.fill: parent
            shouldBeActive: topbarWindow.expandedPanel === "audio"
            sourceComponent: Component {
                AudioPanelContent {
                    themeFg:     topbarWindow.themeFg
                    themeAccent: topbarWindow.themeAccent
                    themeSecond: topbarWindow.themeSecond
                    onRequestClose: topbarWindow.closePanel()
                }
            }
        }
        RevealLoader {
            id: wifiPop
            anchors.fill: parent
            shouldBeActive: topbarWindow.expandedPanel === "wifi"
            sourceComponent: Component {
                WifiPanelContent {
                    themeFg:     topbarWindow.themeFg
                    themeAccent: topbarWindow.themeAccent
                    themeSecond: topbarWindow.themeSecond
                    onRequestClose: topbarWindow.closePanel()
                }
            }
        }
        RevealLoader {
            id: btPop
            anchors.fill: parent
            shouldBeActive: topbarWindow.expandedPanel === "bt"
            sourceComponent: Component {
                BluetoothPanelContent {
                    themeFg:     topbarWindow.themeFg
                    themeAccent: topbarWindow.themeAccent
                    themeSecond: topbarWindow.themeSecond
                    onRequestClose: topbarWindow.closePanel()
                }
            }
        }
    }

    Item {
        id: centerSlot
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topbarWindow.barHeight
        clip: true

        readonly property Item currentItem: launcherPop.shouldBeActive ? launcherPop.item : null

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
            color: topbarWindow.barColor
        }

        RevealLoader {
            id: launcherPop
            anchors.fill: parent
            shouldBeActive: topbarWindow.expandedPanel === "launcher"
            sourceComponent: Component {
                LauncherContent {
                    allApps:     topbarWindow.allApps
                    themeFg:     topbarWindow.themeFg
                    themeAccent: topbarWindow.themeAccent
                    themeSecond: topbarWindow.themeSecond
                    onRequestClose: topbarWindow.closePanel()
                }
            }
        }
    }


    Rectangle {
        id: bar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: topbarWindow.barHeight
        color: topbarWindow.barColor

        Item {
            id: workspacesArea
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            width: wsRow.implicitWidth
            height: 22

            readonly property int boxSize:    22
            readonly property int boxSpacing: 6
            readonly property int step:       boxSize + boxSpacing

            readonly property int activeIdx: {
                const list = Hyprland.workspaces.values
                for (let i = 0; i < list.length; i++) {
                    if (list[i].active) return Math.min(list[i].id - 1, 9)
                }
                return -1
            }

            readonly property real targetX: activeIdx >= 0 ? activeIdx * step : 0

            QtObject {
                id: motion
                property real fast: workspacesArea.targetX
                property real slow: workspacesArea.targetX
                Behavior on fast { NumberAnimation { duration: 260; easing.type: Easing.OutExpo } }
                Behavior on slow { NumberAnimation { duration: 520; easing.type: Easing.OutExpo } }
            }

            Rectangle {
                id: activeIndicator
                y: 0; height: workspacesArea.boxSize; radius: 7
                readonly property real edgeA: motion.fast
                readonly property real edgeB: motion.slow
                x:     Math.min(edgeA, edgeB)
                width: Math.abs(edgeA - edgeB) + workspacesArea.boxSize
                color: Qt.rgba(topbarWindow.themeAccent.r, topbarWindow.themeAccent.g, topbarWindow.themeAccent.b, 0.22)
                opacity: workspacesArea.activeIdx >= 0 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 220 } }
                Behavior on color   { ColorAnimation  { duration: 320 } }
            }

            Row {
                id: wsRow
                spacing: workspacesArea.boxSpacing
                Repeater {
                    model: 10
                    delegate: Item {
                        id: wsItem
                        width: workspacesArea.boxSize; height: workspacesArea.boxSize
                        readonly property var wsObj: Hyprland.workspaces.values.find(w => w.id === index + 1) || null
                        readonly property bool isActive: wsObj !== null && wsObj.active
                        readonly property bool isEmpty:  wsObj === null
                        opacity: isEmpty ? 0.30 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Text {
                            anchors.centerIn: parent
                            text: String(index + 1)
                            color: wsItem.isActive ? topbarWindow.themeFg
                                : (wsMouse.containsMouse ? topbarWindow.themeAccent
                                : Qt.rgba(topbarWindow.themeFg.r, topbarWindow.themeFg.g, topbarWindow.themeFg.b, 0.6))
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 10; weight: wsItem.isActive ? Font.Bold : Font.Medium }
                            scale: wsMouse.pressed ? 0.82 : (wsItem.isActive ? 1.1 : 1.0)
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

    
        Text {
            anchors.left: workspacesArea.right
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: topbarWindow.activeAppName === "" ? "󰋜" : topbarWindow.activeAppName
            color: topbarWindow.activeAppName === ""
                ? topbarWindow.themeAccent
                : Qt.rgba(topbarWindow.themeFg.r, topbarWindow.themeFg.g, topbarWindow.themeFg.b, 0.55)
            font { family: "JetBrainsMono Nerd Font"; pixelSize: topbarWindow.activeAppName === "" ? 13 : 10; weight: Font.Medium; letterSpacing: 0.4 }
        }

        Row {
            anchors.centerIn: parent
            spacing: 10
            Text {
                id: clockTime
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(new Date(), "hh:mm")
                color: topbarWindow.themeFg
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; weight: Font.Medium; letterSpacing: 1.0 }
                Timer {
                    interval: 10000; running: topbarWindow.visible; repeat: true; triggeredOnStart: true
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
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(new Date(), "ddd d MMM").toUpperCase()
                color: topbarWindow.themeFg
                opacity: 0.45
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 9; letterSpacing: 0.8; weight: Font.Medium }
            }
        }

        MediaPill {
            anchors.right: statsRow.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            activePlayer: topbarWindow.activePlayer
            hasPlayer:    topbarWindow.hasPlayer
            isPlaying:    topbarWindow.playerIsPlaying
            themeFg:     topbarWindow.themeFg
            themeAccent: topbarWindow.themeAccent
            themeSecond: topbarWindow.themeSecond
        }

        Row {
            id: statsRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 10
            spacing: 4

            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12; valueSize: 10; hPadding: 12
                icon: "󰍛"; value: topbarWindow.ramUsage
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
                onActivated: topbarWindow.spawn(["kitty", "btop"])
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12; valueSize: 10; hPadding: 12
                icon: topbarWindow.volumeIcon; value: topbarWindow.volumeLevel
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
                active: topbarWindow.expandedPanel === "audio"
                onActivated: topbarWindow.togglePanel("audio")
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12
                icon: topbarWindow.networkIcon
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
                active: topbarWindow.expandedPanel === "wifi"
                onActivated: topbarWindow.togglePanel("wifi")
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12
                icon: topbarWindow.bluetoothIcon
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
                active: topbarWindow.expandedPanel === "bt"
                onActivated: topbarWindow.togglePanel("bt")
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12; valueSize: 10; hPadding: 12
                icon: topbarWindow.batteryIcon; value: topbarWindow.batteryPercent
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
            }
            PowerPill {
                anchors.verticalCenter: parent.verticalCenter
                size: 26; cornerRad: 8; glyphSize: 12
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
                boxSize: 26; boxRadius: 8; iconSize: 12
                icon: "󰏗"
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
                active: topbarWindow.expandedPanel === "launcher"
                onActivated: topbarWindow.togglePanel("launcher")
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12
                icon: "󱂬"
                tint: topbarWindow.themeAccent; baseFg: topbarWindow.themeFg
                onActivated: topbarWindow.spawn(["sidebar"])
            }
        }
    }
}
