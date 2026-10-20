import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import qs.widgets

Panel {
    Head {
        icon: Notifs.icon
        title: Cfg.dnd ? "do not disturb" : Notifs.count ? Notifs.count + " new" : "all clear"
        Btn { size: 30; icon: "󰂛"; active: Cfg.dnd; onClicked: Notifs.toggleDnd() }
        Btn { size: 30; icon: "󰩹"; visible: Notifs.count > 0; onClicked: Notifs.clear() }
    }
    ListView {
        Layout.fillWidth: true
        implicitHeight: Math.min(count, 5) * 64
        visible: count > 0
        clip: true
        model: Notifs.list
        delegate: Tile {
            id: row
            required property var modelData
            width: ListView.view.width
            height: 64
            color: hovered ? Theme.fgA(0.04) : "transparent"
            onClicked: Notifs.activate(modelData.id)

            RowLayout {
                anchors { fill: parent; leftMargin: 8; rightMargin: 4 }
                spacing: 12
                Icon { size: 30; source: Notifs.iconFor(row.modelData) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    T { Layout.fillWidth: true; text: row.modelData.summary || row.modelData.appName; font { pixelSize: 12; weight: Font.Medium } elide: Text.ElideRight }
                    T { Layout.fillWidth: true; visible: text !== ""; text: Notifs.plain(row.modelData.body); color: Theme.fgA(0.5); font.pixelSize: 10; maximumLineCount: 2; wrapMode: Text.WordWrap; elide: Text.ElideRight }
                }
                Btn { plain: true; size: 24; icon: "󰅖"; iconSize: 12; onClicked: row.modelData.dismiss() }
            }
        }
    }
}
