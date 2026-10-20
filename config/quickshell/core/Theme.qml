pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var ansi: []
    property color rawBg: "#101014"
    property color rawFg: "#e6e6ea"

    readonly property bool light: Cfg.look.light
    readonly property color bg: light ? rawFg : rawBg
    readonly property color fg: light ? rawBg : rawFg
    readonly property color accent: adapt(Cfg.look.accent || ansi[4] || fg)
    readonly property color danger: "#ff7070"
    readonly property var swatches: [...new Set(ansi.slice(1))]

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function fgA(a)  { return alpha(fg, a) }
    function accA(a) { return alpha(accent, a) }
    function adapt(c) { c = Qt.color(c); return light && c.hslLightness > 0.6 ? Qt.hsla(c.hslHue, c.hslSaturation, 0.4, 1) : c }

    FileView {
        path: Cfg.home + "/.cache/wal/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text())
                root.rawBg = c.special.background
                root.rawFg = c.special.foreground
                root.ansi = Array.from({ length: 16 }, (_, i) => c.colors["color" + i])
            } catch (e) {}
        }
    }

    readonly property string sans: Qt.application.font.family
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string jp: Qt.fontFamilies().find(f => /CJK JP|Sans JP|Han Sans/.test(f)) ?? mono

    readonly property var curveIn:  [0.2, 0.0, 0.05, 1.0, 1.0, 1.0]
    readonly property var curveOut: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
    readonly property int msIn:    Math.round(500 / Cfg.look.speed)
    readonly property int msOut:   Math.round(380 / Cfg.look.speed)
    readonly property int msMorph: Math.round(340 / Cfg.look.speed)

    onLightChanged: Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", light ? "prefer-light" : "prefer-dark"])

    readonly property string kitty: {
        if (ansi.length < 16) return ""
        const hex = c => Qt.color(c).toString(), a = hex(accent), b = hex(bg), f = hex(fg)
        let s = `cursor ${a}\nurl_color ${a}\nactive_tab_background ${a}\n`
        if (!light) return s
        s += `background ${b}\nforeground ${f}\ncursor_text_color ${b}\nactive_tab_foreground ${b}\ninactive_tab_background ${b}\n`
           + `selection_background ${hex(Qt.tint(bg, alpha(fg, 0.2)))}\nselection_foreground ${f}\n`
           + `color0 ${ansi[7]}\ncolor7 ${ansi[0]}\ncolor8 ${ansi[15]}\ncolor15 ${ansi[8]}\n`
        for (let i = 1; i <= 6; i++) s += `color${i} ${hex(adapt(ansi[i]))}\ncolor${i + 8} ${hex(adapt(ansi[i]))}\n`
        return s
    }
    onKittyChanged: write.restart()
    Timer {
        id: write
        interval: 300
        onTriggered: Quickshell.execDetached(["sh", "-c", 'printf %s "$1" > "$2" && pkill -USR1 -x kitty', "_", root.kitty, Cfg.cacheDir + "/kitty.conf"])
    }
}
