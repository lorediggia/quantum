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

    property string cpuUsage: "—"
    property string ramUsage: "—"
    property string volumeLevel: "—"
    property string networkIcon: "󰖪"
    property string batteryPercent: ""
    property string batteryIcon: "󰁹"
    property string activeTitle: ""

    function show()   { visible = true }
    function hide()   { visible = false }
    function toggle() { visible = !visible }

    WlrLayershell.namespace: "quickshell-topbar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors { top: true; left: true; right: true }
    margins { top: 10; left: 10; right: 10 }
    implicitHeight: 50
    visible: false
    color: "transparent"

    Process {
        id: statsProc
        command: ["sh", "-c",
            "cpu=$(awk 'NR==1{u=$2+$4; t=$2+$3+$4+$5; getline; u2=$2+$4; t2=$2+$3+$4+$5; printf \"%d\", (u2-u)*100/(t2-t)}' <(cat /proc/stat; sleep 0.2; cat /proc/stat));" +
            "mem=$(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2; printf \"%.1fG\", (t-a)/1048576}' /proc/meminfo);" +
            "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}');" +
            "net=$(nmcli -t -f STATE general 2>/dev/null);" +
            "bc=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1);" +
            "bs=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1);" +
            "echo \"$cpu|$mem|$vol|$net|$bc|$bs\""
        ]
        property string buffer: ""
        stdout: SplitParser { onRead: (data) => statsProc.buffer += data }
        onExited: {
            const p = statsProc.buffer.trim().split("|")
            if (p.length >= 6) {
                topbarWindow.cpuUsage    = p[0] !== "" ? p[0] + "%" : "—"
                topbarWindow.ramUsage    = p[1] !== "" ? p[1]       : "—"
                topbarWindow.volumeLevel = p[2] !== "" ? p[2] + "%" : "—"
                topbarWindow.networkIcon = p[3] === "connected" ? "󰖩" : "󰖪"
                const cap = parseInt(p[4])
                if (!isNaN(cap)) {
                    topbarWindow.batteryPercent = cap + "%"
                    topbarWindow.batteryIcon =
                        p[5] === "Charging" ? "󰂄" :
                        cap > 90 ? "󰁹" : cap > 70 ? "󰂀" :
                        cap > 40 ? "󰁾" : cap > 10 ? "󰁼" : "󰂎"
                }
            }
            statsProc.buffer = ""
        }
    }
    Timer {
        interval: 3000; running: topbarWindow.visible; repeat: true; triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    Process {
        id: titleProc
        command: ["sh", "-c", "hyprctl activewindow -j 2>/dev/null | grep -oP '\"class\"\\s*:\\s*\"\\K[^\"]*' | head -n1"]
        property string buffer: ""
        stdout: SplitParser { onRead: (data) => titleProc.buffer += data }
        onExited: { topbarWindow.activeTitle = titleProc.buffer.trim(); titleProc.buffer = "" }
    }
    Timer {
        interval: 1500; running: topbarWindow.visible; repeat: true; triggeredOnStart: true
        onTriggered: titleProc.running = true
    }

    // shell
    Rectangle {
        anchors.fill: parent
        radius: 15
        color: topbarWindow.themeBg

        // workspaces
        Item {
            id: workspacesArea
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            width: wsRow.implicitWidth
            height: 34

            Row {
                id: wsRow
                spacing: 8
                anchors.top: parent.top

                Repeater {
                    model: 10
                    delegate: WorkspacePill { wsId: index + 1 }
                }
            }

            Rectangle {
                id: wsIndicator
                width: 18; height: 2; radius: 1
                color: topbarWindow.themeAccent
                anchors.bottom: parent.bottom
                opacity: 0.9

                property int activeIdx: {
                    const list = Hyprland.workspaces.values
                    for (let i = 0; i < list.length; i++)
                        if (list[i].active) return list[i].id - 1
                    return 0
                }

                x: activeIdx * 36 + (28 - width) / 2
                Behavior on x { SpringAnimation { spring: 3.5; damping: 0.32; mass: 0.6 } }
            }
        }

        // right group
        Row {
            id: rightGroup
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 12
            spacing: 6

            StatPill { icon: "󰻠"; value: topbarWindow.cpuUsage;    tint: topbarWindow.themeWarm }
            StatPill { icon: "󰍛"; value: topbarWindow.ramUsage;    tint: topbarWindow.themeFresh }
            StatPill { icon: "󰕾"; value: topbarWindow.volumeLevel; tint: topbarWindow.themeAccent
                        onActivated: Hyprland.dispatch('hl.dsp.exec_cmd("pavucontrol")') }
            StatPill { icon: topbarWindow.networkIcon; value: ""; tint: topbarWindow.themeSecond
                       onActivated: Hyprland.dispatch('hl.dsp.exec_cmd("kitty nmtui")') }
            StatPill { icon: topbarWindow.batteryIcon; value: topbarWindow.batteryPercent
                       tint: topbarWindow.themeAccent }
            StatPill { icon: "󱂬"; value: ""; tint: topbarWindow.themeAccent
                       onActivated: Hyprland.dispatch('hl.dsp.exec_cmd("quickshell ipc call sidebar toggle")') }
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
                    interval: 10000; running: true; repeat: true; triggeredOnStart: true
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

        // title
        RowLayout {
            anchors.left: workspacesArea.right
            anchors.right: clockArea.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 9

            Rectangle {
                width: 6; height: 6; radius: 3
                color: topbarWindow.themeFresh
                opacity: topbarWindow.activeTitle !== "" ? 1.0 : 0.2
                SequentialAnimation on opacity {
                    running: topbarWindow.activeTitle !== ""
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.45; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0;  duration: 1400; easing.type: Easing.InOutSine }
                }
            }
            Text {
                Layout.fillWidth: true
                text: topbarWindow.activeTitle === ""
                    ? "no active window"
                    : topbarWindow.activeTitle.charAt(0).toUpperCase() + topbarWindow.activeTitle.slice(1)
                color: topbarWindow.activeTitle === ""
                    ? Qt.rgba(topbarWindow.themeFg.r, topbarWindow.themeFg.g, topbarWindow.themeFg.b, 0.4)
                    : topbarWindow.themeFg
                elide: Text.ElideRight
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; weight: Font.Medium; letterSpacing: 0.3 }
                Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.OutCubic } }
            }
        }
    }

    // workspace pill
    component WorkspacePill: Item {
        id: wsRoot
        property int wsId: 1
        property var wsObj: {
            const list = Hyprland.workspaces.values
            for (let i = 0; i < list.length; i++)
                if (list[i].id === wsId) return list[i]
            return null
        }
        readonly property bool isActive:   wsObj !== null && wsObj.active
        readonly property bool isOccupied: wsObj !== null

        width: 28
        height: 28

        Rectangle {
            id: wsBase
            anchors.fill: parent
            radius: 9

            color: wsMouse.pressed
                ? Qt.rgba(1, 1, 1, 0.12)
                : wsMouse.containsMouse
                    ? Qt.rgba(1, 1, 1, 0.08)
                    : Qt.rgba(1, 1, 1, wsRoot.isOccupied ? 0.05 : 0.025)
            Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.OutCubic } }

            border.width: 1
            border.color: wsRoot.isActive
                ? "transparent"
                : wsMouse.containsMouse
                    ? Qt.rgba(topbarWindow.themeAccent.r, topbarWindow.themeAccent.g, topbarWindow.themeAccent.b, 0.55)
                    : Qt.rgba(1, 1, 1, wsRoot.isOccupied ? 0.16 : 0.06)
            Behavior on border.color { ColorAnimation { duration: 320; easing.type: Easing.OutCubic } }

            scale: wsMouse.pressed ? 0.94 : (wsMouse.containsMouse ? 1.06 : 1.0)
            Behavior on scale { SpringAnimation { spring: 3; damping: 0.55; mass: 0.8 } }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: topbarWindow.themeAccent
                opacity: wsRoot.isActive ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutQuart } }
            }

            Text {
                anchors.centerIn: parent
                text: wsRoot.wsId
                color: wsRoot.isActive
                    ? topbarWindow.themeRawBg
                    : wsRoot.isOccupied
                        ? topbarWindow.themeFg
                        : Qt.rgba(topbarWindow.themeFg.r, topbarWindow.themeFg.g, topbarWindow.themeFg.b, 0.32)
                font {
                    family: "JetBrainsMono Nerd Font"
                    pixelSize: wsRoot.isActive ? 12 : 11
                    weight: wsRoot.isActive ? Font.Bold : Font.Medium
                }
                scale: wsMouse.pressed ? 0.9 : (wsMouse.containsMouse ? 1.08 : 1.0)
                Behavior on scale { SpringAnimation { spring: 4; damping: 0.5; mass: 0.7 } }
                Behavior on color { ColorAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            id: wsMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsRoot.wsId + " })")
        }
    }

    component StatPill: Item {
        id: statRoot
        property string icon
        property string value
        property color  tint
        signal activated()

        width: statContent.implicitWidth + 22
        height: 30

        Rectangle {
            anchors.fill: parent
            radius: 10

            color: statMouse.pressed
                ? Qt.rgba(1, 1, 1, 0.12)
                : statMouse.containsMouse
                    ? Qt.rgba(1, 1, 1, 0.08)
                    : Qt.rgba(1, 1, 1, 0.04)
            Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.OutCubic } }

            border.width: 1
            border.color: statMouse.containsMouse
                ? Qt.rgba(statRoot.tint.r, statRoot.tint.g, statRoot.tint.b, 0.55)
                : Qt.rgba(1, 1, 1, 0.08)
            Behavior on border.color { ColorAnimation { duration: 240; easing.type: Easing.OutCubic } }

            scale: statMouse.pressed ? 0.94 : (statMouse.containsMouse ? 1.06 : 1.0)
            Behavior on scale { SpringAnimation { spring: 3; damping: 0.55; mass: 0.8 } }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: statRoot.tint
                opacity: statMouse.containsMouse ? 0.18 : 0.0
                Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                id: statContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: statRoot.icon
                    color: statMouse.containsMouse
                        ? statRoot.tint
                        : Qt.rgba(topbarWindow.themeFg.r, topbarWindow.themeFg.g, topbarWindow.themeFg.b, 0.75)
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                    scale: statMouse.pressed ? 0.9 : (statMouse.containsMouse ? 1.08 : 1.0)
                    Behavior on scale { SpringAnimation { spring: 4; damping: 0.5; mass: 0.7 } }
                    Behavior on color { ColorAnimation { duration: 260; easing.type: Easing.OutCubic } }
                }
                Text {
                    text: statRoot.value
                    visible: statRoot.value !== ""
                    color: topbarWindow.themeFg
                    opacity: 0.85
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; weight: Font.Medium }
                }
            }
        }

        MouseArea {
            id: statMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: statRoot.activated()
        }
    }
}