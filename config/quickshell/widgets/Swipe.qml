import QtQuick

DragHandler {
    signal gone()
    yAxis.enabled: false
    onActiveChanged: if (!active) Math.abs(target.x) > target.width / 3 ? gone() : target.x = 0
}
