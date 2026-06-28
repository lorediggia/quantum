import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

ShellRoot {
    id: root

    property color themeFg:     "#ffffff"
    property color themeBg:     "#66000000"
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

    // power profile
    readonly property var powerProfiles: ["power-saver", "balanced", "performance"]
    readonly property var powerIcons:    ["󰌪", "󰗑", "󰓅"]
    property int currentPowerIndex: 1

    // panel
    property string activePanel: ""

    function panelLoader(name) {
        switch (name) {
            case "audio":     return audioPanelLoader
            case "wifi":      return wifiPanelLoader
            case "bt":        return btPanelLoader
            case "launcher":  return launcherLoader
            case "wallpicker": return wallPickerLoader
        }
        return null
    }

    function closeActivePanel(then) {
        if (activePanel === "") { if (then) then(); return }
        const loader = panelLoader(activePanel)
        activePanel = ""
        if (loader && loader.active && loader.item) {
            loader.item.hide()
            if (then) panelSwitchTimer.schedule(then)
        } else {
            if (loader) loader.active = false
            if (then) then()
        }
    }

    function openPanel(name) {
        if (activePanel === name) {
            closeActivePanel(null)
            return
        }
        if (activePanel !== "") {
            const next = name
            closeActivePanel(() => activatePanel(next))
        } else {
            activatePanel(name)
        }
    }

    function activatePanel(name) {
        const loader = panelLoader(name)
        if (!loader) return
        activePanel = name
        loader.active = true
        Qt.callLater(() => { if (loader.item) loader.item.show() })
    }

    // timer 
    Timer {
        id: panelSwitchTimer
        interval: 220
        repeat: false
        property var callback: null
        function schedule(cb) { callback = cb; restart() }
        onTriggered: { if (callback) { callback(); callback = null } }
    }

    function runCmd(cmd)        { cmdProc.command = cmd; cmdProc.running = true }
    function addRandomSticker() { stickerPickerProc.running = true }
    function triggerSave()      { if (!isRestoring) saveDebounce.restart() }

    function flushSave() {
        if (!isRestoring) {
            saveDebounce.stop()
            saveStickers()
        }
    }

    function cyclePowerProfile() {
        currentPowerIndex = (currentPowerIndex + 1) % 3
        powerProc.command = ["sh", "-c", "powerprofilesctl set " + powerProfiles[currentPowerIndex]]
        powerProc.running = true
        for (let i = 0; i < buttonModel.count; i++) {
            if (buttonModel.get(i).action === "power_profile") {
                buttonModel.setProperty(i, "icon", powerIcons[currentPowerIndex])
                break
            }
        }
    }

    function buildStickerJson() {
        const data = { sizes: stickerSizes, stickers: [] }
        for (let i = 0; i < stickerModel.count; i++) {
            const it = stickerModel.get(i)
            data.stickers.push({
                imgSrc:       it.imgSrc,
                posX:         it.posX,
                posY:         it.posY,
                baseRot:      it.baseRot,
                stickerZ:     it.stickerZ,
                stickerScale: it.stickerScale
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
        stickerModel.remove(idx)
        saveDebounce.stop()
        root.savePending = false
        writeJson(deleteProc, buildStickerJson())
    }

    Component.onCompleted: {
        loadStickersProc.running = true
        batProc.running = true
        loadAppsProc.running = true
    }

    // theme 
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
                root.themeBg     = "#99" + c.special.background.slice(1)
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

    // process
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
                root.batteryIcon    = cap > 90 ? "󰁹" : cap > 70 ? "󰂀"
                                    : cap > 40 ? "󰁾" : cap > 10 ? "󰁼" : "󰂎"
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
                        stickerModel.append(s)
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
                stickerModel.append({
                    imgSrc:       "file://" + imgPath,
                    posX:         Math.floor(Math.random() * 180) + 20,
                    posY:         Math.floor(Math.random() * 300) + 150,
                    baseRot:      Math.floor(Math.random() * 40) - 20,
                    stickerZ:     root.highestZ,
                    stickerScale: root.stickerSizes[imgPath] || 1.0,
                    isNew:        true
                })
                root.flushSave()
            }
        }
    }

    // IPC 
    IpcHandler {
        target: "sidebar"
        function toggle() { sidebarWindow.visible = !sidebarWindow.visible }
    }
    IpcHandler {
        target: "topbar"
        function show()   { if (topbarLoader.item) topbarLoader.item.visible = true }
        function hide()   { if (topbarLoader.item) topbarLoader.item.visible = false }
        function toggle() {
            if (topbarLoader.item) topbarLoader.item.visible = !topbarLoader.item.visible
        }
    }
    IpcHandler {
        target: "wall_e"
        function toggle() { root.openPanel("wallpicker") }
    }
    IpcHandler {
        target: "launcher"
        function toggle() { root.openPanel("launcher") }
    }
    IpcHandler {
        target: "audio_panel"
        function toggle() { root.openPanel("audio") }
    }
    IpcHandler {
        target: "wifi_panel"
        function toggle() { root.openPanel("wifi") }
    }
    IpcHandler {
        target: "bt_panel"
        function toggle() { root.openPanel("bt") }
    }
    ListModel {
        id: buttonModel
        ListElement { icon: "󰚰"; color_role: "second"; action: "cmd";           cmd0: "kitty";           cmd1: "update" }
        ListElement { icon: "󰏗"; color_role: "accent"; action: "sticker";       cmd0: "";                cmd1: "" }
        ListElement { icon: "󰂯"; color_role: "second"; action: "cmd";           cmd0: "blueman-manager"; cmd1: "" }
        ListElement { icon: "󰖩"; color_role: "accent"; action: "cmd";           cmd0: "kitty";           cmd1: "nmtui" }
        ListElement { icon: "󰊴"; color_role: "second"; action: "cmd";           cmd0: "gamemode";        cmd1: "" }
        ListElement { icon: "󰏘"; color_role: "accent"; action: "cmd";           cmd0: "picker";          cmd1: "" }
        ListElement { icon: "󰌾"; color_role: "accent"; action: "cmd";           cmd0: "hyprlock";        cmd1: "" }
        ListElement { icon: "󰐥"; color_role: "accent"; action: "cmd";           cmd0: "systemctl";       cmd1: "poweroff" }
        ListElement { icon: "󰗑"; color_role: "warm";   action: "power_profile"; cmd0: "";                cmd1: "" }
        ListElement { icon: "󰄨"; color_role: "second"; action: "cmd";           cmd0: "kitty";           cmd1: "btop" }
        ListElement { icon: "󰕾"; color_role: "accent"; action: "cmd";           cmd0: "pavucontrol";     cmd1: "" }
    }

    ListModel { id: stickerModel }

    PanelWindow {
        id: sidebarWindow
        WlrLayershell.namespace:     "quickshell-sidebar"
        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        anchors { top: true; bottom: true; right: true }
        margins { top: 14; bottom: 14; right: 14 }
        implicitWidth: 360
        visible: false
        color: "transparent"

        readonly property MprisPlayer activePlayer:
            Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
        readonly property bool hasPlayer: activePlayer !== null
        readonly property bool isPlaying: hasPlayer && activePlayer.playbackState === MprisPlaybackState.Playing

        Rectangle {
            anchors.fill: parent
            radius: 15
            color:  root.themeBg
            clip:   true

            SidebarContent {
                anchors.fill: parent
                visible: sidebarWindow.visible

                themeAccent: root.themeAccent
                themeSecond: root.themeSecond
                themeFg:     root.themeFg
                themeRawBg:  root.themeRawBg
                themeFresh:  root.themeFresh
                themeWarm:   root.themeWarm

                batteryPercent: root.batteryPercent
                batteryIcon:    root.batteryIcon

                buttonModel:  buttonModel
                activePlayer: sidebarWindow.activePlayer
                hasPlayer:    sidebarWindow.hasPlayer
                isPlaying:    sidebarWindow.isPlaying

                onRequestSticker:    root.addRandomSticker()
                onRequestCmd: (cmd) => root.runCmd(cmd)
                onRequestHide:       sidebarWindow.visible = false
                onRequestPowerCycle: root.cyclePowerProfile()
            }

            Item {
                anchors.fill: parent
                visible: sidebarWindow.visible

                Repeater {
                    model: stickerModel
                    delegate: Sticker {
                        imgSrc:       model.imgSrc
                        posX:         model.posX
                        posY:         model.posY
                        baseRot:      model.baseRot
                        stickerZ:     model.stickerZ
                        stickerScale: model.stickerScale ?? 1.0
                        isNew:        model.isNew
                        modelIndex:   index

                        onRequireSave:                       root.triggerSave()
                        onRequireDestroy:     (idx) =>       root.deleteAndSave(idx)
                        onRequireZUpdate:     (idx) =>       { root.highestZ += 1; stickerModel.setProperty(idx, "stickerZ", root.highestZ) }
                        onUpdatePosition:     (idx, x, y) => { stickerModel.setProperty(idx, "posX", x); stickerModel.setProperty(idx, "posY", y) }
                        onUpdateScaleAndSave: (idx, p, s) => { stickerModel.setProperty(idx, "stickerScale", s); root.stickerSizes[p] = s }
                        onUpdateRotation:     (idx, r) =>    stickerModel.setProperty(idx, "baseRot", r)
                        onUpdateIsNew:        (idx, v) =>    stickerModel.setProperty(idx, "isNew", v)
                    }
                }
            }
        }
    }


    Loader {
        id: topbarLoader
        active: true
        sourceComponent: Component {
            Topbar {
                themeFg:        root.themeFg
                themeBg:        root.themeBg
                themeRawBg:     root.themeRawBg
                themeAccent:    root.themeAccent
                themeSecond:    root.themeSecond
                themeWarm:      root.themeWarm
                themeFresh:     root.themeFresh
                batteryPercent: root.batteryPercent
                batteryIcon:    root.batteryIcon
            }
        }
    }

    Loader {
        id: wallPickerLoader
        active: false
        onActiveChanged: if (!active) root.activePanel = ""
        sourceComponent: Component {
            WallPicker {
                themeAccent: root.themeAccent
                themeFg:     root.themeFg
                themeRawBg:  root.themeRawBg
                themeBg:     root.themeBg
            }
        }
    }

    Loader {
        id: launcherLoader
        active: false
        onActiveChanged: if (!active) root.activePanel = ""
        sourceComponent: Component {
            Launcher {
                allApps:     root.allApps
                themeBg:     root.themeBg
                themeFg:     root.themeFg
                themeAccent: root.themeAccent
                themeSecond: root.themeSecond
            }
        }
    }

    Loader {
        id: audioPanelLoader
        active: false
        onActiveChanged: if (!active) root.activePanel = ""
        onLoaded: {
            item.closed.connect(() => {
                root.activePanel = "" 
            })
        }
        sourceComponent: Component {
            AudioPanel {
                themeFg:     root.themeFg
                themeBg:     root.themeBg
                themeRawBg:  root.themeRawBg
                themeAccent: root.themeAccent
                themeSecond: root.themeSecond
            }
        }
    }

    Loader {
        id: wifiPanelLoader
        active: false
        onActiveChanged: if (!active) root.activePanel = ""
        onLoaded: {
            item.closed.connect(() => {
                root.activePanel = ""  
            })
        }
        sourceComponent: Component {
            WifiPanel {
                themeFg:     root.themeFg
                themeBg:     root.themeBg
                themeRawBg:  root.themeRawBg
                themeAccent: root.themeAccent
                themeSecond: root.themeSecond
            }
        }
    }

    Loader {
        id: btPanelLoader
        active: false
        onActiveChanged: if (!active) root.activePanel = ""
        onLoaded: {
            item.closed.connect(() => {
                root.activePanel = ""  
            })
        }
        sourceComponent: Component {
            BluetoothPanel {
                themeFg:     root.themeFg
                themeBg:     root.themeBg
                themeRawBg:  root.themeRawBg
                themeAccent: root.themeAccent
                themeSecond: root.themeSecond
            }
        }
    }
}
