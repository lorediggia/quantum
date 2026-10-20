import QtQuick
import qs.core
import qs.services
import qs.widgets

Item {
    id: osd
    property string kind: ""
    Binding on kind { when: Ui.osd !== ""; value: Ui.osd; restoreMode: Binding.RestoreNone }

    T {
        id: icon
        anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
        text: osd.kind === "brightness" ? Brightness.icon : osd.kind === "mic" ? Audio.micIcon : Audio.icon
        color: Theme.accent
        font.pixelSize: 13
    }
    Rectangle {
        anchors { left: icon.right; leftMargin: 14; right: pct.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
        height: 4
        radius: 2
        color: Theme.fgA(0.12)
        Rectangle {
            width: parent.width * Ui.osdValue
            height: parent.height
            radius: 2
            color: Theme.accent
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
    }
    T {
        id: pct
        anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
        text: Math.round(Ui.osdValue * (osd.kind === "volume" ? Audio.max : 1) * 100) + "%"
        color: Theme.fgA(0.55)
        font { pixelSize: 12; weight: Font.Medium }
    }
}
