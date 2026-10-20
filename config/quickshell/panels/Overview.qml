import QtQuick
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.core
import qs.services
import qs.widgets

Flickable {
    id: ov
    readonly property var names: {
        const n = Array.from({ length: Cfg.bar.wsCount }, (_, i) => String(i + 1))
        return n.concat(Hyprland.workspaces.values.map(w => w.name).filter(w => !n.includes(w)))
    }
    readonly property real aspect: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.height / Hyprland.focusedMonitor.width : 9 / 16
    property Item dragged: null
    property Item target: null

    clip: true
    contentHeight: column.height + 32

    Component.onCompleted: Hyprland.refreshToplevels()
    Connections { target: Hyprland; function onRawEvent(e) { if (/window|float|fullscreen/.test(e.name)) refresh.restart() } }
    Timer { id: refresh; interval: 80; onTriggered: Hyprland.refreshToplevels() }

    Column {
        id: column
        x: 20
        y: 16
        width: ov.width - 40
        spacing: 12

        Repeater {
            model: ov.names
            Tile {
                id: plane
                required property string modelData
                readonly property string name: modelData
                readonly property var ws: Hyprland.workspaces.values.find(w => w.name === name) ?? null
                readonly property bool used: (ws?.toplevels.values.length ?? 0) > 0

                width: column.width
                height: used ? Math.round(width * ov.aspect) : 34
                z: ov.dragged?.parent === plane ? 1 : 0
                color: ov.target === plane ? Theme.accA(0.16) : hovered ? Theme.fgA(0.05) : Theme.fgA(0.025)
                Behavior on height { Anim {} }
                onClicked: { Hypr.workspace(name); Ui.close() }

                T {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Hypr.label(plane.name)
                    color: plane.ws?.focused ? Theme.accA(0.4) : Theme.fgA(0.16)
                    font { family: Cfg.bar.japanese ? Theme.jp : Theme.mono; pixelSize: plane.height * 0.6 }
                    fontSizeMode: Text.HorizontalFit
                    Behavior on color { CAnim {} }
                }

                Repeater {
                    model: plane.ws?.toplevels ?? []
                    Tile {
                        id: win
                        required property var modelData
                        readonly property var info: modelData.lastIpcObject
                        readonly property rect box: {
                            const m = modelData.monitor
                            if (!m || !info.at) return Qt.rect(0, 0, 0, 0)
                            const kx = plane.width * m.scale / m.width, ky = plane.height * m.scale / m.height
                            return Qt.rect((info.at[0] - m.x) * kx, (info.at[1] - m.y) * ky, info.size[0] * kx, info.size[1] * ky)
                        }

                        x: box.x + 2 + (drag.active ? drag.activeTranslation.x : 0)
                        y: box.y + 2 + (drag.active ? drag.activeTranslation.y : 0)
                        width: box.width - 4
                        height: box.height - 4
                        z: drag.active || info.floating ? 1 : 0
                        radius: 8
                        visible: box.width > 0
                        color: modelData.activated ? Theme.accA(0.3) : hovered ? Theme.accA(0.18) : Theme.fgA(0.12)
                        scale: drag.active ? 0.9 : 1
                        Behavior on x { enabled: !drag.active; Anim {} }
                        Behavior on y { enabled: !drag.active; Anim {} }
                        Behavior on width { Anim {} }
                        Behavior on height { Anim {} }
                        Behavior on scale { Anim {} }
                        onClicked: { Hypr.focus(info.address); Ui.close() }
                        onRightClicked: Hypr.close(info.address)

                        IconImage { anchors.centerIn: parent; implicitSize: Util.clamp(Math.min(win.width, win.height) * 0.4, 12, 28); source: Util.iconUrl(Apps.icon(win.info.class ?? "")) }
                        DragHandler {
                            id: drag
                            target: null
                            grabPermissions: PointerHandler.CanTakeOverFromAnything
                            onCentroidChanged: if (active) {
                                const p = column.mapFromItem(null, centroid.scenePosition)
                                ov.target = column.childAt(p.x, p.y)
                            }
                            onActiveChanged: {
                                if (active) return ov.dragged = win
                                if (ov.target && ov.target !== plane) Hypr.move(win.info.address, ov.target.name)
                                ov.dragged = ov.target = null
                            }
                        }
                    }
                }
            }
        }
    }
}
