pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root
    readonly property var players: Mpris.players.values
    property var last: null
    readonly property var player: players.find(p => p.isPlaying) ?? (players.includes(last) ? last : null)
        ?? players.find(p => p.identity === "Spotify") ?? players[0] ?? null
    onPlayingChanged: if (playing) last = player

    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string art: player?.trackArtUrl ?? ""

    function toggle() { if (player?.canTogglePlaying) player.togglePlaying() }
    function next()   { if (player?.canGoNext) player.next() }
    function prev()   { if (player?.canGoPrevious) player.previous() }
}
