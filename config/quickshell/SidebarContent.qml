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

    function roleColor(role) {
        switch (role) {
            case "second": return themeSecond
            case "warm":   return themeWarm
            case "fresh":  return themeFresh
            default:       return themeAccent
        }
    }

    readonly property int  pad:        24   
    readonly property int  sectionGap: 28  
    readonly property int  clockSize:  62
    readonly property int  artSize:    72
    readonly property int  panelRad:   22

    readonly property int  gridCols: 5
    readonly property int  gridGap:  12
    readonly property real gridBtn:
        (width - pad * 2 - gridGap * (gridCols - 1)) / gridCols

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: sidebarContentRoot.pad
        spacing: sidebarContentRoot.sectionGap

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            spacing: 4

            Text {
                id: clockT
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: -5
                color: themeFg
                font {
                    family: "JetBrainsMono Nerd Font"
                    pixelSize: sidebarContentRoot.clockSize
                    weight: Font.ExtraLight
                }
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
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    Layout.maximumWidth: implicitWidth
                    text: Qt.formatDate(new Date(), "dddd, d MMMM").toUpperCase()
                    color: themeFg
                    opacity: 0.8
                    elide: Text.ElideRight
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 10; weight: Font.Medium; letterSpacing: 0.2 }
                }
                Text {
                    text: batteryIcon + " " + batteryPercent
                    color: themeFg
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 10; weight: Font.Bold }
                }
                Item { Layout.fillWidth: true }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: sidebarContentRoot.gridBtn * 2 + sidebarContentRoot.gridGap

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
                contentWidth:  buttonGrid.implicitWidth + 20
                contentHeight: buttonGrid.implicitHeight + 20

                Grid {
                    id: buttonGrid
                    x: 10; y: 10
                    rows: 2
                    spacing: sidebarContentRoot.gridGap
                    flow: Grid.TopToBottom

                    Repeater {
                        model: buttonModel
                        delegate: IconButton {
                            icon:   model.icon
                            tint:   sidebarContentRoot.roleColor(model.color_role)
                            baseFg: themeFg
                            boxSize:   sidebarContentRoot.gridBtn
                            boxRadius: sidebarContentRoot.gridBtn * 0.3
                            iconSize:  16
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


        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: playerLayout.implicitHeight + 36
            visible: hasPlayer

            Theme {
                anchors.fill: parent
                radius: sidebarContentRoot.panelRad
                style: "panel"
                tintColor: themeAccent
                panelSecond: themeSecond
            }

            ColumnLayout {
                id: playerLayout
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

    
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        id: artContainer
                        width:  sidebarContentRoot.artSize
                        height: sidebarContentRoot.artSize

                        Item {
                            id: maskedArt
                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width:  maskedArt.width
                                    height: maskedArt.height
                                    radius: sidebarContentRoot.artSize * 0.28
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
                                sourceSize: Qt.size(150, 150)
                            }

                            Image {
                                id: artImg
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                smooth: true; cache: true; asynchronous: true
                                sourceSize: Qt.size(150, 150)
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

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        clip: true

                        Text {
                            text: activePlayer?.trackTitle ?? "Now playing"
                            color: themeFg
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 15; weight: Font.Medium; letterSpacing: 0.2 }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: activePlayer?.trackArtist ?? "Unknown artist"
                            color: themeSecond
                            opacity: 0.65
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; letterSpacing: 0.3 }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                SeekBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    player:  activePlayer
                    playing: sidebarContentRoot.isPlaying && sidebarContentRoot.visible
                    fg:      themeFg
                    accent:  themeAccent
                    trackHeight: 4
                    thumbSize:   10
                    haloSize:    20
                    updateInterval: 500
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 18

                    IconButton {
                        icon: "󰒮"; boxSize: 38; boxRadius: 12; iconSize: 18
                        tint: themeAccent; baseFg: themeFg
                        onActivated: activePlayer?.previous()
                    }
                    IconButton {
                        boxSize: 48; boxRadius: 14; iconSize: 20
                        tint: themeAccent; baseFg: themeFg
                        icon: sidebarContentRoot.isPlaying ? "󰏤" : "󰐊"
                        onActivated: activePlayer?.togglePlaying()
                    }
                    IconButton {
                        icon: "󰒭"; boxSize: 38; boxRadius: 12; iconSize: 18
                        tint: themeAccent; baseFg: themeFg
                        onActivated: activePlayer?.next()
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
