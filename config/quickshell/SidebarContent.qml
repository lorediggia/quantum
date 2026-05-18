import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: sidebarContentRoot

    property color themeAccent
    property color themeSecond
    property color themeFg
    property color themeRawBg
    property color themeFresh
    property color themeWarm

    property string batteryPercent
    property string batteryIcon

    property var  buttonModel
    property var  activePlayer
    property bool hasPlayer: false
    property bool isPlaying: false

    signal requestSticker()
    signal requestCmd(var cmdArray)
    signal requestHide()
    signal requestPowerCycle()

    function colorForRole(role) {
        switch (role) {
            case "warm":   return themeWarm
            case "fresh":  return themeFresh
            case "accent": return themeAccent
        }
        return themeSecond
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 32

        // header

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            spacing: 4

            Text {
                id: clockT
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: -6
                color: themeAccent
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 72; weight: Font.ExtraLight }
                Component.onCompleted: text = Qt.formatTime(new Date(), "hh:mm")
                Timer {
                    interval: 10000; running: true; repeat: true; triggeredOnStart: true
                    onTriggered: clockT.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 14

                Text {
                    text: Qt.formatDate(new Date(), "dddd, d MMMM").toUpperCase()
                    color: themeSecond
                    opacity: 0.8
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; weight: Font.Medium; letterSpacing: 0.2 }
                }
                Text {
                    text: batteryIcon + " " + batteryPercent
                    color: themeSecond
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; weight: Font.Bold }
                }
            }
        }

        // button grid

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 112

            Flickable {
                anchors.fill: parent
                anchors.margins: -10
                clip: true
                interactive: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.DragAndOvershootBounds
                maximumFlickVelocity: 800
                flickDeceleration: 2500
                pixelAligned: true
                contentWidth: buttonGrid.implicitWidth + 20
                contentHeight: 132

                Grid {
                    id: buttonGrid
                    x: 10; y: 10
                    rows: 2
                    spacing: 16
                    flow: Grid.TopToBottom

                    Repeater {
                        model: buttonModel
                        delegate: IconButton {
                            icon:   model.icon
                            tint:   colorForRole(model.color_role)
                            baseFg: themeFg
                            onActivated: {
                                switch (model.action) {
                                    case "sticker":       requestSticker(); break
                                    case "power_profile": requestPowerCycle(); break
                                    case "ipc":           requestCmd(["quickshell", "ipc", "call", model.cmd0, model.cmd1]); break
                                    default:
                                        requestHide()
                                        requestCmd(model.cmd1 !== "" ? [model.cmd0, model.cmd1] : [model.cmd0])
                                }
                            }
                        }
                    }
                }
            }
        }

        // media player
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: playerLayout.implicitHeight + 40
            visible: hasPlayer

            Theme {
                anchors.fill: parent
                radius: 24
                style: "panel"
                tintColor: themeAccent
                panelSecond: themeSecond
            }

            ColumnLayout {
                id: playerLayout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // cover
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 18

                    // album art
                    Item {
                        id: artContainer
                        width: 85
                        height: 85

                        Item {
                            id: maskedArt
                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width:  maskedArt.width
                                    height: maskedArt.height
                                    radius: 24
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop {
                                        position: 0.0
                                        color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.22)
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: Qt.rgba(themeSecond.r, themeSecond.g, themeSecond.b, 0.08)
                                    }
                                }
                            }

                            Image {
                                id: oldImg
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                cache: true
                                asynchronous: true
                                sourceSize: Qt.size(170, 170)
                            }

                            Image {
                                id: artImg
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                cache: true
                                asynchronous: true
                                sourceSize: Qt.size(170, 170)
                                opacity: 0

                                onStatusChanged: {
                                    if (status === Image.Ready) fadeInAnim.restart()
                                }
                            }
                        }

                        NumberAnimation {
                            id: fadeInAnim
                            target: artImg
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 700
                            easing.type: Easing.OutCubic
                        }

                        function refreshArt() {
                            if (!hasPlayer) return
                            const url = activePlayer.trackArtUrl ?? ""
                            if (url === "" || url === artImg.source.toString()) return

                            if (artImg.status === Image.Ready && artImg.source.toString() !== "") {
                                oldImg.source = artImg.source
                            }
                            fadeInAnim.stop()
                            artImg.opacity = 0
                            artImg.source = url
                        }

                        Connections {
                            target: activePlayer
                            enabled: hasPlayer
                            function onTrackTitleChanged()  { artContainer.refreshArt() }
                            function onTrackArtUrlChanged() { artContainer.refreshArt() }
                        }

                        Component.onCompleted: refreshArt()
                    }

                    // title
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        clip: true

                        Text {
                            text: activePlayer?.trackTitle  ?? "Now playing"
                            color: themeFg
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 17; weight: Font.Medium; letterSpacing: 0.2 }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: activePlayer?.trackArtist ?? "Unknown artist"
                            color: themeSecond
                            opacity: 0.65
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; letterSpacing: 0.3 }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                // progress bar
                Item {
                    id: progressItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24

                    property bool isDragging: false
                    property real dragProgress: 0
                    property real currentPos: activePlayer ? activePlayer.position : 0

                    property real progress: {
                        if (!activePlayer || activePlayer.length <= 0) return 0
                        if (isDragging) return dragProgress
                        return currentPos / activePlayer.length
                    }

                    readonly property bool hovered: progressMouse.containsMouse || isDragging
                    readonly property real thumbX: track.width * Math.max(0.0, Math.min(1.0, progress))

                    Timer {
                        interval: 500; repeat: true
                        running: isPlaying && sidebarContentRoot.visible && !progressItem.isDragging
                        onTriggered: if (activePlayer) progressItem.currentPos = activePlayer.position
                    }

                    // track
                    Rectangle {
                        id: track
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4
                        radius: 2
                        color: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, progressItem.hovered ? 0.18 : 0.10)

                        Behavior on color { ColorAnimation { duration: 260; easing.type: Easing.OutCubic } }

                        Rectangle {
                            id: fill
                            width: parent.width * Math.max(0.0, Math.min(1.0, progressItem.progress))
                            height: parent.height
                            radius: parent.radius
                            color: themeAccent

                            Behavior on width {
                                enabled: !progressItem.isDragging
                                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Rectangle {
                        x: progressItem.thumbX - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 22
                        radius: width / 2
                        color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.20)

                        opacity: progressItem.hovered ? 1 : 0
                        scale:   progressItem.hovered ? 1 : 0.3

                        Behavior on opacity { NumberAnimation { duration: 260 } }
                        Behavior on scale   { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                        Behavior on x {
                            enabled: !progressItem.isDragging
                            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                        }
                    }

                    // thumb 
                    Rectangle {
                        x: progressItem.thumbX - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 11
                        height: 11
                        radius: width / 2
                        color: themeAccent

                        opacity: progressItem.hovered ? 1 : 0
                        scale: progressMouse.pressed
                            ? 0.85
                            : (progressItem.hovered ? 1 : 0.3)

                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on scale   { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                        Behavior on x {
                            enabled: !progressItem.isDragging
                            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        id: progressMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        function updateDrag(mouseX) {
                            progressItem.dragProgress = Math.max(0.0, Math.min(1.0, mouseX / width))
                        }

                        onPressed: (mouse) => {
                            progressItem.isDragging = true
                            updateDrag(mouse.x)
                        }
                        
                        onPositionChanged: (mouse) => {
                            if (progressItem.isDragging) {
                                updateDrag(mouse.x)
                            }
                        }
                        
                        onReleased: (mouse) => {
                            if (progressItem.isDragging) {
                                updateDrag(mouse.x)
                                if (activePlayer && activePlayer.length > 0) {
                                    let targetPos = progressItem.dragProgress * activePlayer.length
                                    activePlayer.position = targetPos
                                    progressItem.currentPos = targetPos // Forza l'aggiornamento grafico se in pausa
                                }
                                progressItem.isDragging = false
                            }
                        }
                    }
                }
                // playback
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 22

                    IconButton {
                        icon: "󰒮"; boxSize: 44; boxRadius: 14; iconSize: 20
                        tint: themeAccent; baseFg: themeFg
                        onActivated: activePlayer?.previous()
                    }
                    IconButton {
                        boxSize: 56; boxRadius: 16; iconSize: 22
                        tint: themeAccent; baseFg: themeFg
                        icon: sidebarContentRoot.isPlaying ? "󰏤" : "󰐊"
                        onActivated: activePlayer?.togglePlaying()
                    }
                    IconButton {
                        icon: "󰒭"; boxSize: 44; boxRadius: 14; iconSize: 20
                        tint: themeAccent; baseFg: themeFg
                        onActivated: activePlayer?.next()
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}