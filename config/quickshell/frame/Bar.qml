import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.core
import qs.services
import qs.widgets

Item {
    id: bar
    readonly property var opt: Cfg.bar
    readonly property real pill: Math.min(26, height - 8)

    Row {
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 18

        Row {
            id: spaces
            visible: bar.opt.wsCount > 0
            spacing: 8
            Repeater {
                model: bar.opt.wsCount
                Tile {
                    id: ws
                    required property int index
                    readonly property bool focused: Hyprland.focusedWorkspace?.id === index + 1
                    width: bar.pill
                    height: bar.pill
                    opacity: Hyprland.workspaces.values.some(w => w.id === index + 1) ? 1 : 0.3
                    Behavior on opacity { NumberAnimation { duration: 240 } }
                    onClicked: Hypr.workspace(index + 1)
                    T {
                        anchors.centerIn: parent
                        text: Hypr.label(ws.index + 1)
                        color: ws.focused ? Theme.fg : ws.hovered ? Theme.accent : Theme.fgA(0.6)
                        font { family: bar.opt.japanese ? Theme.jp : Theme.mono; pixelSize: 15; weight: ws.focused ? Font.Bold : Font.Medium }
                        scale: ws.pressed ? 0.85 : ws.focused ? 1.1 : 1
                        Behavior on color { CAnim {} }
                        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                    }
                }
            }
        }
        T {
            readonly property string app: ToplevelManager.activeToplevel?.appId ?? ""
            visible: bar.opt.appName
            anchors.verticalCenter: parent.verticalCenter
            text: app ? Apps.name(app) : "󰋜"
            color: app ? Theme.fgA(0.55) : Theme.accent
            font { pixelSize: app ? 12 : 16; weight: Font.Medium; letterSpacing: 0.4 }
        }
    }

    Row {
        id: center
        anchors.centerIn: parent
        spacing: 12
        SystemClock { id: clock; precision: bar.opt.seconds ? SystemClock.Seconds : SystemClock.Minutes }
        T {
            id: time
            text: Qt.formatTime(clock.date, (bar.opt.clock24 ? "hh:mm" : "h:mm AP") + (bar.opt.seconds ? ":ss" : ""))
            font { pixelSize: 17; weight: Font.Medium; letterSpacing: 1 }
        }
        T {
            visible: bar.opt.date
            anchors.baseline: time.baseline
            text: Qt.formatDate(clock.date, "ddd d MMM").toUpperCase()
            color: Theme.fgA(0.45)
            font { pixelSize: 11; weight: Font.Medium; letterSpacing: 0.8 }
        }
    }

    function pillX(name) {
        const pill = Array.from(pills.children).find(p => p.modelData === name)
        return pill ? pill.mapToItem(null, pill.width / 2, 0).x : -1
    }

    Track {
        anchors { right: tray.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
        height: bar.pill
        room: Math.min(320, tray.x - 10 - (bar.width + center.width) / 2 - 24)
    }

    Item {
        id: tray
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        width: pills.width
        height: bar.pill
        Row {
            id: pills
            spacing: 6
            Repeater {
                model: bar.opt.buttons
                Btn {
                    id: pill
                    required property string modelData
                    plain: true
                    size: bar.pill
                    icon: Act.icon(modelData)
                    label: modelData === "power" ? Power.pct : ""
                    active: Ui.open === modelData
                    lit: modelData === "caffeine" && Caffeine.active
                    onClicked: Act.run(modelData)
                    Rectangle {
                        visible: pill.modelData === "notifications" && Notifs.count > 0 && !Cfg.dnd
                        anchors { top: parent.top; right: parent.right; margins: 4 }
                        width: 5; height: 5; radius: 2.5
                        color: Theme.accent
                    }
                }
            }
        }
    }
}
