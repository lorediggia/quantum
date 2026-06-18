import QtQuick

Item {
    id: root

    property var   player
    property bool  playing: false
    property color fg:     "#ffffff"
    property color accent: "#ffffff"

    property real trackHeight:    4
    property real thumbSize:      11
    property real haloSize:       22
    property int  updateInterval: 500

    implicitHeight: haloSize

    property bool isDragging:  false
    property real dragProgress: 0
    property real currentPos: player ? player.position : 0

    readonly property bool hovered: mouse.containsMouse || isDragging
    readonly property real progress: {
        if (isDragging) return dragProgress
        if (!player || player.length <= 0) return 0
        return Math.max(0.0, Math.min(1.0, currentPos / player.length))
    }
    readonly property real thumbX: track.width * progress

    Timer {
        interval: root.updateInterval; repeat: true
        running: root.playing && root.visible && !root.isDragging
        onTriggered: if (root.player) root.currentPos = root.player.position
    }

    Connections {
        target: root.player
        enabled: root.player !== null && root.player !== undefined
        function onTrackTitleChanged() { root.currentPos = 0 }
    }

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: root.trackHeight
        radius: height / 2
        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, root.hovered ? 0.18 : 0.10)
        Behavior on color { ColorAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Rectangle {
            width: parent.width * root.progress
            height: parent.height
            radius: parent.radius
            color: root.accent
            Behavior on width {
                enabled: !root.isDragging
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }
        }
    }

    Rectangle {
        x: root.thumbX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: root.haloSize; height: width; radius: width / 2
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
        opacity: root.hovered ? 1 : 0
        scale:   root.hovered ? 1 : 0.3
        Behavior on opacity { NumberAnimation { duration: 260 } }
        Behavior on scale   { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
        Behavior on x {
            enabled: !root.isDragging
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        x: root.thumbX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: root.thumbSize; height: width; radius: width / 2
        color: root.accent
        opacity: root.hovered ? 1 : 0
        scale: mouse.pressed ? 0.85 : (root.hovered ? 1 : 0.3)
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
        Behavior on x {
            enabled: !root.isDragging
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function upd(mx) { root.dragProgress = Math.max(0.0, Math.min(1.0, mx / width)) }
        onPressed:         (m) => { root.isDragging = true; upd(m.x) }
        onPositionChanged: (m) => { if (root.isDragging) upd(m.x) }
        onReleased: (m) => {
            if (!root.isDragging) return
            upd(m.x)
            if (root.player && root.player.length > 0) {
                const t = root.dragProgress * root.player.length
                root.player.position = t
                root.currentPos = t
            }
            root.isDragging = false
        }
    }
}
