import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: head
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    default property alias trailing: trail.data

    Layout.fillWidth: true
    spacing: 11

    Rectangle {
        implicitWidth: 34
        implicitHeight: 34
        radius: 12
        color: Theme.accA(0.14)
        T { anchors.centerIn: parent; text: head.icon; color: Theme.accent; font.pixelSize: 16 }
    }
    T { Layout.fillWidth: true; text: head.subtitle || head.title; color: Theme.fgA(0.85); font { pixelSize: 13; weight: Font.Medium; letterSpacing: 0.3 } elide: Text.ElideRight }
    RowLayout { id: trail; Layout.fillWidth: false; spacing: 8 }
}
