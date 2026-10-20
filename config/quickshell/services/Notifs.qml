pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.core

Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values
    readonly property int count: list.length
    readonly property string icon: Cfg.dnd ? "󰂛" : "󰂚"
    readonly property ListModel toasts: ListModel {}
    readonly property bool urgent: toasts.count > 0 && [...Array(toasts.count).keys()].some(i => toasts.get(i).urgent)

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => {
            n.tracked = true
            const urgent = n.urgency === NotificationUrgency.Critical || n.appName === "Shell"
            if (Cfg.dnd && !urgent) return
            root.toasts.insert(0, { nid: n.id, summary: n.summary || n.appName, body: root.plain(n.body), icon: root.iconFor(n),
                                    urgent, until: Date.now() + (urgent ? 14 : 6) * 1000 })
            if (root.toasts.count > 4) root.toasts.remove(4)
        }
    }
    Timer {
        interval: 500
        repeat: true
        running: root.toasts.count > 0
        onTriggered: { for (let i = root.toasts.count - 1; i >= 0; i--) if (root.toasts.get(i).until <= Date.now()) root.toasts.remove(i) }
    }

    function plain(s) { return s.replace(/<[^>]*>/g, "") }

    readonly property var glyphs: [
        [/batter|charg|power suppl/i, "󰂃"], [/bluetooth|paired|headphone|earbud/i, "󰂯"], [/wi-?fi|network|internet|ethernet/i, "󰖩"],
        [/volume|audio|sound|mic/i, "󰕾"], [/download/i, "󰇚"], [/screenshot|grim|screen ?shot/i, "󰹑"],
        [/update|upgrade|pacman|yay/i, "󰚰"], [/mail|inbox/i, "󰇮"], [/message|chat|reply|mention/i, "󰍡"],
        [/calendar|event|remind|meeting/i, "󰃭"], [/usb|device|mount|drive|disk/i, "󰕓"], [/music|spotify|playing|track/i, "󰎇"],
        [/error|fail|warn|crit/i, "󰀨"], [/done|complete|success|saved|copied/i, "󰗠"]
    ]
    function glyph(s) { return glyphs.find(g => g[0].test(s))?.[1] ?? "󰂚" }
    function iconFor(n) {
        if (n.image) return n.image
        const ic = n.appIcon ?? ""
        if ([...ic].length === 1) return ic
        if (ic.startsWith("/") || ic.includes("://")) return ic.startsWith("/") ? "file://" + ic : ic
        const name = ic || DesktopEntries.byId(n.desktopEntry)?.icon || DesktopEntries.heuristicLookup(n.appName)?.icon || ""
        return (name && n.appName !== "Shell" ? Quickshell.iconPath(name, true) : "") || glyph(`${n.summary} ${n.appName} ${n.body}`)
    }
    function untoast(id) { for (let i = 0; i < toasts.count; i++) if (toasts.get(i).nid === id) return toasts.remove(i) }
    function activate(id) {
        const n = list.find(n => n.id === id)
        n?.actions.find(a => a.identifier === "default")?.invoke()
        n?.dismiss()
        untoast(id)
    }
    function clear() { for (const n of [...list]) n.dismiss(); toasts.clear() }
    function toggleDnd() { Cfg.dnd = !Cfg.dnd; if (Cfg.dnd) toasts.clear() }
}
