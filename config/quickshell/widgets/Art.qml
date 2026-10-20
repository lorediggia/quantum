import QtQuick
import Quickshell.Widgets
import qs.core

ClippingRectangle {
    id: art
    property string url: ""

    radius: width * 0.28
    color: Theme.accA(0.2)

    T { anchors.centerIn: parent; visible: art.url === ""; text: "󰎇"; color: Theme.accent; font.pixelSize: art.width * 0.5 }
    Image { id: old; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; sourceSize: front.sourceSize }
    Image {
        id: front
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(160, 160)
        source: art.url
        onStatusChanged: if (status === Image.Ready) fade.restart()
        NumberAnimation { id: fade; target: front; property: "opacity"; from: 0; to: 1; duration: 500; onFinished: old.source = front.source }
    }
}
