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

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            spacing: 4

            Text {
                id: clockT
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: -6 // ← Compensa lo spazio vuoto a sinistra del font
                horizontalAlignment: Text.AlignLeft
                color: themeAccent
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 72; weight: Font.ExtraLight }
                Component.onCompleted: text = Qt.formatTime(new Date(), "hh:mm")
                Timer {
                    interval: 1000; running: true; repeat: true; triggeredOnStart: true
                    onTriggered: clockT.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 14

                Text {
                    text: Qt.formatDate(new Date(), "dddd, d MMMM").toUpperCase()
                    color: themeSecond
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; weight: Font.Medium; letterSpacing: 0.2 }
                }
                Text {
                    text: batteryIcon + " " + batteryPercent
                    color: themeAccent
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; weight: Font.Bold }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 112

            Flickable {
                anchors.fill: parent
                anchors { topMargin: -10; bottomMargin: -10; leftMargin: -10; rightMargin: -4 }
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
                    spacing: 12
                    flow: Grid.TopToBottom

                    Repeater {
                        model: buttonModel
                        delegate: Item {
                            id: btnRoot
                            width: 50; height: 50

                            readonly property color roleColor: colorForRole(model.color_role)

                            Rectangle {
                                anchors.centerIn: parent
                                width: 50; height: 50; radius: 14
                                color: "transparent"
                                opacity: btnMouse.containsMouse ? 1.0 : 0.0
                                scale:   btnMouse.containsMouse ? 1.35 : 1.0
                                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 44; height: 44; radius: 12
                                    color: Qt.rgba(btnRoot.roleColor.r, btnRoot.roleColor.g, btnRoot.roleColor.b, 0.12)
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: btnMouse.pressed
                                    ? Qt.rgba(1, 1, 1, 0.10)
                                    : btnMouse.containsMouse
                                        ? Qt.rgba(1, 1, 1, 0.07)
                                        : Qt.rgba(1, 1, 1, 0.04)
                                Behavior on color { ColorAnimation { duration: 180 } }

                                border {
                                    width: 1
                                    color: btnMouse.containsMouse
                                        ? Qt.rgba(btnRoot.roleColor.r, btnRoot.roleColor.g, btnRoot.roleColor.b, 0.55)
                                        : Qt.rgba(1, 1, 1, 0.09)
                                }
                                Behavior on border.color { ColorAnimation { duration: 220 } }

                                scale: btnMouse.pressed ? 0.91 : 1.0
                                Behavior on scale { SpringAnimation { spring: 7; damping: 0.42 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: model.icon
                                    color: btnMouse.containsMouse
                                        ? btnRoot.roleColor
                                        : Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.55)
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 21 }
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    scale: btnMouse.pressed ? 0.88 : (btnMouse.containsMouse ? 1.10 : 1.0)
                                    Behavior on scale { SpringAnimation { spring: 7; damping: 0.38 } }
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        switch (model.action) {
                                            case "sticker":       requestSticker(); break
                                            case "power_profile": requestPowerCycle(); break
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
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: playerLayout.implicitHeight + 40
            radius: 24
            color: "#12ffffff"
            border { width: 1; color: "#0effffff" }
            visible: hasPlayer

            ColumnLayout {
                id: playerLayout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 18

                    Rectangle {
                        id: artContainer
                        width: 85; height: 85; radius: 20
                        color: "#2affffff"

                        property bool showingA: true
                        property string artUrl: activePlayer?.trackArtUrl ?? ""
                        onArtUrlChanged: {
                            if (showingA) {
                                imgB.source = artUrl
                                if (imgB.status === Image.Ready) showingA = false
                            } else {
                                imgA.source = artUrl
                                if (imgA.status === Image.Ready) showingA = true
                            }
                        }
                        Component.onCompleted: imgA.source = artUrl

                        Image {
                            id: imgA
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; smooth: true
                            visible: false; layer.enabled: true
                            onStatusChanged: {
                                if (status === Image.Ready && !artContainer.showingA)
                                    artContainer.showingA = true
                            }
                        }
                        Image {
                            id: imgB
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; smooth: true
                            visible: false; layer.enabled: true
                            onStatusChanged: {
                                if (status === Image.Ready && artContainer.showingA)
                                    artContainer.showingA = false
                            }
                        }

                        Rectangle {
                            id: artMask
                            anchors.fill: parent
                            radius: parent.radius
                            color: "white"
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: imgA; maskSource: artMask
                            opacity: artContainer.showingA ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                        OpacityMask {
                            anchors.fill: parent
                            source: imgB; maskSource: artMask
                            opacity: artContainer.showingA ? 0.0 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰎇"
                            color: themeAccent
                            opacity: 0.7
                            font.pixelSize: 32
                            visible: imgA.status !== Image.Ready && imgB.status !== Image.Ready
                        }
                    }

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

                Rectangle {
                    id: progressBg
                    Layout.fillWidth: true
                    height: progressMouse.containsMouse ? 7 : 4
                    radius: 3
                    color: progressMouse.containsMouse ? "#2effffff" : "#1cffffff"
                    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutQuart } }
                    Behavior on color  { ColorAnimation  { duration: 160 } }

                    property real currentPos: activePlayer ? activePlayer.position : 0
                    Timer {
                        interval: 500; repeat: true
                        running: isPlaying && sidebarContentRoot.visible
                        onTriggered: { if (activePlayer) progressBg.currentPos = activePlayer.position }
                    }
                    Rectangle {
                        width: parent.width * Math.min(1.0, (activePlayer && activePlayer.length > 0
                            ? progressBg.currentPos / activePlayer.length : 0))
                        height: parent.height; radius: parent.radius
                        color: themeAccent
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        id: progressMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (activePlayer && activePlayer.length > 0) {
                                const newPos = (mouse.x / width) * activePlayer.length
                                activePlayer.position = newPos
                                progressBg.currentPos = newPos
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 48

                    Row {
                        anchors.centerIn: parent
                        spacing: 38

                        Item {
                            width: 44; height: 44
                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                font.pixelSize: 22
                                scale: prevMouse.pressed ? 0.86 : (prevMouse.containsMouse ? 1.08 : 1.0)
                                Behavior on scale { SpringAnimation { spring: 4; damping: 0.4 } }
                                color:   prevMouse.containsMouse ? themeAccent : themeFg
                                opacity: prevMouse.containsMouse ? 1.0 : 0.75
                                Behavior on color   { ColorAnimation  { duration: 180 } }
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }
                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: activePlayer?.previous()
                            }
                        }

                        Rectangle {
                            id: playBtn
                            width: 48; height: 48
                            radius: 14

                            property bool localPlaying: isPlaying
                            Connections {
                                target: sidebarContentRoot
                                function onIsPlayingChanged() { playBtn.localPlaying = isPlaying }
                            }

                            color: themeAccent
                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            scale: playMouse.pressed ? 0.92 : (playMouse.containsMouse ? 1.06 : 1.0)
                            Behavior on scale { SpringAnimation { spring: 4; damping: 0.38 } }

                            Text {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: playBtn.localPlaying ? 0 : 2
                                text: playBtn.localPlaying ? "󰏤" : "󰐊"
                                color: themeRawBg
                                opacity: 0.9
                                font.pixelSize: 20
                            }

                            MouseArea {
                                id: playMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    playBtn.localPlaying = !playBtn.localPlaying
                                    activePlayer?.togglePlaying()
                                }
                            }
                        }
                        Item {
                            width: 44; height: 44
                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                font.pixelSize: 22
                                scale: nextMouse.pressed ? 0.86 : (nextMouse.containsMouse ? 1.08 : 1.0)
                                Behavior on scale { SpringAnimation { spring: 4; damping: 0.4 } }
                                color:   nextMouse.containsMouse ? themeAccent : themeFg
                                opacity: nextMouse.containsMouse ? 1.0 : 0.75
                                Behavior on color   { ColorAnimation  { duration: 180 } }
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }
                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: activePlayer?.next()
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
