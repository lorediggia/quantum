import QtQuick
import qs.core
import qs.services
import qs.widgets

Tile {
    id: tr
    property real room: 300
    visible: Cfg.bar.media && Media.title !== "" && room > 80
    width: art.width + title.width + 20
    radius: height * 0.36
    onClicked: once.running ? (once.stop(), Media.next()) : once.start()
    onRightClicked: Ui.toggle("sidebar")
    Timer { id: once; interval: 230; onTriggered: Media.toggle() }

    Art { id: art; x: 3; anchors.verticalCenter: parent.verticalCenter; width: tr.height - 6; height: width; url: Media.art }
    T {
        id: title
        anchors { left: art.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
        width: Math.min(implicitWidth, tr.room - tr.height - 20)
        text: Media.title
        elide: Text.ElideRight
        opacity: Media.playing ? 1 : 0.5
        font { pixelSize: 12; weight: Font.Medium }
    }
}
