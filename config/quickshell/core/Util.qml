pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
    function quote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function expand(p) { return p === "~" || p.startsWith("~/") ? Cfg.home + p.slice(1) : p }

    function argv(cmd) { return typeof cmd === "string" ? ["sh", "-c", cmd] : cmd }
    function spawn(cmd) { Quickshell.execDetached(argv(cmd)) }
    function run(cmd, done) { proc.createObject(root, { command: argv(cmd), done }) }
    function notify(title, body, urgency, icon) { spawn(["notify-send", "-a", "Shell", "-u", urgency, "-i", icon, title, body]) }

    function iconUrl(s) {
        return !s ? "image://icon/application-x-executable" : s.startsWith("/") ? "file://" + s : s.includes("://") ? s : "image://icon/" + s
    }

    Component {
        id: proc
        Process {
            id: p
            property var done
            running: true
            stdout: StdioCollector { onStreamFinished: { p.done(text); p.destroy() } }
        }
    }
}
