import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

ColumnLayout {
    spacing: 14

    RowLayout {
        spacing: 14
        Art { implicitWidth: 72; implicitHeight: 72; url: Media.art }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            T { Layout.fillWidth: true; text: Media.title || "Now playing"; font { pixelSize: 15; weight: Font.Medium } elide: Text.ElideRight }
            T { Layout.fillWidth: true; text: Media.artist; color: Theme.fgA(0.5); font.pixelSize: 11; elide: Text.ElideRight }
        }
    }
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 18
        Btn { icon: "󰒮"; size: 38; iconSize: 18; onClicked: Media.prev() }
        Btn { icon: Media.playing ? "󰏤" : "󰐊"; size: 48; iconSize: 20; onClicked: Media.toggle() }
        Btn { icon: "󰒭"; size: 38; iconSize: 18; onClicked: Media.next() }
    }
}
