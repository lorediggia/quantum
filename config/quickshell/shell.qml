import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core
import qs.services
import qs.frame

ShellRoot {
    Frame {}
    Desk {}

    component Reserve: PanelWindow {
        WlrLayershell.namespace: "quickshell-reserve"
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        mask: Region {}
    }
    Reserve { anchors.top: true; exclusiveZone: Cfg.look.barH }
    Reserve { anchors.bottom: true; exclusiveZone: Cfg.look.edge }
    Reserve { anchors.left: true; exclusiveZone: Cfg.look.edge }
    Reserve { anchors.right: true; exclusiveZone: Cfg.look.edge }

    IpcHandler { target: "shell"; function toggle(name: string): void { Ui.toggle(name) } }
    IpcHandler {
        target: "volume"
        function up(): void { Audio.step(1) }
        function down(): void { Audio.step(-1) }
        function mute(): void { Audio.toggleMute() }
        function micmute(): void { Audio.toggleMic() }
    }
    IpcHandler {
        target: "caffeine"
        function toggle(): void { Caffeine.toggle() }
        function on(): void { Cfg.caffeine = true }
        function off(): void { Cfg.caffeine = false }
        function status(): bool { return Caffeine.active }
    }
    IpcHandler {
        target: "desktop"
        function edit(): void { Desktop.editing = !Desktop.editing }
    }
    IpcHandler {
        target: "media"
        function toggle(): void { Media.toggle() }
        function next(): void { Media.next() }
        function prev(): void { Media.prev() }
    }
    IpcHandler {
        target: "brightness"
        function up(): void { Brightness.step(1) }
        function down(): void { Brightness.step(-1) }
    }
}
