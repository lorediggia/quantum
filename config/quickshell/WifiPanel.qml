import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: wifiPanel

    property color themeFg:     "#ffffff"
    property color themeBg:     "#66000000"
    property color themeRawBg:  "#000000"
    property color themeAccent: "#ffffff"
    property color themeSecond: "#ffffff"

    property var    networks:       []
    property bool   scanning:       false
    property string connectingTo:   ""
    property string errorMsg:       ""
    property string passwordTarget: ""
    property bool   showPassword:   false
    property string activeSsid:     ""

    visible: false
    color:   "transparent"

    signal closed()

    WlrLayershell.namespace:     "quickshell-wifi"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    implicitWidth: 340
    implicitHeight: Math.min(cardContent.implicitHeight + 48, 540)

    function show() {
        visible        = true
        errorMsg       = ""
        passwordTarget = ""
        scan()
    }

    function hide() {
        visible = false
        closed()
    }

    function scan() {
        scanning = true
        errorMsg = ""
        scanProc.running = true
    }

    function connect(ssid, secured) {
        if (secured) {
            passwordTarget = ssid
            errorMsg = ""
            Qt.callLater(() => pwInput.forceActiveFocus())
        } else {
            doConnect(ssid, "")
        }
    }

    function doConnect(ssid, password) {
        errorMsg       = ""
        connectingTo   = ssid
        passwordTarget = ""
        pwInput.text   = ""
        const cmd = password !== ""
            ? ["sh", "-c", "nmcli dev wifi connect " + JSON.stringify(ssid) + " password " + JSON.stringify(password) + " 2>&1 | tail -1"]
            : ["sh", "-c", "nmcli con up " + JSON.stringify(ssid) + " 2>/dev/null || nmcli dev wifi connect " + JSON.stringify(ssid) + " 2>&1 | tail -1"]
        connectProc.command = cmd
        connectProc.running = true
    }

    function disconnect(ssid) {
        disconnectProc.command = ["sh", "-c", "nmcli con down " + JSON.stringify(ssid) + " 2>&1"]
        disconnectProc.running = true
        connectingTo = ssid
    }

    function signalIcon(strength) {
        if (strength >= 80) return "󰤨"
        if (strength >= 60) return "󰤥"
        if (strength >= 40) return "󰤢"
        if (strength >= 20) return "󰤟"
        return "󰤯"
    }

    Process {
        id: scanProc
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan auto 2>/dev/null"]
        property string buf: ""
        stdout: SplitParser { onRead: (d) => scanProc.buf += d + "\n" }
        onExited: {
            const lines = scanProc.buf.split("\n")
            scanProc.buf = ""
            wifiPanel.scanning = false
            const byName = {}
            let active = ""
            for (const line of lines) {
                if (!line.trim()) continue
                const parts = line.split(":")
                if (parts.length < 4) continue
                const inUse    = parts[0].trim()
                const signal   = parseInt(parts[1]) || 0
                const security = parts[2].trim()
                let   ssid     = parts.slice(3).join(":").replace(/\\:/g, ":").replace(/\\\\/g, "\\").trim()
                if (!ssid) continue
                const isActive = inUse === "*"
                if (isActive) active = ssid
                const secured = security !== "" && security !== "--"
                if (!byName[ssid] || signal > byName[ssid].signal || isActive)
                    byName[ssid] = { ssid, signal, secured, active: isActive }
            }
            const nets = Object.values(byName)
            nets.sort((a, b) => (b.active - a.active) || (b.signal - a.signal))
            wifiPanel.networks   = nets
            wifiPanel.activeSsid = active
            wifiPanel.connectingTo = ""
        }
    }

    Process {
        id: connectProc
        property string buf: ""
        stdout: SplitParser { onRead: (d) => connectProc.buf += d }
        onExited: (code) => {
            const out = connectProc.buf.trim()
            connectProc.buf = ""
            if (code !== 0 || out.toLowerCase().includes("error") || out.toLowerCase().includes("fail"))
                wifiPanel.errorMsg = out || "Connessione fallita"
            else
                wifiPanel.errorMsg = ""
            wifiPanel.scanning = true
            scanProc.running = true
        }
    }

    Process {
        id: disconnectProc
        onExited: { wifiPanel.scanning = true; scanProc.running = true }
    }

    Shortcut {
        sequence: "Escape"
        enabled:  wifiPanel.visible
        onActivated: wifiPanel.hide()
    }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: 20
            color:  wifiPanel.themeBg
            clip:   true

            MouseArea { anchors.fill: parent; onClicked: {} }

            Rectangle {
                anchors.fill: parent; radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.08)
            }

            ColumnLayout {
                id: cardContent
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 24; topMargin: 24 }
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "󰖩  Wi-Fi"
                        color: wifiPanel.themeFg; opacity: 0.7
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; weight: Font.Medium; letterSpacing: 0.5 }
                    }
                    Item { Layout.fillWidth: true }
                    Item {
                        width: 30; height: 30
                        Rectangle {
                            anchors.fill: parent; radius: 9
                            color: scanHover.containsMouse
                                ? Qt.rgba(wifiPanel.themeAccent.r, wifiPanel.themeAccent.g, wifiPanel.themeAccent.b, 0.20)
                                : Qt.rgba(1, 1, 1, 0.06)
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        Text {
                            anchors.centerIn: parent; text: "󰑐"
                            color: wifiPanel.scanning ? wifiPanel.themeAccent : Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.6)
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                            Behavior on color { ColorAnimation { duration: 140 } }
                            RotationAnimation on rotation {
                                running: wifiPanel.scanning; loops: Animation.Infinite
                                from: 0; to: 360; duration: 1000
                            }
                        }
                        HoverHandler { id: scanHover }
                        TapHandler  { onTapped: wifiPanel.scan() }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: wifiPanel.activeSsid !== "" ? "Connesso a " + wifiPanel.activeSsid : "Non connesso"
                    color: wifiPanel.activeSsid !== "" ? wifiPanel.themeAccent : Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.4)
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 10; weight: Font.Medium }
                    elide: Text.ElideRight
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8
                    visible: wifiPanel.passwordTarget !== ""

                    Text {
                        text: "Password per \"" + wifiPanel.passwordTarget + "\""
                        color: Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.6)
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 40; radius: 10
                        color: Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: pwInput.activeFocus
                            ? Qt.rgba(wifiPanel.themeAccent.r, wifiPanel.themeAccent.g, wifiPanel.themeAccent.b, 0.5)
                            : Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.10)
                        Behavior on border.color { ColorAnimation { duration: 160 } }
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 8; spacing: 8
                            TextInput {
                                id: pwInput
                                Layout.fillWidth: true
                                color: wifiPanel.themeFg
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                                echoMode: wifiPanel.showPassword ? TextInput.Normal : TextInput.Password
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                selectionColor: Qt.rgba(wifiPanel.themeAccent.r, wifiPanel.themeAccent.g, wifiPanel.themeAccent.b, 0.3)
                                Keys.onReturnPressed: { if (text.length > 0) wifiPanel.doConnect(wifiPanel.passwordTarget, text) }
                                Keys.onEscapePressed: { wifiPanel.passwordTarget = ""; text = "" }
                                Text {
                                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                    text: "Inserisci password..."
                                    color: Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.28)
                                    font: pwInput.font; visible: pwInput.text === ""
                                }
                            }
                            Item {
                                width: 26; height: 26
                                Rectangle {
                                    anchors.fill: parent; radius: 7
                                    color: eyeHover.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: wifiPanel.showPassword ? "󰛐" : "󰛑"
                                    color: Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.45)
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                                }
                                HoverHandler { id: eyeHover }
                                TapHandler  { onTapped: wifiPanel.showPassword = !wifiPanel.showPassword }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true; height: 36
                        Rectangle {
                            anchors.fill: parent; radius: 10
                            color: connectBtnHover.containsMouse
                                ? Qt.rgba(wifiPanel.themeAccent.r, wifiPanel.themeAccent.g, wifiPanel.themeAccent.b, 0.28)
                                : Qt.rgba(wifiPanel.themeAccent.r, wifiPanel.themeAccent.g, wifiPanel.themeAccent.b, 0.18)
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        Text {
                            anchors.centerIn: parent; text: "Connetti"
                            color: wifiPanel.themeAccent
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; weight: Font.Medium }
                        }
                        HoverHandler { id: connectBtnHover }
                        TapHandler { onTapped: if (pwInput.text.length > 0) wifiPanel.doConnect(wifiPanel.passwordTarget, pwInput.text) }
                    }
                }

                Text {
                    Layout.fillWidth: true; text: wifiPanel.errorMsg; color: "#ff6b6b"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
                    wrapMode: Text.WordWrap; visible: wifiPanel.errorMsg !== ""
                }

                Rectangle {
                    Layout.fillWidth: true; height: 1
                    color: Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.06)
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2

                    Text {
                        text: wifiPanel.networks.length === 0
                            ? (wifiPanel.scanning ? "Scansione in corso..." : "Nessuna rete trovata") : ""
                        color: Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.35)
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; italic: true }
                        visible: wifiPanel.networks.length === 0
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Repeater {
                        model: wifiPanel.networks
                        delegate: Item {
                            Layout.fillWidth: true; height: 38
                            readonly property bool isConnecting: wifiPanel.connectingTo === modelData.ssid
                            readonly property bool isActive:     modelData.active

                            Rectangle {
                                anchors.fill: parent; anchors.leftMargin: -8; anchors.rightMargin: -8
                                radius: 10
                                color: isActive
                                    ? Qt.rgba(wifiPanel.themeAccent.r, wifiPanel.themeAccent.g, wifiPanel.themeAccent.b, 0.12)
                                    : (nh.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            RowLayout {
                                anchors.fill: parent; spacing: 10
                                Text {
                                    text: wifiPanel.signalIcon(modelData.signal)
                                    color: isActive ? wifiPanel.themeAccent : Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.45)
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 }
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                Text {
                                    Layout.fillWidth: true; text: modelData.ssid
                                    color: isActive ? wifiPanel.themeFg : Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, 0.75)
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; weight: isActive ? Font.Medium : Font.Normal }
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                Text {
                                    text: isConnecting ? "󰑐" : isActive ? "󰅙" : modelData.secured ? "󰌾" : ""
                                    color: Qt.rgba(wifiPanel.themeFg.r, wifiPanel.themeFg.g, wifiPanel.themeFg.b, isActive ? 0.35 : 0.25)
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                                    visible: text !== ""
                                    RotationAnimation on rotation {
                                        running: isConnecting; loops: Animation.Infinite
                                        from: 0; to: 360; duration: 900
                                    }
                                }
                            }
                            HoverHandler { id: nh }
                            TapHandler {
                                onTapped: {
                                    if (isConnecting) return
                                    if (isActive) wifiPanel.disconnect(modelData.ssid)
                                    else wifiPanel.connect(modelData.ssid, modelData.secured)
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