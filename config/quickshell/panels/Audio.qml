import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import qs.widgets

Panel {
    Head { icon: Audio.icon; title: Audio.sink ? Audio.name(Audio.sink) : "no output" }

    Level {
        Layout.fillWidth: true
        value: Audio.volume / Audio.max
        dimmed: Audio.muted
        icon: Audio.icon
        label: Audio.muted ? "󰖁" : Audio.pct(Audio.volume)
        onMoved: v => Audio.setVolume(v * Audio.max)
        onSecondary: Audio.toggleMute()
    }
    Level {
        Layout.fillWidth: true
        value: Audio.micVolume
        dimmed: Audio.micMuted
        icon: Audio.micIcon
        label: Audio.micMuted ? "󰍭" : Audio.pct(Audio.micVolume)
        onMoved: v => Audio.setMic(v)
        onSecondary: Audio.toggleMic()
    }

    Caption { text: "Apps"; visible: Audio.streams.length > 0 }
    Repeater {
        model: Audio.streams
        Level {
            required property var modelData
            readonly property var a: modelData.audio
            Layout.fillWidth: true
            implicitHeight: 36
            value: a.volume
            dimmed: a.muted
            icon: "󰎇"
            label: modelData.properties["application.name"] ?? Audio.name(modelData)
            onMoved: v => a.volume = v
            onSecondary: a.muted = !a.muted
        }
    }

    Repeater {
        model: [{ title: "Output", list: Audio.sinks, current: Audio.sink, icon: "󰓃" },
                { title: "Input", list: Audio.sources, current: Audio.source, icon: "󰍬" }]
        ColumnLayout {
            id: group
            required property var modelData
            visible: modelData.list.length > 1
            spacing: 4
            Caption { text: group.modelData.title }
            Repeater {
                model: group.modelData.list
                ListRow {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: -8
                    Layout.rightMargin: -8
                    icon: group.modelData.icon
                    title: Audio.name(modelData)
                    active: modelData === group.modelData.current
                    onClicked: Audio.setDefault(modelData)
                }
            }
        }
    }
}
