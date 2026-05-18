import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

ShellRoot {
    id: root

    // palette
    property color themeFg:     "#ffffff"
    property color themeBg:     "#66000000"
    property color themeRawBg:  "#000000"
    property color themeAccent: "#ffffff"
    property color themeSecond: "#ffffff"
    property color themeWarm:   "#ffffff"
    property color themeFresh:  "#ffffff"

    // state
    property int  highestZ:     0
    property var  stickerSizes: ({})
    property bool isRestoring:  false

    //battery
    property string batteryPercent: ""
    property string batteryIcon:    "󰁹"

    // power profile
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
        for (let i = 0; i < buttonModel.count; i++) {
            if (buttonModel.get(i).action === "power_profile") {
                buttonModel.setProperty(i, "icon", powerIcons[currentPowerIndex])
                break
            }
        }
    }

    function saveStickers() {
        const data = { sizes: stickerSizes, stickers: [] }
        for (let i = 0; i < stickerModel.count; i++) {
            const it = stickerModel.get(i)
            data.stickers.push({
                imgSrc: it.imgSrc, posX: it.posX, posY: it.posY,
                baseRot: it.baseRot, stickerZ: it.stickerZ, stickerScale: it.stickerScale
            })
        }
        const safeJson = JSON.stringify(data).replace(/'/g, "'\\''")
        saveProc.command = ["sh", "-c", "echo '" + safeJson + "' > ~/.cache/sidebar_stickers.json"]
        saveProc.running = true
    }

    Component.onCompleted: {
        loadStickersProc.running = true
        batFile.reload()
    }

    // colors
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

    // battery
    FileView {
        id: batFile
        path: "/sys/class/power_supply/BAT0/capacity"
        onLoaded: {
            const cap = parseInt(text().trim())
            if (isNaN(cap)) return
            root.batteryPercent = cap + "%"
            statusFile.reload()
            root.batteryIcon = cap > 90 ? "󰁹" : cap > 70 ? "󰂀"
                             : cap > 40 ? "󰁾" : cap > 10 ? "󰁼" : "󰂎"
        }
    }
    FileView {
        id: statusFile
        path: "/sys/class/power_supply/BAT0/status"
        onLoaded: {
            if (text().trim() === "Charging") root.batteryIcon = "󰂄"
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: batFile.reload() }

    // sticker persistence
    Timer { id: saveDebounce; interval: 200; onTriggered: root.saveStickers() }
    Process { id: saveProc }
    Process {
        id: loadStickersProc
        command: ["sh", "-c", "cat ~/.cache/sidebar_stickers.json 2>/dev/null || echo ''"]
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
                root.triggerSave()
            }
        }
    }

    // ipc
    IpcHandler {
        target: "sidebar"
        function toggle() { sidebarWindow.visible = !sidebarWindow.visible }
    }
    IpcHandler {
        target: "wall_e"
        function show()   { wallPicker.show() }
        function hide()   { wallPicker.hide() }
        function toggle() { wallPicker.toggle() }
    }
    IpcHandler {
        target: "topbar"
        function show()   { topbar.show() }
        function hide()   { topbar.hide() }
        function toggle() { topbar.toggle() }
    }
    IpcHandler {
        target: "keybinds"
        function show()   { keybindsWindow.show() }
        function hide()   { keybindsWindow.hide() }
        function toggle() { keybindsWindow.toggle() }
    }

    // sidebar buttons
    ListModel {
        id: buttonModel
        ListElement { icon: "󰚰"; color_role: "second"; action: "cmd";           cmd0: "kitty";           cmd1: "update" }
        ListElement { icon: "󰏗"; color_role: "accent"; action: "sticker";       cmd0: "";                cmd1: "" }
        ListElement { icon: "󰂯"; color_role: "second"; action: "cmd";           cmd0: "blueman-manager"; cmd1: "" }
        ListElement { icon: "󰖩"; color_role: "accent"; action: "cmd";           cmd0: "kitty";           cmd1: "nmtui" }
        ListElement { icon: "󰊴"; color_role: "second"; action: "cmd";           cmd0: "gamemode";        cmd1: "" }
        ListElement { icon: "󰏘"; color_role: "accent"; action: "cmd";           cmd0: "picker";          cmd1: "" }
        ListElement { icon: "󰒲"; color_role: "second"; action: "cmd";           cmd0: "systemctl";       cmd1: "suspend" }
        ListElement { icon: "󰍃"; color_role: "accent"; action: "cmd";           cmd0: "hyprctl";         cmd1: "dispatch exit" }
        ListElement { icon: "󰜉"; color_role: "second"; action: "cmd";           cmd0: "systemctl";       cmd1: "reboot" }
        ListElement { icon: "󰐥"; color_role: "accent"; action: "cmd";           cmd0: "systemctl";       cmd1: "poweroff" }
        ListElement { icon: "󰗑"; color_role: "warm";   action: "power_profile"; cmd0: "";                cmd1: "" }
        ListElement { icon: "󰄨"; color_role: "second"; action: "cmd";           cmd0: "kitty";           cmd1: "btop" }
        ListElement { icon: "󰕾"; color_role: "accent"; action: "cmd";           cmd0: "pavucontrol";     cmd1: "" }
        ListElement { icon: "󰌌"; color_role: "fresh";  action: "ipc";           cmd0: "keybinds";        cmd1: "toggle" }
    }

    ListModel { id: stickerModel }

    // sidebar window
    PanelWindow {
        id: sidebarWindow
        WlrLayershell.namespace:     "quickshell-sidebar"
        WlrLayershell.layer:         WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        anchors { top: true; bottom: true; right: true }
        margins { top: 10; bottom: 10; right: 10 }
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
                        onRequireDestroy:     (idx) =>       { stickerModel.remove(idx); root.triggerSave() }
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

    WallPicker {
        id: wallPicker
        themeAccent: root.themeAccent
        themeFg:     root.themeFg
        themeRawBg:  root.themeRawBg
        themeBg:     root.themeBg
    }

    Topbar {
        id: topbar
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

    KeybindsWindow {
        id: keybindsWindow
        themeBg:     root.themeBg
        themeFg:     root.themeFg
        themeAccent: root.themeAccent
        themeSecond: root.themeSecond
        themeWarm:   root.themeWarm
    }
}