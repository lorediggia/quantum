pragma Singleton
import QtQuick
import Quickshell
import qs.core

Singleton {
    readonly property var live: ({ caffeine: Caffeine.icon, audio: Audio.icon, wifi: Net.icon, bluetooth: Bt.icon, notifications: Notifs.icon, power: Power.icon, profile: Power.profileIcon })
    function icon(n) { return live[n] ?? Ui.icons[n] ?? "?" }
    function run(n, w, h) {
        switch (n) {
        case "caffeine": return Caffeine.toggle()
        case "profile":  return Power.cycleProfile()
        case "gamemode": return Util.spawn("gamemode")
        case "update":   Util.spawn("kitty update"); return Ui.close()
        case "stickers": Ui.open = "sidebar"; return Stickers.add(w ?? Cfg.look.drawerW, h ?? 700)
        default:         Ui.toggle(n)
        }
    }
}
