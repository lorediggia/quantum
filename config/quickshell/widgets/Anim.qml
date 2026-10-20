import QtQuick
import qs.core

NumberAnimation {
    duration: Theme.msMorph
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.curveIn
}
