import QtQuick

Item {
    visible: false

    readonly property string userId: "umbra-fixture"
    readonly property string displayName: "Nocturne User"
    readonly property string hostname: "Nocturne · isolated"
    readonly property string sessionId: "hyprland-mock"
    readonly property string desktopSession: "Hyprland · mock"
    readonly property var availableSessions: ["hyprland-mock", "plasma-mock"]
    readonly property bool canPowerOff: false
    readonly property bool canReboot: false
    readonly property bool networkAvailable: false
    readonly property bool online: false
    readonly property bool audioAvailable: false
    readonly property bool audioMuted: false
    readonly property int volumePercent: 0
    readonly property bool batteryAvailable: false
    readonly property int batteryPercent: 0
}
