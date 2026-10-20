pragma Singleton
import QtQuick
import Quickshell
import qs.core

Singleton {
    id: root
    readonly property var icons: Cfg.desktop.icons
    property bool editing: false
    property bool picking: false
    property var target: null

    onEditingChanged: if (!editing && Ui.open === "pin") Ui.close()
    Connections { target: Ui; function onOpenChanged() { if (Ui.open !== "pin") root.target = null } }

    function select(index, col, row) { editing = true; target = { index, col, row }; Ui.open = "pin" }
    function back() { Ui.open === "pin" ? Ui.close() : editing = !editing }
    function at(col, row) { return icons.findIndex(r => r.col === col && r.row === row) }

    function put(i, row) { const a = icons.slice(); i < 0 ? a.push(row) : a[i] = row; Cfg.desktop.icons = a }
    function drop(i) { Cfg.desktop.icons = icons.filter((_, j) => j !== i) }
    function move(i, col, row) {
        const a = icons.map(r => Object.assign({}, r)), j = at(col, row)
        if (j >= 0 && j !== i) Object.assign(a[j], { col: a[i].col, row: a[i].row })
        Object.assign(a[i], { col, row })
        Cfg.desktop.icons = a
    }

    function entry(id) { return id ? DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id) : null }
    function iconOf(r) { return r.icon || (r.app && !r.cmd ? entry(r.app)?.icon : "") || "󰆍" }
    function launch(r) { r.cmd ? Util.spawn("cd; " + r.cmd) : entry(r.app)?.execute() }
}
