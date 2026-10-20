pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.core

Singleton {
    id: root

    readonly property real max: 1.5
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var sinks: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => !n.isSink && !n.isStream && !n.name.endsWith(".monitor"))
    readonly property var streams: nodes.filter(n => n.isStream && n.properties["media.class"] === "Stream/Output/Audio")

    PwObjectTracker { objects: [root.sink, root.source, ...root.streams].filter(Boolean) }

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property string icon: muted || volume <= 0 ? "󰝟" : volume < 0.33 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"
    readonly property string micIcon: micMuted ? "󰍭" : "󰍬"
    function pct(v) { return Math.round(v * 100) + "%" }
    function name(n) { return n.description || n.nickname || n.name }

    function setVolume(v) { if (sink?.audio) { sink.audio.volume = Util.clamp(v, 0, max); Ui.show("volume", volume / max) } }
    function setMic(v) { if (source?.audio) { source.audio.volume = Util.clamp(v, 0, 1); Ui.show("mic", micVolume) } }
    function step(dir) { setVolume(volume + dir * 0.05) }
    function toggleMute() { if (sink?.audio) { sink.audio.muted = !muted; Ui.show("volume", muted ? 0 : volume / max) } }
    function toggleMic() { if (source?.audio) { source.audio.muted = !micMuted; Ui.show("mic", micMuted ? 0 : micVolume) } }
    function setDefault(n) { if (n.isSink) Pipewire.preferredDefaultAudioSink = n; else Pipewire.preferredDefaultAudioSource = n }
}
