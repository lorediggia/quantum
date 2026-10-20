import QtQuick
import QtQuick.Layouts
import qs.core

Tile {
    id: lr
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool busy: false

    implicitHeight: 46
    radius: 12
    color: active ? Theme.accA(0.14) : hovered ? Theme.fgA(0.05) : "transparent"

    RowLayout {
        anchors { fill: parent; leftMargin: 8; rightMargin: 12 }
        spacing: 11
        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 10
            color: lr.active ? Theme.accA(0.2) : Theme.fgA(0.05)
            T {
                anchors.centerIn: parent
                text: lr.busy ? "󰑐" : lr.icon
                color: lr.active ? Theme.accent : Theme.fgA(0.5)
                font.pixelSize: 15
                RotationAnimation on rotation { running: lr.busy; loops: Animation.Infinite; from: 0; to: 360; duration: 900; onStopped: target.rotation = 0 }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            T { Layout.fillWidth: true; text: lr.title; color: Theme.fgA(lr.active ? 1 : 0.85); font.pixelSize: 12; elide: Text.ElideRight }
            T { Layout.fillWidth: true; visible: text !== ""; text: lr.subtitle; color: lr.active ? Theme.accA(0.75) : Theme.fgA(0.34); font.pixelSize: 9; elide: Text.ElideRight }
        }
    }
}
