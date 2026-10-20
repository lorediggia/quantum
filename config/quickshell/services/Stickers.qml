pragma Singleton
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root

    readonly property string dir: Cfg.dotfiles + "/local/stickers"
    readonly property var packs: Array.from({ length: folders.count }, (_, i) => folders.get(i, "fileName"))
    readonly property ListModel board: ListModel {}

    function rows() {
        return Array.from({ length: board.count }, (_, i) => { const { src, px, py, pz, rot, size } = board.get(i); return { src, px, py, pz, rot, size } })
    }
    function top() { return Math.max(0, ...rows().map(r => r.pz)) }
    function set(i, row) { for (const k in row) board.setProperty(i, k, row[k]); save.restart() }
    function drop(i) { board.remove(i); save.restart() }
    function raise(i) { set(i, { pz: top() + 1 }) }

    function add(w, h) {
        Util.run(`find ${Util.quote(dir + "/" + Cfg.pack)} -type f -not -path '*/logo/*' -iregex '.*\\.\\(png\\|jpe?g\\|webp\\|gif\\)' | shuf -n1`, out => {
            if (!out.trim()) return
            board.append({ src: "file://" + out.trim(), px: 20 + Math.random() * (w - 180), py: 60 + Math.random() * (h - 260),
                           pz: top() + 1, rot: Math.random() * 40 - 20, size: 1, fresh: true })
            save.restart()
        })
    }

    FolderListModel { id: folders; folder: "file://" + root.dir; showFiles: false }
    Timer { id: save; interval: 400; onTriggered: file.setText(JSON.stringify(root.rows())) }
    FileView {
        id: file
        path: Cfg.stateDir + "/sidebar-stickers.json"
        onLoaded: {
            try { for (const r of JSON.parse(text())) root.board.append(Object.assign({ size: 1, fresh: false }, r)) } catch (e) {}
        }
    }
}
