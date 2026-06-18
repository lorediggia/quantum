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
                color: themeFg
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 72; weight: Font.ExtraLight }
                Component.onCompleted: text = Qt.formatTime(new Date(), "hh:mm")
                Timer {
                    interval: 10000
                    running: sidebarContentRoot.visible
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: clockT.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 14

                Text {
                    text: Qt.formatDate(new Date(), "dddd, d MMMM").toUpperCase()
                    color: themeFg
                    opacity: 0.8
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; weight: Font.Medium; letterSpacing: 0.2 }
                }
                Text {
                    text: batteryIcon + " " + batteryPercent
                    color: themeFg
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
                            tint:   themeAccent
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

                            readonly property string artUrl: (hasPlayer && activePlayer.trackArtUrl) ? activePlayer.trackArtUrl : ""

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0.0; color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.22) }
                                    GradientStop { position: 1.0; color: Qt.rgba(themeSecond.r, themeSecond.g, themeSecond.b, 0.08) }
                                }
                            }

                            Image {
                                id: oldImg
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                smooth: true; cache: true; asynchronous: true
                                sourceSize: Qt.size(170, 170)
                            }

                            Image {
                                id: artImg
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                smooth: true; cache: true; asynchronous: true
                                sourceSize: Qt.size(170, 170)
                                opacity: 0

                                onStatusChanged: {
                                    if (status === Image.Ready) fadeInAnim.restart()
                                }

                                NumberAnimation {
                                    id: fadeInAnim
                                    target: artImg; property: "opacity"
                                    from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic
                                }
                            }

                            onArtUrlChanged: {
                                if (artUrl === artImg.source.toString()) return
                                if (artImg.status === Image.Ready && artImg.source.toString() !== "")
                                    oldImg.source = artImg.source
                                artImg.opacity = 0
                                artImg.source = artUrl
                            }

                            Component.onCompleted: artImg.source = artUrl
                        }
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
                SeekBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    player:  activePlayer
                    playing: sidebarContentRoot.isPlaying && sidebarContentRoot.visible
                    fg:      themeFg
                    accent:  themeAccent
                    trackHeight: 4
                    thumbSize:   11
                    haloSize:    22
                    updateInterval: 500
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
