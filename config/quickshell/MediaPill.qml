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

    property real artSize:   20
    property real infoWidth: 92
    property real btnSize:   22
    property real btnGap:    2
    property real gap:       8    
    property real hPad:      9   

    readonly property real ctrlWidth: btnSize * 3 + btnGap * 2

    visible: hasPlayer
    implicitHeight: 28
    implicitWidth: hPad * 2 + artSize + gap + infoWidth + gap + ctrlWidth

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2.15

        color: Qt.rgba(1, 1, 1, 0.015)
        border.width: 0

        Item {
            id: content
            anchors.fill: parent
            anchors.leftMargin:  root.hPad
            anchors.rightMargin: root.hPad

            Item {
                id: artCell
                width: root.artSize; height: root.artSize
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                readonly property real rad: root.artSize * 0.3
                readonly property string artUrl: root.hasPlayer ? (activePlayer.trackArtUrl ?? "") : ""

                Rectangle {
                    anchors.fill: parent
                    radius: artCell.rad
                    visible: artCell.artUrl === ""
                    color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.20)
                }
                Text {
                    anchors.centerIn: parent
                    visible: artCell.artUrl === ""
                    text: "󰎈"
                    color: themeAccent
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: root.artSize * 0.5 }
                }

                Image {
                    id: artOld
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    cache: true; asynchronous: true; smooth: true
                    sourceSize: Qt.size(64, 64)
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle { width: artOld.width; height: artOld.height; radius: artCell.rad }
                    }
                }

                Image {
                    id: artImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    cache: true; asynchronous: true; smooth: true
                    sourceSize: Qt.size(64, 64)
                    opacity: 0
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle { width: artImg.width; height: artImg.height; radius: artCell.rad }
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
                width: root.infoWidth
                anchors.left: artCell.right
                anchors.leftMargin: root.gap
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: activePlayer?.trackTitle ?? "Now playing"
                    color: themeFg
                    elide: Text.ElideRight
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 10; weight: Font.Medium; letterSpacing: 0.2 }
                }

                SeekBar {
                    width: parent.width
                    height: 11
                    player:  root.activePlayer
                    playing: root.isPlaying
                    fg:      themeFg
                    accent:  themeAccent
                    trackHeight: 3
                    thumbSize:   6
                    haloSize:    11
                    updateInterval: 1000
                }
            }
            
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.btnGap

                IconButton {
                    icon: "󰒮"
                    boxSize: root.btnSize; boxRadius: root.btnSize * 0.32; iconSize: 11
                    tint: themeAccent; baseFg: themeFg
                    onActivated: activePlayer?.previous()
                }
                IconButton {
                    icon: root.isPlaying ? "󰏤" : "󰐊"
                    boxSize: root.btnSize; boxRadius: root.btnSize * 0.32; iconSize: 12
                    tint: themeAccent; baseFg: themeFg
                    onActivated: activePlayer?.togglePlaying()
                }
                IconButton {
                    icon: "󰒭"
                    boxSize: root.btnSize; boxRadius: root.btnSize * 0.32; iconSize: 11
                    tint: themeAccent; baseFg: themeFg
                    onActivated: activePlayer?.next()
                }
            }
        }
    }
}
