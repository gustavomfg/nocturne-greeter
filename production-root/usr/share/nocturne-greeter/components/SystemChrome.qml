pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    property real scaleFactor: 1
    property real leftMargin: 32
    property real rightMargin: 32
    property string hostname: "Local system"
    property string desktopSession: "Local session"
    property string sessionContextText: "Selected session"
    property string powerUnavailableText: "Unavailable"
    property bool networkAvailable: false
    property bool online: false
    property bool audioAvailable: false
    property bool audioMuted: false
    property int volumePercent: 0
    property bool batteryAvailable: false
    property int batteryPercent: 0
    property var controller
    property bool powerMenuOpen: false
    property bool sessionMenuOpen: false
    function dismissMenus() {
        const wasOpen = powerMenuOpen || sessionMenuOpen;
        powerMenuOpen = false;
        sessionMenuOpen = false;
        return wasOpen;
    }
    Connections {
        target: root.controller
        function onPhaseChanged() {
            root.dismissMenus();
        }
    }
    Row {
        x: root.leftMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18 * root.scaleFactor
        Text {
            text: root.hostname
            width: Math.min(implicitWidth, root.width * .18)
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
            color: "#777781"
            font.family: "Adwaita Sans"
            font.pixelSize: 12 * root.scaleFactor
        }
        Rectangle {
            width: 1
            height: 12 * root.scaleFactor
            color: "#34343D"
            anchors.verticalCenter: parent.verticalCenter
        }
        Item {
            id: sessionButton
            width: sessionLabel.implicitWidth + 24 * root.scaleFactor
            height: 40 * root.scaleFactor
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: "Session: " + root.desktopSession
            function activate() {
                root.sessionMenuOpen = !root.sessionMenuOpen;
                root.powerMenuOpen = false;
            }
            Keys.onReturnPressed: activate()
            Keys.onSpacePressed: activate()
            Text {
                id: sessionLabel
                anchors.verticalCenter: parent.verticalCenter
                text: root.desktopSession
                color: sessionMouse.containsMouse || sessionButton.activeFocus ? "#F2F2F3" : "#A6A6B0"
                font.family: "Adwaita Sans"
                font.pixelSize: 12 * root.scaleFactor
            }
            Image {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 14 * root.scaleFactor
                height: width
                source: "../assets/icons/chevron.svg"
                rotation: root.sessionMenuOpen ? 180 : 0
                Behavior on rotation {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }
            }
            MouseArea {
                id: sessionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    sessionButton.forceActiveFocus();
                    sessionButton.activate();
                }
            }
        }
    }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: root.rightMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5 * root.scaleFactor
        IconButton {
            visible: root.networkAvailable
            icon: "../assets/icons/network.svg"
            label: root.online ? "Connected" : "No connection"
            scaleFactor: root.scaleFactor
            interactive: false
        }
        IconButton {
            visible: root.audioAvailable
            icon: root.audioMuted ? "../assets/icons/muted.svg" : "../assets/icons/audio.svg"
            label: root.audioMuted ? "Muted" : "Volume " + root.volumePercent + "%"
            scaleFactor: root.scaleFactor
            interactive: false
        }
        IconButton {
            visible: root.batteryAvailable
            icon: "../assets/icons/battery.svg"
            label: root.batteryPercent + "% battery"
            scaleFactor: root.scaleFactor
            interactive: false
        }
        Item {
            width: 14 * root.scaleFactor
            height: 1
        }
        IconButton {
            id: powerButton
            objectName: "powerButton"
            icon: "../assets/icons/power.svg"
            label: "Power"
            scaleFactor: root.scaleFactor
            selected: root.powerMenuOpen
            onClicked: {
                root.powerMenuOpen = !root.powerMenuOpen;
                root.sessionMenuOpen = false;
            }
        }
    }
    Rectangle {
        id: powerMenu
        anchors.right: parent.right
        anchors.rightMargin: root.rightMargin
        y: -height - 8 * root.scaleFactor + (1 - opacity) * 10
        width: 220 * root.scaleFactor
        height: 182 * root.scaleFactor
        radius: 10 * root.scaleFactor
        color: "#111116"
        border.width: 1
        border.color: "#292930"
        visible: opacity > .001
        opacity: root.powerMenuOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }
        Column {
            anchors.fill: parent
            anchors.margins: 18 * root.scaleFactor
            spacing: 15 * root.scaleFactor
            Repeater {
                model: [
                    {
                        name: "Sleep",
                        icon: "moon"
                    },
                    {
                        name: "Restart",
                        icon: "restart"
                    },
                    {
                        name: "Shut down",
                        icon: "power"
                    }
                ]
                delegate: Row {
                    id: powerRow
                    required property var modelData
                    spacing: 12 * root.scaleFactor
                    opacity: .5
                    Image {
                        source: "../assets/icons/" + powerRow.modelData.icon + ".svg"
                        width: 17 * root.scaleFactor
                        height: width
                    }
                    Text {
                        text: powerRow.modelData.name
                        color: "#A6A6B0"
                        font.family: "Adwaita Sans"
                        font.pixelSize: 13 * root.scaleFactor
                    }
                }
            }
            Text {
                text: root.powerUnavailableText
                color: "#777781"
                font.family: "Adwaita Sans"
                font.pixelSize: 11 * root.scaleFactor
            }
        }
    }
    Rectangle {
        x: root.leftMargin
        y: -height - 8 * root.scaleFactor + (1 - opacity) * 10
        width: 240 * root.scaleFactor
        height: 96 * root.scaleFactor
        radius: 10 * root.scaleFactor
        color: "#111116"
        border.width: 1
        border.color: "#292930"
        visible: opacity > .001
        opacity: root.sessionMenuOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }
        Column {
            anchors.fill: parent
            anchors.margins: 18 * root.scaleFactor
            spacing: 12 * root.scaleFactor
            Text {
                text: root.desktopSession
                color: "#F2F2F3"
                font.family: "Adwaita Sans"
                font.pixelSize: 14 * root.scaleFactor
            }
            Text {
                text: root.sessionContextText
                color: "#777781"
                font.family: "Adwaita Sans"
                font.pixelSize: 11 * root.scaleFactor
            }
        }
    }
}
