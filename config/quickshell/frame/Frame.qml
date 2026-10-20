import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services
import qs.widgets

PanelWindow {
    id: frame
    readonly property real barH: Cfg.look.barH
    readonly property real edge: Cfg.look.edge
    readonly property real rad: Cfg.look.rad
    readonly property real drawerY: barH + 70
    readonly property real drawerH: height - edge - 70 - drawerY

    WlrLayershell.namespace: "quickshell-frame"
    WlrLayershell.layer: raised.p > 0 || Notifs.urgent ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: Desktop.picking ? WlrKeyboardFocus.None : panels.open || wallpapers.open ? WlrKeyboardFocus.Exclusive : Ui.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    mask: Region {
        width: frame.width; height: frame.barH
        Region { y: frame.height - frame.edge; width: frame.width; height: frame.edge }
        Region { width: frame.edge; height: frame.height }
        Region { x: frame.width - frame.edge; width: frame.edge; height: frame.height }
        Region { item: panels }
        Region { item: status }
        Region { item: wallpapers }
        Region { item: overview }
        Region { item: sidebar }
    }

    Reveal { id: raised; open: Ui.open !== "" }
    IdleInhibitor { window: frame; enabled: Caffeine.active }
    Shortcut { sequence: "Escape"; enabled: Ui.open !== ""; onActivated: Ui.close() }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: Theme.bg
            strokeColor: "transparent"
            PathLine { x: 0; y: frame.height }
            PathLine { x: frame.width; y: frame.height }
            PathLine { x: frame.width; y: 0 }
            PathLine { x: 0; y: 0 }
            PathRectangle {
                x: frame.edge; y: frame.barH
                width: frame.width - 2 * frame.edge; height: frame.height - frame.barH - frame.edge
                radius: frame.rad
            }
        }
    }

    Bar { id: bar; width: frame.width; height: frame.barH }

    Panels {
        id: panels
        names: ["launcher", "audio", "wifi", "bluetooth", "notifications", "power"]
        readonly property real size: bodyW || w
        readonly property real pill: last === "launcher" ? -1 : bar.pillX(last)
        readonly property real want: (pill < 0 ? frame.width / 2 : pill) - size / 2 - frame.rad
        readonly property real docked: frame.width - frame.edge - frame.rad - size
        flush: want > docked - 2 * frame.rad
        x: flush ? docked : Math.max(want, frame.edge + frame.rad)
        y: frame.barH
        Behavior on x { enabled: panels.p > 0; Anim {} }
    }
    Notch {
        id: status
        property bool osd: false
        Binding on osd { when: status.open; value: Ui.osd !== ""; restoreMode: Binding.RestoreNone }
        open: (Ui.osd !== "" || Notifs.toasts.count > 0) && !panels.open
        bodyW: osd ? 200 : 320
        bodyH: osd ? 50 : toasts.contentHeight
        x: (frame.width - width) / 2
        y: frame.barH

        Toasts { id: toasts; width: 320; visible: opacity > 0; opacity: status.osd ? 0 : 1; Behavior on opacity { NumberAnimation { duration: 200 } } }
        Osd { anchors.fill: parent; visible: opacity > 0; opacity: status.osd ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 200 } } }
    }
    Panels {
        id: wallpapers
        edge: "bottom"
        names: ["wallpapers", "pin"]
        x: (frame.width - width) / 2
        y: frame.height - frame.edge - height
    }

    Panels {
        id: overview
        edge: "left"
        names: ["overview"]
        dismiss: false
        bodyW: Cfg.look.drawerW
        bodyH: frame.drawerH
        x: frame.edge
        y: frame.drawerY - frame.rad
    }
    Panels {
        id: sidebar
        edge: "right"
        names: ["sidebar", "settings"]
        dismiss: false
        bodyW: Cfg.look.drawerW
        bodyH: frame.drawerH
        x: frame.width - frame.edge - width
        y: frame.drawerY - frame.rad
    }
}
