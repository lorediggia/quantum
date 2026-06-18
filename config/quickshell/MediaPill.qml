import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property var   activePlayer
    property bool  hasPlayer: false
    property bool  isPlaying: false

    property color themeFg
    property color themeAccent
    property color themeSecond

    visible: hasPlayer
    implicitHeight: 38
    implicitWidth: 288

    HoverHandler { id: hover }
    readonly property bool expanded: hover.hovered

    Rectangle {
        id: pill
        height: parent.height
        width: 288
        radius: 13

        color: Qt.rgba(1, 1, 1, 0.015)
        border.width: 0

        Item {
            id: content
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Item {
                id: artCell
                width: 28; height: 28
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                readonly property string artUrl: root.hasPlayer ? (activePlayer.trackArtUrl ?? "") : ""


                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    visible: artCell.artUrl === ""
                    color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.20)
                }
                Text {
                    anchors.centerIn: parent
                    visible: artCell.artUrl === ""
                    text: "󰎈"
                    color: themeAccent
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                }


                Image {
                    id: artOld
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    cache: true; asynchronous: true; smooth: true
                    sourceSize: Qt.size(80, 80)
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle { width: artOld.width; height: artOld.height; radius: 8 }
                    }
                }

                Image {
                    id: artImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    cache: true; asynchronous: true; smooth: true
                    sourceSize: Qt.size(80, 80)
                    opacity: 0
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle { width: artImg.width; height: artImg.height; radius: 8 }
                    }

                    onStatusChanged: {
                        if (status === Image.Ready) fadeIn.restart()
                    }

                    NumberAnimation {
                        id: fadeIn
                        target: artImg; property: "opacity"
                        from: 0; to: 1; duration: 450; easing.type: Easing.OutCubic
                    }
                }

                onArtUrlChanged: {
                    if (artUrl === artImg.source.toString()) return
                    if (artImg.status === Image.Ready && artImg.source.toString() !== "")
                        artOld.source = artImg.source
                    artImg.opacity = 0
                    artImg.source = artUrl
                }

                Component.onCompleted: artImg.source = artUrl
            }


            Column {
                id: infoCol
                width: 132
                anchors.left: artCell.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: activePlayer?.trackTitle ?? "Now playing"
                    color: themeFg
                    elide: Text.ElideRight
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 11; weight: Font.Medium; letterSpacing: 0.2 }
                }

                SeekBar {
                    width: parent.width
                    height: 14
                    player:  root.activePlayer
                    playing: root.isPlaying
                    fg:      themeFg
                    accent:  themeAccent
                    trackHeight: 4
                    thumbSize:   7
                    haloSize:    14
                    updateInterval: 1000
                }
            }


            Row {
                anchors.left: infoCol.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                IconButton {
                    icon: "󰒮"; boxSize: 26; boxRadius: 8; iconSize: 13
                    tint: themeAccent; baseFg: themeFg
                    onActivated: activePlayer?.previous()
                }
                IconButton {
                    icon: root.isPlaying ? "󰏤" : "󰐊"
                    boxSize: 26; boxRadius: 8; iconSize: 14
                    tint: themeAccent; baseFg: themeFg
                    onActivated: activePlayer?.togglePlaying()
                }
                IconButton {
                    icon: "󰒭"; boxSize: 26; boxRadius: 8; iconSize: 13
                    tint: themeAccent; baseFg: themeFg
                    onActivated: activePlayer?.next()
                }
            }
        }
    }
}