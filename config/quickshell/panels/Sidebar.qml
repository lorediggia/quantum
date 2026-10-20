import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services
import qs.widgets

Item {
    id: sb
    readonly property var actions: ["wifi", "bluetooth", "audio", "notifications", "wallpapers", "stickers", "profile", "gamemode", "update", "settings"]

    ColumnLayout {
        anchors { fill: parent; margins: 24 }
        spacing: 26

        Column {
            SystemClock { id: clock; precision: SystemClock.Minutes }
            T { text: Qt.formatTime(clock.date, Cfg.bar.clock24 ? "hh:mm" : "h:mm"); font { pixelSize: 64; weight: Font.Thin; letterSpacing: -2 } }
            T { text: Qt.formatDate(clock.date, "dddd d MMMM").toLowerCase() + (Power.hasBattery ? "  ·  " + Power.pct : ""); color: Theme.fgA(0.45); font { pixelSize: 12; letterSpacing: 0.4 } }
        }

        ColumnLayout {
            spacing: 10
            Level {
                Layout.fillWidth: true
                implicitHeight: 52
                value: Audio.volume / Audio.max
                dimmed: Audio.muted
                icon: Audio.icon
                label: Audio.pct(Audio.volume)
                onMoved: v => Audio.setVolume(v * Audio.max)
                onSecondary: Audio.toggleMute()
            }
            Level {
                Layout.fillWidth: true
                implicitHeight: 52
                visible: Brightness.available
                value: Brightness.value
                icon: Brightness.icon
                label: Brightness.pct
                onMoved: v => Brightness.set(v)
            }
        }

        Grid {
            id: grid
            readonly property real cell: (sb.width - 48 - 4 * spacing) / 5
            columns: 5
            spacing: 12
            Repeater {
                model: sb.actions
                Btn {
                    required property string modelData
                    size: grid.cell
                    iconSize: 16
                    icon: Act.icon(modelData)
                    onClicked: Act.run(modelData, sb.width, sb.height)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: player.implicitHeight + 36
            visible: Media.player !== null
            radius: 22
            color: Theme.fgA(0.03)
            Player { id: player; anchors { fill: parent; margins: 18 } }
        }
        Item { Layout.fillHeight: true }
    }

    Repeater { model: Stickers.board; Sticker {} }
}
