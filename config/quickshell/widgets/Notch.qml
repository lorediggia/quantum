import QtQuick
import QtQuick.Shapes
import qs.core

Item {
    id: n
    property string edge: "top"
    property bool open: false
    property real bodyW: 0
    property real bodyH: 0
    property bool flush: false
    default property alias content: body.data
    readonly property alias p: reveal.p

    readonly property bool flat: edge === "top" || edge === "bottom"
    readonly property real r: Cfg.look.rad
    readonly property real along: (flat ? w : h) + (flush ? 1 : 2) * r
    readonly property real depth: (flat ? h : w) * p

    property real w: 0
    property real h: 0
    Binding on w { when: n.open && n.bodyW > 0; value: n.bodyW; restoreMode: Binding.RestoreNone }
    Binding on h { when: n.open && n.bodyH > 0; value: n.bodyH; restoreMode: Binding.RestoreNone }
    Behavior on w { enabled: n.p > 0; Anim {} }
    Behavior on h { enabled: n.p > 0; Anim {} }
    Reveal { id: reveal; open: n.open }

    width: flat ? along : depth
    height: flat ? depth : along
    visible: depth > 0

    Shape {
        id: shape
        readonly property real len: n.along
        readonly property real d: n.depth
        readonly property real r: n.r
        readonly property bool deep: d >= 2 * r
        readonly property real fx: deep ? 0 : 2 * r - Math.sqrt(d * (4 * r - d))
        readonly property real tx: deep ? r : r + fx / 2
        readonly property real ty: deep ? r : d / 2
        readonly property real side: Math.max(ty, d - r)
        readonly property real farFx: n.flush ? 0 : fx
        readonly property real farTx: n.flush ? 0 : tx
        preferredRendererType: Shape.CurveRenderer
        transform: Matrix4x4 {
            matrix: n.edge === "top"    ? Qt.matrix4x4(1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1)
                  : n.edge === "bottom" ? Qt.matrix4x4(1, 0, 0, 0,  0, -1, 0, shape.d,  0, 0, 1, 0,  0, 0, 0, 1)
                  : n.edge === "left"   ? Qt.matrix4x4(0, 1, 0, 0,  1, 0, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1)
                  :                       Qt.matrix4x4(0, -1, 0, shape.d,  1, 0, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1)
        }
        ShapePath {
            fillColor: Theme.bg
            strokeColor: "transparent"
            startX: shape.fx; startY: -1
            PathLine { x: shape.fx; y: 0 }
            PathArc  { x: shape.tx; y: shape.ty; radiusX: shape.r; radiusY: shape.r }
            PathLine { x: shape.tx; y: shape.side }
            PathArc  { x: 2 * shape.r; y: shape.d; radiusX: shape.r; radiusY: shape.r; direction: PathArc.Counterclockwise }
            PathLine { x: shape.len - (n.flush ? 1 : 2) * shape.r; y: shape.d }
            PathArc  { x: shape.len - shape.farTx; y: n.flush ? shape.d + shape.r : shape.side; radiusX: shape.r; radiusY: shape.r
                       direction: n.flush ? PathArc.Clockwise : PathArc.Counterclockwise }
            PathLine { x: shape.len - shape.farTx; y: n.flush ? -1 : shape.ty }
            PathArc  { x: shape.len - shape.farFx; y: n.flush ? -1 : 0; radiusX: shape.r; radiusY: shape.r }
            PathLine { x: shape.len - shape.farFx; y: -1 }
        }
    }

    Item {
        clip: true
        x: n.flat ? n.r : 0
        y: n.flat ? 0 : n.r
        width: n.flat ? n.w : n.depth
        height: n.flat ? n.depth : n.h
        Item {
            id: body
            x: n.edge === "left" ? parent.width - width : 0
            y: n.edge === "top" ? parent.height - height : 0
            width: n.w
            height: n.h
            opacity: reveal.alpha
        }
    }
}
