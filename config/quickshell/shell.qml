import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property color themeFg:     "#ffffff"
    property color themeRawBg:  "#000000"
    property color themeAccent: "#ffffff"
    property color themeSecond: "#ffffff"
    property color themeWarm:   "#ffffff"
    property color themeFresh:  "#ffffff"

    property int  highestZ:     0
    property var  stickerSizes: ({})
    property bool isRestoring:  false
    property bool savePending:  false

    property string batteryPercent: ""
    property string batteryIcon:    "󰁹"

    property var allApps: []

    readonly property var powerProfiles: ["power-saver", "balanced", "performance"]
    readonly property var powerIcons:    ["󰌪", "󰗑", "󰓅"]
    property int currentPowerIndex: 1

    function runCmd(cmd)        { cmdProc.command = cmd; cmdProc.running = true }
    function addRandomSticker() { stickerPickerProc.running = true }
    function triggerSave()      { if (!isRestoring) saveDebounce.restart() }

    function cyclePowerProfile() {
        currentPowerIndex = (currentPowerIndex + 1) % 3
        powerProc.command = ["sh", "-c", "powerprofilesctl set " + powerProfiles[currentPowerIndex]]
        powerProc.running = true
        for (let i = 0; i < sidebarButtons.count; i++) {
            if (sidebarButtons.get(i).action === "power_profile") {
                sidebarButtons.setProperty(i, "icon", powerIcons[currentPowerIndex])
                break
            }
        }
    }

    function bumpStickerZ(idx) {
        root.highestZ += 1
        stickerItems.setProperty(idx, "stickerZ", root.highestZ)
    }

    function rememberStickerSize(path, scale) {
        root.stickerSizes[path] = scale
    }

    function buildStickerJson() {
        const data = { sizes: stickerSizes, stickers: [] }
        for (let i = 0; i < stickerItems.count; i++) {
            const it = stickerItems.get(i)
            data.stickers.push({
                imgSrc: it.imgSrc, posX: it.posX, posY: it.posY,
                baseRot: it.baseRot, stickerZ: it.stickerZ, stickerScale: it.stickerScale
            })
        }
        return JSON.stringify(data).replace(/'/g, "'\\''")
    }

    function writeJson(proc, json) {
        proc.command = ["sh", "-c",
            "f=~/.cache/sidebar_stickers.json; " +
            "printf '%s' '" + json + "' > \"$f.tmp\" && mv \"$f.tmp\" \"$f\""
        ]
        proc.running = true
    }

    function saveStickers() {
        if (saveProc.running) { root.savePending = true; return }
        writeJson(saveProc, buildStickerJson())
    }

    function deleteAndSave(idx) {
        stickerItems.remove(idx)
        saveDebounce.stop()
        root.savePending = false
        writeJson(deleteProc, buildStickerJson())
    }

    Component.onCompleted: {
        loadStickersProc.running = true
        batProc.running = true
        loadAppsProc.running = true
    }

    FileView {
        id: colorFile
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text())
                root.themeRawBg  = c.special.background
                root.themeFg     = c.special.foreground
                root.themeWarm   = c.colors.color1
                root.themeFresh  = c.colors.color2
                root.themeAccent = c.colors.color4
                root.themeSecond = c.colors.color3
            } catch (e) {}
        }
    }

    Repeater {
        model: [
            Quickshell.env("HOME") + "/.local/share/applications",
            "/usr/share/applications",
            "/usr/local/share/applications",
            "/var/lib/flatpak/exports/share/applications",
            Quickshell.env("HOME") + "/.local/share/flatpak/exports/share/applications"
        ]
        delegate: FileView {
            path: modelData
            watchChanges: true
            onFileChanged: loadAppsProc.running = true
        }
    }

    Process {
        id: batProc
        command: ["sh", "-c",
            "for d in /sys/class/power_supply/BAT*; do" +
            "  [ -f \"$d/capacity\" ] || continue;" +
            "  echo \"$(cat $d/capacity)|$(cat $d/status 2>/dev/null)\";" +
            "  exit;" +
            "done;" +
            "ac=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 0);" +
            "echo \"|AC|$ac\""
        ]
        property string buf: ""
        stdout: SplitParser { onRead: (d) => batProc.buf += d }
        onExited: {
            const p = batProc.buf.trim().split("|")
            batProc.buf = ""
            const cap = parseInt(p[0])
            if (!isNaN(cap)) {
                root.batteryPercent = cap + "%"
                root.batteryIcon    = cap > 90 ? "󰁹" : cap > 70 ? "󰂀" : cap > 40 ? "󰁾" : cap > 10 ? "󰁼" : "󰂎"
                if ((p[1] ?? "").trim() === "Charging") root.batteryIcon = "󰂄"
            } else if ((p[2] ?? "").trim() === "1") {
                root.batteryIcon    = "󰚥"
                root.batteryPercent = "AC"
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: batProc.running = true }

    Process {
        id: loadAppsProc
        command: ["launcher-apps"]
        property string buf: ""
        stdout: SplitParser { onRead: (d) => loadAppsProc.buf += d + "\n" }
        onExited: {
            const apps = []
            for (const line of loadAppsProc.buf.split("\n")) {
                if (!line) continue
                const i = line.indexOf("\t")
                if (i < 0) continue
                apps.push({ name: line.substring(0, i), exec: line.substring(i + 1) })
            }
            root.allApps = apps
            loadAppsProc.buf = ""
        }
    }

    Timer { id: saveDebounce; interval: 200; onTriggered: root.saveStickers() }

    Process {
        id: saveProc
        onRunningChanged: {
            if (!running && root.savePending) {
                root.savePending = false
                root.saveStickers()
            }
        }
    }

    Process { id: deleteProc }

    Process {
        id: loadStickersProc
        command: ["sh", "-c", "sticker-load 2>/dev/null || cat ~/.cache/sidebar_stickers.json 2>/dev/null || echo ''"]
        property string buffer: ""
        stdout: SplitParser { onRead: (data) => loadStickersProc.buffer += data }
        onExited: (code) => {
            if (code === 0 && loadStickersProc.buffer.trim() !== "") {
                try {
                    const data = JSON.parse(loadStickersProc.buffer)
                    root.stickerSizes = data.sizes || {}
                    root.isRestoring  = true
                    for (const s of data.stickers) {
                        if (s.stickerZ > root.highestZ) root.highestZ = s.stickerZ
                        s.isNew = false
                        stickerItems.append(s)
                    }
                    root.isRestoring = false
                } catch (e) {}
            }
            loadStickersProc.buffer = ""
        }
    }

    Process { id: powerProc }
    Process { id: cmdProc }
    Process {
        id: stickerPickerProc
        command: ["sh", "-c", "find \"$HOME/dotfiles/logo/img/\" -type f \\( -name '*.png' -o -name '*.jpg' \\) | shuf -n 1"]
        stdout: SplitParser {
            onRead: (data) => {
                const imgPath = data.trim()
                if (imgPath === "") return
                root.highestZ += 1
                stickerItems.append({
                    imgSrc:       "file://" + imgPath,
                    posX:         Math.floor(Math.random() * 180) + 20,
                    posY:         Math.floor(Math.random() * 300) + 150,
                    baseRot:      Math.floor(Math.random() * 40) - 20,
                    stickerZ:     root.highestZ,
                    stickerScale: root.stickerSizes[imgPath] || 1.0,
                    isNew:        true
                })
                root.saveStickers()
            }
        }
    }

    ListModel {
        id: sidebarButtons
        ListElement { icon: "󰚰"; color_role: "second"; action: "cmd";           cmd0: "kitty";           cmd1: "update" }
        ListElement { icon: "󰏗"; color_role: "accent"; action: "sticker";       cmd0: "";                cmd1: "" }
        ListElement { icon: "󰂯"; color_role: "second"; action: "cmd";           cmd0: "blueman-manager"; cmd1: "" }
        ListElement { icon: "󰖩"; color_role: "accent"; action: "cmd";           cmd0: "kitty";           cmd1: "nmtui" }
        ListElement { icon: "󰊴"; color_role: "second"; action: "cmd";           cmd0: "gamemode";        cmd1: "" }
        ListElement { icon: "󰏘"; color_role: "accent"; action: "cmd";           cmd0: "picker";          cmd1: "" }
        ListElement { icon: "󰌾"; color_role: "accent"; action: "cmd";           cmd0: "hyprlock";        cmd1: "" }
        ListElement { icon: "󰐥"; color_role: "accent"; action: "cmd";           cmd0: "systemctl";       cmd1: "poweroff" }
        ListElement { icon: "󰤄"; color_role: "warm";   action: "cmd";           cmd0: "systemctl";       cmd1: "suspend" }
        ListElement { icon: "󰜉"; color_role: "warm";   action: "cmd";           cmd0: "systemctl";       cmd1: "reboot" }
        ListElement { icon: "󰍃"; color_role: "warm";   action: "cmd";           cmd0: "hyprctl";         cmd1: "dispatch exit" }
        ListElement { icon: "󰗑"; color_role: "warm";   action: "power_profile"; cmd0: "";                cmd1: "" }
        ListElement { icon: "󰄨"; color_role: "second"; action: "cmd";           cmd0: "kitty";           cmd1: "btop" }
        ListElement { icon: "󰕾"; color_role: "accent"; action: "cmd";           cmd0: "pavucontrol";     cmd1: "" }
        ListElement { icon: "󰆓"; color_role: "second"; action: "cmd";           cmd0: "nautilus";        cmd1: "" }
        ListElement { icon: "󰆍"; color_role: "second"; action: "cmd";           cmd0: "kitty";           cmd1: "" }
        ListElement { icon: "󰄀"; color_role: "fresh";  action: "cmd";           cmd0: "sh";              cmd1: "-c 'grim - | wl-copy'" }
        ListElement { icon: "󰕧"; color_role: "fresh";  action: "cmd";           cmd0: "sh";              cmd1: "-c 'grim \"$HOME/Pictures/$(date +%Y%m%d-%H%M%S).png\"'" }
        ListElement { icon: "󰈹"; color_role: "second"; action: "cmd";           cmd0: "zen-browser";     cmd1: "" }
    }

    ListModel { id: stickerItems }

    IpcHandler {
        target: "sidebar"
        function toggle() { if (frameLoader.item) frameLoader.item.toggleSidebar() }
    }
    IpcHandler {
        target: "topbar"
        function show()   { if (frameLoader.item) frameLoader.item.visible = true }
        function hide()   { if (frameLoader.item) frameLoader.item.visible = false }
        function toggle() { if (frameLoader.item) frameLoader.item.visible = !frameLoader.item.visible }
    }
    IpcHandler {
        target: "wall_e"
        function toggle() { if (frameLoader.item) frameLoader.item.toggleWallpicker() }
    }
    IpcHandler {
        target: "launcher"
        function toggle() { if (frameLoader.item) frameLoader.item.togglePanel("launcher") }
    }
    IpcHandler {
        target: "audio_panel"
        function toggle() { if (frameLoader.item) frameLoader.item.togglePanel("audio") }
    }
    IpcHandler {
        target: "wifi_panel"
        function toggle() { if (frameLoader.item) frameLoader.item.togglePanel("wifi") }
    }
    IpcHandler {
        target: "bt_panel"
        function toggle() { if (frameLoader.item) frameLoader.item.togglePanel("bt") }
    }

    Loader {
        id: frameLoader
        active: true
        sourceComponent: Component {
            Frame {
                allApps:        root.allApps
                themeFg:        root.themeFg
                themeRawBg:     root.themeRawBg
                themeAccent:    root.themeAccent
                themeSecond:    root.themeSecond
                themeWarm:      root.themeWarm
                themeFresh:     root.themeFresh
                batteryPercent: root.batteryPercent
                batteryIcon:    root.batteryIcon
                buttonModel:    sidebarButtons
                stickerModel:   stickerItems

                onRequestSticker:        root.addRandomSticker()
                onRequestCmd:      (cmd) => root.runCmd(cmd)
                onRequestPowerCycle:     root.cyclePowerProfile()
                onRequestStickerSave:    root.triggerSave()
                onRequestStickerDestroy: (idx) => root.deleteAndSave(idx)
                onRequestStickerZBump:   (idx) => root.bumpStickerZ(idx)
                onRequestStickerSize:    (path, scale) => root.rememberStickerSize(path, scale)
            }
        }
    }
}
