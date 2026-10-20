import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core
import qs.services
import qs.widgets

Panel {
    id: lc
    readonly property var apps: Apps.search(search.text)
    function launch(i) { if (apps[i]) { apps[i].execute(); Ui.close() } }

    implicitWidth: 420
    implicitHeight: 430
    margin: 16
    spacing: 12
    Keys.onDownPressed: list.incrementCurrentIndex()
    Keys.onUpPressed: list.decrementCurrentIndex()

    Field {
        id: search
        Layout.fillWidth: true
        implicitHeight: 40
        hint: "󰍉"
        Component.onCompleted: grab()
        onTextChanged: list.currentIndex = 0
        onAccepted: lc.launch(list.currentIndex)
    }
    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: lc.apps
        highlightMoveDuration: 150
        highlightMoveVelocity: -1
        highlight: Rectangle { radius: 12; color: Theme.accA(0.13) }
        delegate: Tile {
            id: row
            required property var modelData
            required property int index
            width: ListView.view.width
            height: 46
            onHoveredChanged: if (hovered) list.currentIndex = index
            onClicked: lc.launch(index)
            IconImage { id: icon; x: 12; anchors.verticalCenter: parent.verticalCenter; implicitSize: 24; source: Util.iconUrl(row.modelData.icon) }
            T {
                anchors { left: icon.right; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                text: row.modelData.name
                color: Theme.fgA(row.ListView.isCurrentItem ? 1 : 0.7)
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }
}
