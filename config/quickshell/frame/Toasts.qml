import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import qs.widgets

ListView {
    height: 4 * 66
    interactive: false
    model: Notifs.toasts

    add: Transition {
        Anim { property: "opacity"; from: 0; to: 1; duration: Theme.msIn }
        Anim { property: "height"; from: 0; duration: Theme.msIn }
    }
    remove: Transition {
        Anim { property: "opacity"; to: 0; duration: Theme.msOut; easing.bezierCurve: Theme.curveOut }
        Anim { property: "height"; to: 0; duration: Theme.msOut; easing.bezierCurve: Theme.curveOut }
    }
    displaced: Transition { Anim { property: "y" } }

    delegate: Tile {
        id: toast
        required property int index
        required property int nid
        required property string summary
        required property string body
        required property string icon
        width: ListView.view.width
        height: 66
        radius: 0
        clip: true
        onClicked: Notifs.activate(nid)

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 12; topMargin: 11; bottomMargin: 11 }
            spacing: 11
            Icon { Layout.alignment: Qt.AlignTop; size: 22; source: toast.icon }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                T { Layout.fillWidth: true; text: toast.summary; font { pixelSize: 11; weight: Font.Medium } elide: Text.ElideRight }
                T { Layout.fillWidth: true; text: toast.body; color: Theme.fgA(0.5); font.pixelSize: 10; maximumLineCount: 2; wrapMode: Text.WordWrap; elide: Text.ElideRight }
            }
        }
        Rectangle { visible: toast.index > 0; width: parent.width; height: 1; color: Theme.fgA(0.06) }
    }
}
