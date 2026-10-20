import QtQuick
import QtQuick.Layouts

Item {
    id: p
    default property alias content: col.data
    property alias spacing: col.spacing
    property real margin: 20

    implicitWidth: 340
    implicitHeight: col.implicitHeight + 2 * margin

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: p.margin }
        spacing: 14
    }
}
