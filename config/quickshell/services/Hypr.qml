pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core

Singleton {
    function dispatch(call) { Hyprland.dispatch("hl.dsp." + call) }
    function selector(ws) { return /^\d+$|^special/.test(ws) ? ws : "name:" + ws }

    function workspace(ws)  { dispatch(`focus({ workspace = "${selector(ws)}" })`) }
    function focus(addr)    { dispatch(`focus({ window = "address:${addr}" })`) }
    function close(addr)    { dispatch(`window.close({ window = "address:${addr}" })`) }
    function move(addr, ws) { dispatch(`window.move({ window = "address:${addr}", workspace = "${selector(ws)}", follow = false })`) }
    function exit()         { dispatch("exit()") }

    function label(ws) {
        const d = "〇一二三四五六七八九十", n = parseInt(ws)
        return isNaN(n) ? String(ws).replace(/^special:/, "") : !Cfg.bar.japanese || n > 19 ? String(n) : n <= 10 ? d[n] : d[10] + d[n - 10]
    }
}
