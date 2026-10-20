import QtQuick
import QtQuick.Window
import qs.core
import qs.services

Item {
    id: st
    required property int index
    required property string src
    required property real px
    required property real py
    required property int pz
    required property real rot
    required property real size
    required property bool fresh

    x: px
    y: py
    z: pz
    width: face.implicitWidth / Screen.devicePixelRatio * size
    height: face.implicitHeight / Screen.devicePixelRatio * size
    rotation: rot
    opacity: fresh ? 0 : 1

    property point tilt
    property point vel
    property point last
    property real lastT: 0
    function save() { Stickers.set(index, { px: Math.round(x), py: Math.round(y) }) }

    ParallelAnimation {
        id: land
        NumberAnimation { target: st; property: "opacity"; to: 1; duration: 260 }
        NumberAnimation { target: face; property: "scale"; from: 0.4; to: 1; duration: 520; easing.type: Easing.OutBack }
        onFinished: Stickers.set(st.index, { fresh: false })
    }
    SequentialAnimation {
        id: peel
        ParallelAnimation {
            NumberAnimation { target: face; property: "scale"; to: 0.6; duration: 160 }
            NumberAnimation { target: st; property: "opacity"; to: 0; duration: 160 }
        }
        ScriptAction { script: Stickers.drop(st.index) }
    }

    FrameAnimation {
        id: glide
        onTriggered: {
            const maxX = st.parent.width - 30, maxY = st.parent.height - 30, minX = 30 - st.width, minY = 30 - st.height
            let vx = st.vel.x * 0.93, vy = st.vel.y * 0.93
            st.x += vx; st.y += vy
            if (st.x < minX || st.x > maxX) { st.x = Util.clamp(st.x, minX, maxX); vx *= -0.45 }
            if (st.y < minY || st.y > maxY) { st.y = Util.clamp(st.y, minY, maxY); vy *= -0.45 }
            st.vel = Qt.point(vx, vy)
            if (Math.hypot(vx, vy) < 0.25) { stop(); st.save() }
        }
    }

    Image {
        id: face
        anchors.fill: parent
        source: st.src
        asynchronous: true
        scale: ma.pressed ? 1.14 : ma.containsMouse ? 1.06 : 1
        Behavior on scale { enabled: !land.running && !peel.running; NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        transform: [
            Rotation { origin { x: face.width / 2; y: face.height / 2 } axis { x: 1; y: 0; z: 0 } angle: st.tilt.y; Behavior on angle { NumberAnimation { duration: 180 } } },
            Rotation { origin { x: face.width / 2; y: face.height / 2 } axis { x: 0; y: 1; z: 0 } angle: st.tilt.x; Behavior on angle { NumberAnimation { duration: 180 } } }
        ]
        onStatusChanged: if (status === Image.Ready && st.fresh) land.start()
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        drag { target: st; smoothed: false }

        onPositionChanged: m => {
            st.tilt = Qt.point((m.x / width - 0.5) * 40, (0.5 - m.y / height) * 40)
            if (!drag.active) return
            const now = Date.now(), k = 16 / Math.max(1, now - st.lastT)
            st.vel = Qt.point(st.vel.x * 0.3 + (st.x - st.last.x) * k * 0.7, st.vel.y * 0.3 + (st.y - st.last.y) * k * 0.7)
            st.last = Qt.point(st.x, st.y)
            st.lastT = now
        }
        onExited: st.tilt = Qt.point(0, 0)
        onPressed: m => {
            if (m.button === Qt.RightButton) return peel.start()
            glide.stop()
            Stickers.raise(st.index)
            st.vel = Qt.point(0, 0)
            st.last = Qt.point(st.x, st.y)
            st.lastT = Date.now()
        }
        onReleased: {
            const speed = Math.hypot(st.vel.x, st.vel.y), cap = Math.min(1, 35 / speed)
            st.vel = Qt.point(st.vel.x * cap, st.vel.y * cap)
            speed > 0.6 ? glide.start() : st.save()
        }
        onWheel: w => {
            const dir = Math.sign(w.angleDelta.y)
            if (w.modifiers & Qt.ControlModifier) Stickers.set(st.index, { size: Util.clamp(st.size + dir * 0.1, 0.3, 3) })
            else Stickers.set(st.index, { rot: st.rot + dir * 12 })
        }
    }
}
