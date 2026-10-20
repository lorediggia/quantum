import QtQuick
import qs.core

QtObject {
    id: reveal
    property bool open: false
    property real p: open ? 1 : 0
    readonly property real alpha: Util.clamp((p - 0.12) / 0.45, 0, 1)
    Behavior on p {
        Anim {
            duration: reveal.open ? Theme.msIn : Theme.msOut
            easing.bezierCurve: reveal.open ? Theme.curveIn : Theme.curveOut
        }
    }
}
