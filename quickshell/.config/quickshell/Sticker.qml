import QtQuick

Item {
    id: stickerRoot

    property string imgSrc
    property real   posX
    property real   posY
    property real   baseRot
    property int    stickerZ
    property real   stickerScale: 1.0
    property bool   isNew:   false
    property int    modelIndex

    readonly property real playgroundWidth:  parent ? parent.width  : 0
    readonly property real playgroundHeight: parent ? parent.height : 0
    readonly property bool playgroundReady:  playgroundWidth > 0 && playgroundHeight > 0

    signal requireSave()
    signal requireDestroy(int idx)
    signal requireZUpdate(int idx)
    signal updatePosition(int idx, real newX, real newY)
    signal updateScaleAndSave(int idx, string path, real newScale)
    signal updateRotation(int idx, real newRot)
    signal updateIsNew(int idx, bool val)

    readonly property real maxSize: 120
    readonly property real naturalW: stickerImage.implicitWidth  > 0 ? stickerImage.implicitWidth  : maxSize
    readonly property real naturalH: stickerImage.implicitHeight > 0 ? stickerImage.implicitHeight : maxSize
    readonly property real capScale: Math.min(1.0, maxSize / Math.max(naturalW, naturalH))

    width:  naturalW * capScale * stickerScale
    height: naturalH * capScale * stickerScale
    x: posX; y: posY; z: stickerZ
    rotation: baseRot + idleWobble

    opacity: isNew ? 0   : 1
    scale:   isNew ? 0.4 : 1.0

    property real tiltX: 0
    property real tiltY: 0
    property real idleWobble: 0

    property real velX: 0
    property real velY: 0
    property real lastDragX: 0
    property real lastDragY: 0
    property real lastDragTime: 0

    readonly property bool isHovered: stickerMouse.containsMouse
    readonly property bool isPressed: stickerMouse.pressed

    ParallelAnimation {
        id: spawnAnim
        NumberAnimation { target: stickerRoot; property: "opacity"; to: 1;   duration: 260; easing.type: Easing.OutCubic }
        NumberAnimation { target: stickerRoot; property: "scale";   to: 1.0; duration: 520; easing.type: Easing.OutBack  }
        onFinished: { if (isNew) updateIsNew(modelIndex, false) }
    }

    SequentialAnimation {
        id: destroyAnim
        ParallelAnimation {
            NumberAnimation { target: stickerRoot; property: "scale";   to: 0.6; duration: 160; easing.type: Easing.OutQuad }
            NumberAnimation { target: stickerRoot; property: "opacity"; to: 0;   duration: 160; easing.type: Easing.OutQuad }
        }
        ScriptAction { script: requireDestroy(modelIndex) }
    }

    SequentialAnimation on idleWobble {
        running: stickerRoot.isHovered && !stickerRoot.isPressed && !inertiaAnim.running
        loops: Animation.Infinite
        alwaysRunToEnd: false
        NumberAnimation { to:  1.2; duration: 1600; easing.type: Easing.InOutSine }
        NumberAnimation { to: -1.2; duration: 1600; easing.type: Easing.InOutSine }
    }
    Behavior on idleWobble { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    FrameAnimation {
        id: inertiaAnim
        running: false
        readonly property real friction:      0.93
        readonly property real bounce:        0.45
        readonly property real stopThreshold: 0.18
        onTriggered: {
            if (!playgroundReady) return

            stickerRoot.x += stickerRoot.velX
            stickerRoot.y += stickerRoot.velY
            stickerRoot.velX *= friction
            stickerRoot.velY *= friction

            const vm = 30
            const minX = -stickerRoot.width  + vm
            const maxX =  playgroundWidth    - vm
            const minY = -stickerRoot.height + vm
            const maxY =  playgroundHeight   - vm

            if (stickerRoot.x < minX) { stickerRoot.x = minX; stickerRoot.velX = -stickerRoot.velX * bounce }
            else if (stickerRoot.x > maxX) { stickerRoot.x = maxX; stickerRoot.velX = -stickerRoot.velX * bounce }
            if (stickerRoot.y < minY) { stickerRoot.y = minY; stickerRoot.velY = -stickerRoot.velY * bounce }
            else if (stickerRoot.y > maxY) { stickerRoot.y = maxY; stickerRoot.velY = -stickerRoot.velY * bounce }

            if (Math.abs(stickerRoot.velX) < stopThreshold && Math.abs(stickerRoot.velY) < stopThreshold) {
                stickerRoot.velX = 0; stickerRoot.velY = 0; running = false
                updatePosition(modelIndex, stickerRoot.x, stickerRoot.y)
                requireSave()
            }
        }
    }

    FrameAnimation {
        id: tiltApply
        running: false
        property real pendingX: 0
        property real pendingY: 0
        onTriggered: {
            stickerRoot.tiltX = pendingX
            stickerRoot.tiltY = pendingY
            running = false
        }
    }
    MouseArea {
        id: stickerMouse
        anchors.fill: parent
        anchors.margins: -20
        hoverEnabled: true
        enabled: stickerImage.status === Image.Ready
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        drag.target: stickerRoot
        drag.smoothed: false

        onEntered: stickerRoot.forceActiveFocus()

        onPositionChanged: (mouse) => {
            const actualX = mouse.x - 20, actualY = mouse.y - 20
            const normX = Math.max(-1, Math.min(1, (actualX - width  / 2) / (width  / 2)))
            const normY = Math.max(-1, Math.min(1, (actualY - height / 2) / (height / 2)))
            tiltApply.pendingX = -normY * 20
            tiltApply.pendingY =  normX * 20
            if (!tiltApply.running) tiltApply.running = true

            if (drag.active) {
                const now = Date.now()
                const dt  = Math.max(1, now - stickerRoot.lastDragTime)
                stickerRoot.velX = stickerRoot.velX * 0.3 + ((stickerRoot.x - stickerRoot.lastDragX) * 16 / dt) * 0.7
                stickerRoot.velY = stickerRoot.velY * 0.3 + ((stickerRoot.y - stickerRoot.lastDragY) * 16 / dt) * 0.7
                stickerRoot.lastDragX = stickerRoot.x
                stickerRoot.lastDragY = stickerRoot.y
                stickerRoot.lastDragTime = now
            }
        }

        onExited: { stickerRoot.tiltX = 0; stickerRoot.tiltY = 0 }

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) { destroyAnim.start(); return }
            requireZUpdate(modelIndex)
            stickerRoot.velX = 0; stickerRoot.velY = 0
            stickerRoot.lastDragX = stickerRoot.x
            stickerRoot.lastDragY = stickerRoot.y
            stickerRoot.lastDragTime = Date.now()
            inertiaAnim.running = false
        }

        onReleased: (mouse) => {
            if (mouse.button !== Qt.LeftButton) return
            const speed = Math.hypot(stickerRoot.velX, stickerRoot.velY)
            if (speed > 0.6) {
                const maxV = 35
                if (speed > maxV) {
                    const f = maxV / speed
                    stickerRoot.velX *= f
                    stickerRoot.velY *= f
                }
                inertiaAnim.running = true
            } else {
                updatePosition(modelIndex, stickerRoot.x, stickerRoot.y)
                requireSave()
            }
        }

        onWheel: (wheel) => {
            if (wheel.modifiers & Qt.ControlModifier) {
                const delta = wheel.angleDelta.y > 0 ? 0.1 : -0.1
                const newScale = Math.max(0.3, Math.min(3.0, stickerRoot.stickerScale + delta))
                updateScaleAndSave(modelIndex, imgSrc.replace("file://", ""), newScale)
            } else {
                updateRotation(modelIndex, baseRot + (wheel.angleDelta.y > 0 ? 12 : -12))
            }
            requireSave()
        }
    }

    Item {
        id: visualTarget
        anchors.centerIn: parent
        width:  parent.width
        height: parent.height

        scale: stickerRoot.isPressed ? 1.14 : (stickerRoot.isHovered ? 1.06 : 1.0)
        Behavior on scale { SpringAnimation { spring: 4.5; damping: 0.32; mass: 0.7 } }

        transform: [
            Rotation {
                axis { x: 1; y: 0; z: 0 }
                origin { x: visualTarget.width / 2; y: visualTarget.height / 2 }
                angle: stickerRoot.tiltX
                Behavior on angle { SpringAnimation { spring: 3.2; damping: 0.42; mass: 0.5 } }
            },
            Rotation {
                axis { x: 0; y: 1; z: 0 }
                origin { x: visualTarget.width / 2; y: visualTarget.height / 2 }
                angle: stickerRoot.tiltY
                Behavior on angle { SpringAnimation { spring: 3.2; damping: 0.42; mass: 0.5 } }
            }
        ]

        Image {
            id: stickerImage
            anchors.fill: parent
            source: imgSrc
            fillMode: Image.Stretch
            asynchronous: true
            smooth: true
            mipmap: true
            cache:  true
            sourceSize: Qt.size(512, 512)

            onStatusChanged: {
                if (status === Image.Ready && isNew && !spawnAnim.running) spawnAnim.start()
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) destroyAnim.start()
    }
}
