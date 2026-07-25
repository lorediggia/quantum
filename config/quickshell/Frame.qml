import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

PanelWindow {
    id: frame

    component InnerCorner: Canvas {
        property color fill: frame.barColor
        width: frame.hyprRounding; height: width
        onPaint: {
            const ctx = getContext("2d"); ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width, 0)
            ctx.arc(width, height, width, -Math.PI / 2, Math.PI, true)
            ctx.closePath()
            ctx.fillStyle = fill
            ctx.fill()
        }
        Component.onCompleted: requestPaint()
        onFillChanged: requestPaint()
    }

    component BaseFillet: Canvas {
        property real  f:      frame.filletRad
        property real  r:      frame.hyprRounding
        property real  extent: 0
        property color fill:   frame.barColor

        property string mode: "top"

        readonly property bool vertical: mode === "right" || mode === "right-mirror"
        readonly property real along: f + r + 2
        readonly property real deep:  f + 2

        width:  vertical ? deep  : along
        height: vertical ? along : deep

        function shape(ctx, f, r, V) {
            const ccx = f + r, ccy = V - r
            const onArc = V < r + f
            const cx = onArc
                ? f + r - Math.sqrt(Math.max(0, V * (2 * r + 2 * f - V)))
                : 0

            ctx.beginPath()
            ctx.moveTo(cx, 0)

            if (onArc) {

                const ang = Math.atan2(ccy - f, ccx - cx)
                ctx.arc(cx, f, f, -Math.PI / 2, ang, false)
                if (V >= r) {
                    ctx.arc(ccx, ccy, r, ang + Math.PI, Math.PI, false)
                    ctx.lineTo(f, 0)
                } else {
                    const sx = Math.sqrt(Math.max(0, 2 * r * V - V * V))
                    ctx.arc(ccx, ccy, r, ang + Math.PI, Math.atan2(-ccy, -sx), false)
                }
            } else {

                ctx.arc(cx, f, f, -Math.PI / 2, 0, false)
                ctx.lineTo(f, 0)
            }

            ctx.closePath()
        }

        onPaint: {
            const ctx = getContext("2d"); ctx.reset()
            ctx.clearRect(0, 0, width, height)
            if (extent <= 0.05 || f <= 0.05 || r <= 0.05) return

            const W = width, H = height
            ctx.save()

            if (mode === "top-mirror")         { ctx.translate(W, 0); ctx.scale(-1, 1) }
            else if (mode === "bottom")        { ctx.translate(0, H); ctx.scale(1, -1) }
            else if (mode === "bottom-mirror") { ctx.translate(W, H); ctx.scale(-1, -1) }
            else if (mode === "right")         { ctx.translate(W, 0); ctx.rotate(Math.PI / 2) }
            else if (mode === "right-mirror")  { ctx.translate(W, H); ctx.rotate(Math.PI / 2); ctx.scale(-1, 1) }

            ctx.fillStyle = fill
            shape(ctx, f, r, extent)
            ctx.fill()
            ctx.restore()
        }

        onExtentChanged: requestPaint()
        onModeChanged:   requestPaint()
        onWidthChanged:  requestPaint()
        onHeightChanged: requestPaint()
        onFillChanged:   requestPaint()
        Component.onCompleted: requestPaint()
    }

    property color themeFg
    property color themeRawBg
    property color themeAccent
    property color themeSecond
    property color themeWarm
    property color themeFresh

    property var allApps: []
    property var buttonModel
    property var stickerModel
    property string batteryPercent: ""
    property string batteryIcon:    "󰁹"

    signal requestSticker()
    signal requestCmd(var cmdArray)
    signal requestPowerCycle()
    signal requestStickerSave()
    signal requestStickerDestroy(int idx)
    signal requestStickerZBump(int idx)

    signal requestStickerSize(string path, real scale)

    readonly property int topThickness:    34
    readonly property int sideThickness:   10
    readonly property int bottomThickness: 10

    readonly property int hyprRounding: 15
    readonly property int filletRad:    18
    readonly property real panelInset:  30

    readonly property real sidebarVInset: 130

    readonly property real  barAlpha: 1.0
    readonly property color barColor: Qt.rgba(themeRawBg.r, themeRawBg.g, themeRawBg.b, barAlpha)

    readonly property var slideInCurve: [0.2, 0.0, 0.05, 1.0, 1.0, 1.0]

    readonly property var slideOutCurve: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]

    readonly property int slideInMs:   500
    readonly property int slideOutMs:  380

    readonly property int morphMs: 340

    readonly property int fadeInMs:  240
    readonly property int fadeOutMs: 130

    function contentAlpha(p) {
        return Math.max(0, Math.min(1, (p - 0.12) / 0.45))
    }

    property string expandedPanel: ""
    property bool   sidebarOpen:    false
    property bool   wallpickerOpen: false

    function togglePanel(name) {
        expandedPanel = (expandedPanel === name) ? "" : name
        if (expandedPanel !== "") sidebarOpen = false
    }
    function closePanel() { expandedPanel = "" }
    function toggleSidebar() {
        sidebarOpen = !sidebarOpen
        if (sidebarOpen) expandedPanel = ""
    }
    function toggleWallpicker() { wallpickerOpen = !wallpickerOpen }

    property string ramUsage:      "—"
    property string volumeLevel:   "—"
    property string volumeIcon:    "󰕾"
    property string networkIcon:   "󰖪"
    property string bluetoothIcon: "󰂲"
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
    readonly property bool sbHasPlayer: Mpris.players.values.length > 0
    readonly property var  sbPlayer:    sbHasPlayer ? Mpris.players.values[0] : null
    readonly property bool sbIsPlaying: sbHasPlayer && sbPlayer.playbackState === MprisPlaybackState.Playing

    function spawn(args) { cmdProc.command = args; cmdProc.running = true }

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

    WlrLayershell.namespace: "quickshell-frame"
    WlrLayershell.layer:     WlrLayer.Overlay

    WlrLayershell.keyboardFocus:
        expandedPanel === "launcher"
            ? WlrKeyboardFocus.Exclusive
            : (expandedPanel !== "" || sidebarOpen || wallpickerOpen)
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    Shortcut {
        sequence: "Escape"
        enabled: frame.expandedPanel !== "" || frame.sidebarOpen || frame.wallpickerOpen
        onActivated: { frame.closePanel(); frame.sidebarOpen = false; frame.wallpickerOpen = false }
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
            frame.activeAppName = cls === "" ? "" : cls.charAt(0).toUpperCase() + cls.slice(1)
        }
    }
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: activeWinProc.running = true }

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
            if (p[0]) frame.ramUsage = p[0]
            if (p[1]) {
                frame.volumeLevel = p[1] + "%"
                const v = parseInt(p[1])
                frame.volumeIcon = isNaN(v) || v <= 0 ? "󰝟" : v < 33 ? "󰕿" : v < 67 ? "󰖀" : "󰕾"
            }
            if (p[2]) frame.networkIcon = p[2].trim() === "connected" ? "󰖩" : "󰖪"
            if (p[3] !== undefined) frame.bluetoothIcon = p[3].trim() === "yes" ? "󰂯" : "󰂲"
            if (p[4] !== undefined && p[4].trim() !== "" && p[4].indexOf(":") !== -1) {
                const seg = p[4].trim().split(":")
                const cap = parseInt(seg[0])
                const st  = (seg[1] || "").trim()
                if (!isNaN(cap)) {
                    frame.batteryPercent = cap + "%"
                    frame.batteryIcon = frame.batIcon(cap, st === "Charging")
                } else frame.batteryPercent = ""
            } else frame.batteryPercent = ""
        }
    }
    Timer { interval: 4000; running: true; repeat: true; triggeredOnStart: true; onTriggered: statsProc.running = true }

    mask: Region {
        x: 0; y: 0; width: frame.width; height: frame.topThickness
        Region { x: 0; y: 0; width: frame.sideThickness; height: frame.height }
        Region { x: frame.width - frame.sideThickness; y: 0; width: frame.sideThickness; height: frame.height }
        Region { x: 0; y: frame.height - frame.bottomThickness; width: frame.width; height: frame.bottomThickness }
        Region {
            x: sidePanelArea.x - frame.filletRad; y: sidePanelArea.y
            width: sidePanelArea.width + frame.filletRad * 2; height: sidePanelArea.height
        }
        Region {
            x: centerPanelArea.x - frame.filletRad; y: centerPanelArea.y
            width: centerPanelArea.width + frame.filletRad * 2; height: centerPanelArea.height
        }
        Region {
            x: wallpickerArea.x - frame.filletRad; y: wallpickerArea.y
            width: wallpickerArea.width + frame.filletRad * 2; height: wallpickerArea.height
        }
        Region {
            x: sidebarArea.x - frame.filletRad
            y: sidebarArea.y - frame.filletRad
            width:  sidebarArea.width + frame.filletRad
            height: sidebarArea.height + frame.filletRad * 2
        }
    }

    Rectangle {
        x: 0; y: 0; width: frame.width; height: frame.topThickness
        color: frame.barColor
    }
    Rectangle {
        x: 0; y: frame.height - frame.bottomThickness
        width: frame.width; height: frame.bottomThickness
        color: frame.barColor
    }
    Rectangle {
        x: 0; y: frame.topThickness
        width: frame.sideThickness
        height: frame.height - frame.topThickness - frame.bottomThickness
        color: frame.barColor
    }
    Rectangle {
        x: frame.width - frame.sideThickness; y: frame.topThickness
        width: frame.sideThickness
        height: frame.height - frame.topThickness - frame.bottomThickness
        color: frame.barColor
    }

    InnerCorner {
        x: frame.sideThickness; y: frame.topThickness
    }
    InnerCorner {
        x: frame.width - frame.sideThickness - width; y: frame.topThickness
        rotation: 90
    }
    InnerCorner {
        x: frame.width - frame.sideThickness - width
        y: frame.height - frame.bottomThickness - height
        rotation: 180
    }
    InnerCorner {
        x: frame.sideThickness
        y: frame.height - frame.bottomThickness - height
        rotation: 270
    }

    Item {
        id: topBarContent
        x: 0; y: 0
        width: frame.width; height: frame.topThickness

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
                for (let i = 0; i < list.length; i++)
                    if (list[i].active) return Math.min(list[i].id - 1, 9)
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
                y: 0; height: workspacesArea.boxSize; radius: 7
                readonly property real edgeA: motion.fast
                readonly property real edgeB: motion.slow
                x:     Math.min(edgeA, edgeB)
                width: Math.abs(edgeA - edgeB) + workspacesArea.boxSize
                color: Qt.rgba(frame.themeAccent.r, frame.themeAccent.g, frame.themeAccent.b, 0.22)
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
                            color: wsItem.isActive ? frame.themeFg
                                : (wsMouse.containsMouse ? frame.themeAccent
                                : Qt.rgba(frame.themeFg.r, frame.themeFg.g, frame.themeFg.b, 0.6))
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
            text: frame.activeAppName === "" ? "󰋜" : frame.activeAppName
            color: frame.activeAppName === "" ? frame.themeAccent : Qt.rgba(frame.themeFg.r, frame.themeFg.g, frame.themeFg.b, 0.55)
            font { family: "JetBrainsMono Nerd Font"; pixelSize: frame.activeAppName === "" ? 13 : 10; weight: Font.Medium; letterSpacing: 0.4 }
        }

        Row {
            anchors.centerIn: parent
            spacing: 10
            Text {
                id: clockTime
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(new Date(), "hh:mm")
                color: frame.themeFg
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; weight: Font.Medium; letterSpacing: 1.0 }
                Timer {
                    interval: 10000; running: true; repeat: true; triggeredOnStart: true
                    property string last: ""
                    onTriggered: {
                        const t = Qt.formatTime(new Date(), "hh:mm")
                        if (t !== last) { clockTime.text = t; clockDate.text = Qt.formatDate(new Date(), "ddd d MMM").toUpperCase(); last = t }
                    }
                }
            }
            Text {
                id: clockDate
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(new Date(), "ddd d MMM").toUpperCase()
                color: frame.themeFg
                opacity: 0.45
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 9; letterSpacing: 0.8; weight: Font.Medium }
            }
        }

        MediaPill {
            anchors.right: statsRow.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            activePlayer: frame.activePlayer
            hasPlayer:    frame.hasPlayer
            isPlaying:    frame.playerIsPlaying
            themeFg:     frame.themeFg
            themeAccent: frame.themeAccent
            themeSecond: frame.themeSecond
        }

        Row {
            id: statsRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 10
            spacing: 4

            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12; valueSize: 10; hPadding: 12
                icon: "󰍛"; value: frame.ramUsage
                tint: frame.themeAccent; baseFg: frame.themeFg
                onActivated: frame.spawn(["kitty", "btop"])
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12; valueSize: 10; hPadding: 12
                icon: frame.volumeIcon; value: frame.volumeLevel
                tint: frame.themeAccent; baseFg: frame.themeFg
                active: frame.expandedPanel === "audio"
                onActivated: frame.togglePanel("audio")
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12
                icon: frame.networkIcon
                tint: frame.themeAccent; baseFg: frame.themeFg
                active: frame.expandedPanel === "wifi"
                onActivated: frame.togglePanel("wifi")
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12
                icon: frame.bluetoothIcon
                tint: frame.themeAccent; baseFg: frame.themeFg
                active: frame.expandedPanel === "bt"
                onActivated: frame.togglePanel("bt")
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12; valueSize: 10; hPadding: 12
                icon: frame.batteryIcon; value: frame.batteryPercent
                tint: frame.themeAccent; baseFg: frame.themeFg
            }
            PowerPill {
                anchors.verticalCenter: parent.verticalCenter
                size: 26; cornerRad: 8; glyphSize: 12
                themeFg: frame.themeFg; themeAccent: frame.themeAccent; themeSecond: frame.themeSecond
                themeWarm: frame.themeWarm; themeFresh: frame.themeFresh
                onPoweroff: frame.spawn(["systemctl", "poweroff"])
                onReboot:   frame.spawn(["systemctl", "reboot"])
                onSuspend:  frame.spawn(["systemctl", "suspend"])
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12
                icon: "󰏗"
                tint: frame.themeAccent; baseFg: frame.themeFg
                active: frame.expandedPanel === "launcher"
                onActivated: frame.togglePanel("launcher")
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12
                icon: "󱂬"
                tint: frame.themeAccent; baseFg: frame.themeFg
                active: frame.sidebarOpen
                onActivated: frame.toggleSidebar()
            }
            IconButton {
                boxSize: 26; boxRadius: 8; iconSize: 12
                icon: "󰸉"
                tint: frame.themeAccent; baseFg: frame.themeFg
                active: frame.wallpickerOpen
                onActivated: frame.toggleWallpicker()
            }
        }
    }

    Item {
        id: sidePanelArea
        x: frame.width - frame.sideThickness - frame.panelInset - width
        y: frame.topThickness
        clip: true

        readonly property Item currentItem:
            [audioPop, wifiPop, btPop].find(p => p.shouldBeActive)?.item ?? null

        readonly property bool isOpen:
            frame.expandedPanel === "audio" ||
            frame.expandedPanel === "wifi"  ||
            frame.expandedPanel === "bt"

        readonly property real liveW: currentItem ? currentItem.implicitWidth  : 0
        readonly property real liveH: currentItem ? currentItem.implicitHeight : 0
        property real heldW: 0
        property real heldH: 0
        onLiveWChanged: if (liveW > 0) heldW = liveW
        onLiveHChanged: if (liveH > 0) heldH = liveH

        Behavior on heldW {
            enabled: sidePanelArea.p > 0.99
            NumberAnimation {
                duration: frame.morphMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: frame.slideInCurve
            }
        }
        Behavior on heldH {
            enabled: sidePanelArea.p > 0.99
            NumberAnimation {
                duration: frame.morphMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: frame.slideInCurve
            }
        }

        property real p: isOpen ? 1 : 0
        readonly property real alpha: frame.contentAlpha(p)
        Behavior on p {
            NumberAnimation {
                duration: sidePanelArea.isOpen ? frame.slideInMs : frame.slideOutMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: sidePanelArea.isOpen ? frame.slideInCurve : frame.slideOutCurve
            }
        }

        width:  heldW
        height: heldH * p

        Rectangle {
            id: sideCard
            anchors.bottom: parent.bottom
            width:  sidePanelArea.heldW
            height: sidePanelArea.heldH
            color:  frame.barColor
            bottomLeftRadius:  frame.hyprRounding
            bottomRightRadius: frame.hyprRounding

            RevealLoader {
                id: audioPop
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                shouldBeActive: frame.expandedPanel === "audio"
                opacity: shouldBeActive ? sidePanelArea.alpha : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: shouldBeActive ? frame.fadeInMs : frame.fadeOutMs
                        easing.type: Easing.OutCubic
                    }
                }
                sourceComponent: Component {
                    AudioPanelContent {
                        themeFg: frame.themeFg; themeAccent: frame.themeAccent; themeSecond: frame.themeSecond
                        onRequestClose: frame.closePanel()
                    }
                }
            }
            RevealLoader {
                id: wifiPop
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                shouldBeActive: frame.expandedPanel === "wifi"
                opacity: shouldBeActive ? sidePanelArea.alpha : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: shouldBeActive ? frame.fadeInMs : frame.fadeOutMs
                        easing.type: Easing.OutCubic
                    }
                }
                sourceComponent: Component {
                    WifiPanelContent {
                        themeFg: frame.themeFg; themeAccent: frame.themeAccent; themeSecond: frame.themeSecond
                        onRequestClose: frame.closePanel()
                    }
                }
            }
            RevealLoader {
                id: btPop
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                shouldBeActive: frame.expandedPanel === "bt"
                opacity: shouldBeActive ? sidePanelArea.alpha : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: shouldBeActive ? frame.fadeInMs : frame.fadeOutMs
                        easing.type: Easing.OutCubic
                    }
                }
                sourceComponent: Component {
                    BluetoothPanelContent {
                        themeFg: frame.themeFg; themeAccent: frame.themeAccent; themeSecond: frame.themeSecond
                        onRequestClose: frame.closePanel()
                    }
                }
            }
        }
    }

    BaseFillet {
        extent: sidePanelArea.height
        x: sidePanelArea.x - f
        y: frame.topThickness
    }
    BaseFillet {
        extent: sidePanelArea.height
        mode: "top-mirror"
        x: sidePanelArea.x + sidePanelArea.width + f - width
        y: frame.topThickness
    }

    Item {
        id: centerPanelArea
        x: Math.round((frame.width - width) / 2)
        y: frame.topThickness
        clip: true

        readonly property Item currentItem: launcherPop.shouldBeActive ? launcherPop.item : null
        readonly property bool isOpen: currentItem !== null

        readonly property real liveW: currentItem ? currentItem.implicitWidth  : 0
        readonly property real liveH: currentItem ? currentItem.implicitHeight : 0
        property real heldW: 0
        property real heldH: 0
        onLiveWChanged: if (liveW > 0) heldW = liveW
        onLiveHChanged: if (liveH > 0) heldH = liveH

        Behavior on heldW {
            enabled: centerPanelArea.p > 0.99
            NumberAnimation {
                duration: frame.morphMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: frame.slideInCurve
            }
        }
        Behavior on heldH {
            enabled: centerPanelArea.p > 0.99
            NumberAnimation {
                duration: frame.morphMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: frame.slideInCurve
            }
        }

        property real p: isOpen ? 1 : 0
        readonly property real alpha: frame.contentAlpha(p)
        Behavior on p {
            NumberAnimation {
                duration: centerPanelArea.isOpen ? frame.slideInMs : frame.slideOutMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: centerPanelArea.isOpen ? frame.slideInCurve : frame.slideOutCurve
            }
        }

        width:  heldW
        height: heldH * p

        Rectangle {
            anchors.bottom: parent.bottom
            width:  centerPanelArea.heldW
            height: centerPanelArea.heldH
            color:  frame.barColor
            bottomLeftRadius:  frame.hyprRounding
            bottomRightRadius: frame.hyprRounding

            RevealLoader {
                id: launcherPop
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                shouldBeActive: frame.expandedPanel === "launcher"
                opacity: shouldBeActive ? centerPanelArea.alpha : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: shouldBeActive ? frame.fadeInMs : frame.fadeOutMs
                        easing.type: Easing.OutCubic
                    }
                }
                sourceComponent: Component {
                    LauncherContent {
                        allApps: frame.allApps
                        themeFg: frame.themeFg; themeAccent: frame.themeAccent; themeSecond: frame.themeSecond
                        onRequestClose: frame.closePanel()
                    }
                }
            }
        }
    }

    BaseFillet {
        extent: centerPanelArea.height
        x: centerPanelArea.x - f
        y: frame.topThickness
    }
    BaseFillet {
        extent: centerPanelArea.height
        mode: "top-mirror"
        x: centerPanelArea.x + centerPanelArea.width + f - width
        y: frame.topThickness
    }

    Item {
        id: wallpickerArea
        x: Math.round((frame.width - width) / 2)
        y: frame.height - frame.bottomThickness - height
        clip: true

        readonly property Item currentItem: wallPop.shouldBeActive ? wallPop.item : null
        readonly property bool isOpen: currentItem !== null

        readonly property real liveW: currentItem ? currentItem.implicitWidth  : 0
        readonly property real liveH: currentItem ? currentItem.implicitHeight : 0
        property real heldW: 0
        property real heldH: 0
        onLiveWChanged: if (liveW > 0) heldW = liveW
        onLiveHChanged: if (liveH > 0) heldH = liveH

        Behavior on heldW {
            enabled: wallpickerArea.p > 0.99
            NumberAnimation {
                duration: frame.morphMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: frame.slideInCurve
            }
        }
        Behavior on heldH {
            enabled: wallpickerArea.p > 0.99
            NumberAnimation {
                duration: frame.morphMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: frame.slideInCurve
            }
        }

        property real p: isOpen ? 1 : 0
        readonly property real alpha: frame.contentAlpha(p)
        Behavior on p {
            NumberAnimation {
                duration: wallpickerArea.isOpen ? frame.slideInMs : frame.slideOutMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: wallpickerArea.isOpen ? frame.slideInCurve : frame.slideOutCurve
            }
        }

        width:  heldW
        height: heldH * p

        Rectangle {
            anchors.top: parent.top
            width:  wallpickerArea.heldW
            height: wallpickerArea.heldH
            color:  frame.barColor
            topLeftRadius:  frame.hyprRounding
            topRightRadius: frame.hyprRounding

            RevealLoader {
                id: wallPop
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                shouldBeActive: frame.wallpickerOpen
                opacity: shouldBeActive ? wallpickerArea.alpha : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: shouldBeActive ? frame.fadeInMs : frame.fadeOutMs
                        easing.type: Easing.OutCubic
                    }
                }
                sourceComponent: Component {
                    WallpaperGridContent {
                        themeFg: frame.themeFg; themeAccent: frame.themeAccent
                        onRequestClose: frame.wallpickerOpen = false
                    }
                }
            }
        }
    }

    BaseFillet {
        extent: wallpickerArea.height
        mode: "bottom"
        x: wallpickerArea.x - f
        y: frame.height - frame.bottomThickness - height
    }
    BaseFillet {
        extent: wallpickerArea.height
        mode: "bottom-mirror"
        x: wallpickerArea.x + wallpickerArea.width + f - width
        y: frame.height - frame.bottomThickness - height
    }

    Item {
        id: sidebarArea
        x: frame.width - width

        y: frame.topThickness + frame.sidebarVInset
        height: frame.height - frame.topThickness - frame.bottomThickness
                - frame.sidebarVInset * 2
        clip: true

        property real p: frame.sidebarOpen ? 1 : 0
        readonly property real alpha: frame.contentAlpha(p)
        Behavior on p {
            NumberAnimation {
                duration: frame.sidebarOpen ? frame.slideInMs : frame.slideOutMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: frame.sidebarOpen ? frame.slideInCurve : frame.slideOutCurve
            }
        }

        readonly property real fullW: 320
        width: fullW * p

        Rectangle {
            anchors.left: parent.left
            width:  sidebarArea.fullW
            height: parent.height
            color:  frame.barColor
            topLeftRadius:    frame.hyprRounding
            bottomLeftRadius: frame.hyprRounding

            SidebarContent {
                anchors.fill: parent
                opacity: sidebarArea.alpha
                themeAccent: frame.themeAccent
                themeSecond: frame.themeSecond
                themeFg:     frame.themeFg
                themeRawBg:  frame.themeRawBg
                themeFresh:  frame.themeFresh
                themeWarm:   frame.themeWarm
                batteryPercent: frame.batteryPercent
                batteryIcon:    frame.batteryIcon
                buttonModel:  frame.buttonModel
                activePlayer: frame.sbPlayer
                hasPlayer:    frame.sbHasPlayer
                isPlaying:    frame.sbIsPlaying
                onRequestSticker:    frame.requestSticker()
                onRequestCmd: (cmd) => frame.requestCmd(cmd)
                onRequestHide:       frame.sidebarOpen = false
                onRequestPowerCycle: frame.requestPowerCycle()
            }

            Repeater {
                model: frame.stickerModel
                delegate: Sticker {
                    imgSrc:       model.imgSrc
                    posX:         model.posX
                    posY:         model.posY
                    baseRot:      model.baseRot
                    stickerZ:     model.stickerZ
                    stickerScale: model.stickerScale ?? 1.0
                    isNew:        model.isNew
                    modelIndex:   index

                    onRequireSave:                       frame.requestStickerSave()
                    onRequireDestroy:     (idx) =>       frame.requestStickerDestroy(idx)
                    onRequireZUpdate:     (idx) =>       frame.requestStickerZBump(idx)
                    onUpdatePosition:     (idx, x, y) => { frame.stickerModel.setProperty(idx, "posX", x); frame.stickerModel.setProperty(idx, "posY", y) }
                    onUpdateScaleAndSave: (idx, p, s) => {
                        frame.stickerModel.setProperty(idx, "stickerScale", s)
                        frame.requestStickerSize(p, s)
                    }
                    onUpdateRotation:     (idx, r) =>    frame.stickerModel.setProperty(idx, "baseRot", r)
                    onUpdateIsNew:        (idx, v) =>    frame.stickerModel.setProperty(idx, "isNew", v)
                }
            }
        }
    }

    BaseFillet {
        mode: "right"
        extent: Math.max(0, sidebarArea.width - frame.sideThickness)
        x: frame.width - frame.sideThickness - width
        y: sidebarArea.y - f
    }
    BaseFillet {
        mode: "right-mirror"
        extent: Math.max(0, sidebarArea.width - frame.sideThickness)
        x: frame.width - frame.sideThickness - width
        y: sidebarArea.y + sidebarArea.height + f - height
    }
}
