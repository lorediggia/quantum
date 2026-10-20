pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/quickshell"
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || home + "/.cache") + "/quickshell"
    readonly property string dotfiles: Quickshell.env("DOTFILES") || home + "/dotfiles"

    readonly property alias look: s.look
    readonly property alias bar: s.bar
    readonly property alias desktop: s.desktop
    property alias pack: s.pack
    property alias wallDir: s.wallDir
    property alias dnd: s.dnd
    property alias caffeine: s.caffeine

    function reset() { file.setText("{}"); Quickshell.reload(false) }
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", stateDir, cacheDir])

    FileView {
        id: file
        path: root.stateDir + "/settings.json"
        blockWrites: true
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: s
            property JsonObject look: JsonObject {
                property bool light: false
                property string accent: ""
                property real speed: 1
                property int rad: 15
                property int barH: 40
                property int edge: 10
                property int drawerW: 320
            }
            property JsonObject bar: JsonObject {
                property var buttons: ["wifi", "bluetooth", "audio", "power", "caffeine", "settings"]
                property int wsCount: 10
                property bool japanese: false
                property bool appName: true
                property bool clock24: true
                property bool seconds: false
                property bool date: true
                property bool media: true
            }
            property JsonObject desktop: JsonObject {
                property bool show: true
                property int size: 48
                property var icons: []
            }
            property string pack: ""
            property string wallDir: "~/pictures/wal"
            property bool dnd: false
            property bool caffeine: false
        }
    }
}
