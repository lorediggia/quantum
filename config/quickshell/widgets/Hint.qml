import QtQuick
import QtQuick.Layouts
import qs.core

T {
    property bool error: false
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    visible: text !== ""
    color: error ? Theme.danger : Theme.fgA(0.35)
    font.pixelSize: 11
    font.italic: !error
}
