import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root
    visible: false

    readonly property bool networkAvailable: true
    readonly property bool online: Networking.devices.values.some(device => device.connected)
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool audioAvailable: Pipewire.ready && audioSink !== null
    readonly property bool audioMuted: audioSink && audioSink.audio ? audioSink.audio.muted : false
    readonly property int volumePercent: audioSink && audioSink.audio ? Math.round(audioSink.audio.volume * 100) : 0
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryAvailable: battery !== null && battery.isPresent
    readonly property int batteryPercent: battery ? Math.round(battery.percentage * 100) : 0
    readonly property string desktopSession: String(Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("DESKTOP_SESSION") || "Local session").split(":")[0]

    PwObjectTracker {
        objects: root.audioSink ? [root.audioSink] : []
    }
}
