pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property var list: [...DesktopEntries.applications.values].sort((a, b) => a.name.localeCompare(b.name))

    function search(q) {
        q = q.toLowerCase()
        const at = a => a.name.toLowerCase().indexOf(q)
        return q ? list.filter(a => at(a) >= 0).sort((a, b) => at(a) - at(b)) : list
    }
    function icon(cls) { return DesktopEntries.heuristicLookup(cls)?.icon || cls }
    function name(cls) { return DesktopEntries.heuristicLookup(cls)?.name || cls }
}
