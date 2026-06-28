import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: btPanel

    property color themeFg:     "#ffffff"
    property color themeBg:     "#66000000"
    property color themeRawBg:  "#000000"
    property color themeAccent: "#ffffff"
    property color themeSecond: "#ffffff"

    property var    devices:      []
    property bool   scanning:     false
    property bool   btEnabled:    false
    property bool   noController: false
    property string connectingTo: ""
    property string errorMsg:     ""

    visible: false
    color:   "transparent"

    signal closed()

    WlrLayershell.namespace:     "quickshell-bluetooth"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    implicitWidth: 340
    implicitHeight: Math.min(cardContent.implicitHeight + 48, 480)

    function show() {
        visible  = true
        errorMsg = ""
        refreshStatus()
    }

    function hide() {
        visible = false
        closed()
    }

    function refreshStatus() { statusProc.running = true }

    function toggleBluetooth() {
        const cmd = btEnabled
            ? "bluetoothctl power off 2>/dev/null"
            : "rfkill unblock bluetooth 2>/dev/null; bluetoothctl power on 2>/dev/null; sleep 1"
        toggleProc.command = ["sh", "-c", cmd]
        toggleProc.running = true
    }

    function scan() {
        if (!btEnabled) return
        scanning = true
        scanProc.running = true
    }

    function connect(mac) {
        connectingTo = mac; errorMsg = ""
        connectProc.command = ["sh", "-c", "bluetoothctl connect " + mac + " 2>&1 | tail -1"]
        connectProc.running = true
    }

    function disconnect(mac) {
        connectingTo = mac
        disconnectProc.command = ["sh", "-c", "bluetoothctl disconnect " + mac + " 2>/dev/null"]
        disconnectProc.running = true
    }

    function remove(mac) {
        removeProc.command = ["sh", "-c", "bluetoothctl remove " + mac + " 2>/dev/null"]
        removeProc.running = true
    }

    function btIcon(type) {
        const t = (type || "").toLowerCase()
        if (t.includes("audio") || t.includes("headphone") || t.includes("headset")) return "󰋋"
        if (t.includes("keyboard")) return "󰌌"
        if (t.includes("mouse"))    return "󰍽"
        if (t.includes("phone"))    return "󰏲"
        if (t.includes("computer")) return "󰟀"
        if (t.includes("speaker"))  return "󰓃"
        if (t.includes("gamepad") || t.includes("joystick")) return "󰖺"
        return "󰂯"
    }

    Process {
        id: statusProc
        command: ["sh", "-c",
            "show=$(timeout 1 bluetoothctl show 2>/dev/null);" +
            "if [ -z \"$show\" ]; then echo 'NOCTRL'; exit 0; fi;" +
            "powered=$(echo \"$show\" | awk '/Powered:/{print $2; exit}');" +
            "echo \"POWERED:$powered\";" +
            "timeout 2 bluetoothctl devices 2>/dev/null | while read -r _ mac name; do" +
            "  info=$(timeout 1 bluetoothctl info $mac 2>/dev/null);" +
            "  connected=$(echo \"$info\" | awk '/Connected:/{print $2}');" +
            "  paired=$(echo \"$info\" | awk '/Paired:/{print $2}');" +
            "  type=$(echo \"$info\" | awk '/Icon:/{print $2}');" +
            "  [ \"$paired\" = 'yes' ] && echo \"DEV:$mac|$name|$connected|$type\";" +
            "done"
        ]
        property string buf: ""
        stdout: SplitParser { onRead: (d) => statusProc.buf += d + "\n" }
        onExited: {
            const lines = statusProc.buf.split("\n")
            statusProc.buf = ""
            const devs = []
            let noCtrl = false
            for (const line of lines) {
                if (line.trim() === "NOCTRL") { noCtrl = true; continue }
                if (line.startsWith("POWERED:"))
                    btPanel.btEnabled = line.replace("POWERED:", "").trim() === "yes"
                else if (line.startsWith("DEV:")) {
                    const parts = line.replace("DEV:", "").split("|")
                    if (parts.length < 3) continue
                    const mac = parts[0].trim(); const name = parts[1].trim()
                    const connected = parts[2].trim() === "yes"; const type = (parts[3] || "").trim()
                    if (mac && name) devs.push({ mac, name, connected, type })
                }
            }
            btPanel.noController = noCtrl
            if (noCtrl) btPanel.btEnabled = false
            btPanel.devices = devs; btPanel.connectingTo = ""
        }
    }

    Process {
        id: scanProc
        command: ["sh", "-c",
            "bluetoothctl --timeout 8 scan on >/dev/null 2>&1;" +
            "bluetoothctl devices 2>/dev/null | while read -r _ mac name; do" +
            "  info=$(timeout 1 bluetoothctl info $mac 2>/dev/null);" +
            "  connected=$(echo \"$info\" | awk '/Connected:/{print $2}');" +
            "  type=$(echo \"$info\" | awk '/Icon:/{print $2}');" +
            "  echo \"DEV:$mac|$name|$connected|$type\";" +
            "done"
        ]
        property string buf: ""
        stdout: SplitParser { onRead: (d) => scanProc.buf += d + "\n" }
        onExited: {
            const lines = scanProc.buf.split("\n"); scanProc.buf = ""; btPanel.scanning = false
            const devs = []
            for (const line of lines) {
                if (!line.startsWith("DEV:")) continue
                const parts = line.replace("DEV:", "").split("|")
                if (parts.length < 3) continue
                const mac = parts[0].trim(); const name = parts[1].trim()
                const connected = parts[2].trim() === "yes"; const type = (parts[3] || "").trim()
                if (mac && name) devs.push({ mac, name, connected, type })
            }
            btPanel.devices = devs
        }
    }

    Process { id: toggleProc; onExited: Qt.callLater(() => statusProc.running = true) }
    Process {
        id: connectProc; property string buf: ""
        stdout: SplitParser { onRead: (d) => connectProc.buf += d }
        onExited: (code) => {
            const out = connectProc.buf.trim(); connectProc.buf = ""
            if (code !== 0 || out.toLowerCase().includes("fail")) btPanel.errorMsg = out || "Connessione fallita"
            statusProc.running = true
        }
    }
    Process { id: disconnectProc; onExited: statusProc.running = true }
    Process { id: removeProc;     onExited: statusProc.running = true }

    Shortcut {
        sequence: "Escape"
        enabled:  btPanel.visible
        onActivated: btPanel.hide()
    }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: 20
            color:  btPanel.themeBg
            clip:   true

            MouseArea { anchors.fill: parent; onClicked: {} }

            Rectangle {
                anchors.fill: parent; radius: parent.radius; color: "transparent"
                border.width: 1
                border.color: Qt.rgba(btPanel.themeFg.r, btPanel.themeFg.g, btPanel.themeFg.b, 0.08)
            }

            ColumnLayout {
                id: cardContent
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 24; topMargin: 24 }
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "󰂯  Bluetooth"; color: btPanel.themeFg; opacity: 0.7
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; weight: Font.Medium; letterSpacing: 0.5 }
                    }
                    Item { Layout.fillWidth: true }
                    Item {
                        width: 30; height: 30; visible: btPanel.btEnabled
                        Rectangle {
                            anchors.fill: parent; radius: 9
                            color: scanHover.containsMouse
                                ? Qt.rgba(btPanel.themeAccent.r, btPanel.themeAccent.g, btPanel.themeAccent.b, 0.20)
                                : Qt.rgba(1, 1, 1, 0.06)
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        Text {
                            anchors.centerIn: parent; text: "󰑐"
                            color: btPanel.scanning ? btPanel.themeAccent : Qt.rgba(btPanel.themeFg.r, btPanel.themeFg.g, btPanel.themeFg.b, 0.6)
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                            Behavior on color { ColorAnimation { duration: 140 } }
                            RotationAnimation on rotation {
                                running: btPanel.scanning; loops: Animation.Infinite
                                from: 0; to: 360; duration: 1000
                            }
                        }
                        HoverHandler { id: scanHover }
                        TapHandler  { onTapped: btPanel.scan() }
                    }
                    Item { width: 8; visible: !btPanel.noController }
                    Item {
                        width: 44; height: 26; visible: !btPanel.noController
                        Rectangle {
                            anchors.fill: parent; radius: 13
                            color: btPanel.btEnabled
                                ? Qt.rgba(btPanel.themeAccent.r, btPanel.themeAccent.g, btPanel.themeAccent.b, 0.35)
                                : Qt.rgba(1, 1, 1, 0.10)
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Rectangle {
                                x: btPanel.btEnabled ? parent.width - width - 3 : 3
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20; height: 20; radius: 10
                                color: btPanel.btEnabled ? btPanel.themeAccent : Qt.rgba(btPanel.themeFg.r, btPanel.themeFg.g, btPanel.themeFg.b, 0.4)
                                Behavior on x     { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation  { duration: 200 } }
                            }
                        }
                        TapHandler { onTapped: btPanel.toggleBluetooth() }
                    }
                }

                Text {
                    Layout.fillWidth: true; text: btPanel.errorMsg; color: "#ff6b6b"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
                    wrapMode: Text.WordWrap; visible: btPanel.errorMsg !== ""
                }

                Rectangle {
                    Layout.fillWidth: true; height: 1
                    color: Qt.rgba(btPanel.themeFg.r, btPanel.themeFg.g, btPanel.themeFg.b, 0.06)
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2

                    Text {
                        text: btPanel.noController ? "Nessun controller Bluetooth"
                            : !btPanel.btEnabled   ? "Bluetooth disattivato"
                            : btPanel.devices.length === 0
                                ? (btPanel.scanning ? "Scansione in corso..." : "Nessun dispositivo abbinato") : ""
                        color: Qt.rgba(btPanel.themeFg.r, btPanel.themeFg.g, btPanel.themeFg.b, 0.35)
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; italic: true }
                        visible: btPanel.noController || !btPanel.btEnabled || btPanel.devices.length === 0
                        Layout.alignment: Qt.AlignHCenter; wrapMode: Text.WordWrap
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                    }

                    Repeater {
                        model: (btPanel.btEnabled && !btPanel.noController) ? btPanel.devices : []
                        delegate: Item {
                            Layout.fillWidth: true; height: 40
                            readonly property bool isConnecting: btPanel.connectingTo === modelData.mac
                            readonly property bool isConnected:  modelData.connected

                            Rectangle {
                                anchors.fill: parent; anchors.leftMargin: -8; anchors.rightMargin: -8
                                radius: 10
                                color: isConnected
                                    ? Qt.rgba(btPanel.themeAccent.r, btPanel.themeAccent.g, btPanel.themeAccent.b, 0.12)
                                    : (dh.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            RowLayout {
                                anchors.fill: parent; spacing: 12
                                Text {
                                    text: btPanel.btIcon(modelData.type)
                                    color: isConnected ? btPanel.themeAccent : Qt.rgba(btPanel.themeFg.r, btPanel.themeFg.g, btPanel.themeFg.b, 0.40)
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 1
                                    Text {
                                        Layout.fillWidth: true; text: modelData.name
                                        color: isConnected ? btPanel.themeFg : Qt.rgba(btPanel.themeFg.r, btPanel.themeFg.g, btPanel.themeFg.b, 0.70)
                                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; weight: isConnected ? Font.Medium : Font.Normal }
                                        elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                    Text {
                                        text: isConnecting ? "Connessione..." : isConnected ? "Connesso" : "Abbinato"
                                        color: isConnected
                                            ? Qt.rgba(btPanel.themeAccent.r, btPanel.themeAccent.g, btPanel.themeAccent.b, 0.7)
                                            : Qt.rgba(btPanel.themeFg.r, btPanel.themeFg.g, btPanel.themeFg.b, 0.30)
                                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 9 }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                }
                                Text {
                                    text: "󰑐"; color: btPanel.themeAccent
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                                    visible: isConnecting
                                    RotationAnimation on rotation {
                                        running: isConnecting; loops: Animation.Infinite
                                        from: 0; to: 360; duration: 900
                                    }
                                }
                                Item {
                                    width: 26; height: 26; visible: !isConnecting && dh.containsMouse
                                    Rectangle {
                                        anchors.fill: parent; radius: 7
                                        color: rmHover.containsMouse ? Qt.rgba(1,0,0,0.15) : Qt.rgba(1,1,1,0.05)
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                    Text {
                                        anchors.centerIn: parent; text: "󰅙"
                                        color: Qt.rgba(btPanel.themeFg.r, btPanel.themeFg.g, btPanel.themeFg.b, 0.35)
                                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                                    }
                                    HoverHandler { id: rmHover }
                                    TapHandler  { onTapped: btPanel.remove(modelData.mac) }
                                }
                            }
                            HoverHandler { id: dh }
                            TapHandler {
                                onTapped: {
                                    if (isConnecting) return
                                    if (isConnected) btPanel.disconnect(modelData.mac)
                                    else btPanel.connect(modelData.mac)
                                }
                            }
                        }
                    }
                }

                Item { height: 4 }
            }
        }
    }
}