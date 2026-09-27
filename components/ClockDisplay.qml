import QtQuick
import Quickshell

Item {
    id: root
    property real scaleFactor: 1
    property real authProgress: 0
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    Column {
        spacing: 9 * root.scaleFactor
        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "#F2F2F3"
            font.family: "Noto Sans"
            font.pixelSize: 88 * root.scaleFactor
            font.weight: Font.Light
            font.letterSpacing: -3 * root.scaleFactor
        }
        Text {
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: "#A6A6B0"
            font.family: "Adwaita Sans"
            font.pixelSize: 14 * root.scaleFactor
        }
    }
}
