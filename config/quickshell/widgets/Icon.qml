import QtQuick
import Quickshell.Widgets
import qs.core

Item {
    id: ic
    property string source: ""
    property real size: 48
    readonly property bool glyph: [...source].length === 1
    readonly property bool file: /^(\/|~|file:)/.test(source)

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        visible: ic.glyph
        radius: width * 0.28
        color: Theme.accA(0.16)
        T { anchors.centerIn: parent; text: ic.glyph ? ic.source : ""; color: Theme.accent; font.pixelSize: ic.size * 0.5 }
    }
    IconImage {
        anchors.fill: parent
        visible: !ic.glyph
        implicitSize: ic.size
        asynchronous: true
        source: ic.glyph || !ic.source ? "" : ic.file ? "file://" + Util.expand(ic.source.replace(/^file:\/\//, "")) : Util.iconUrl(ic.source)
    }
}
