import QtQuick
import "../components"

Item {
    id: root
    visible: false

    required property var controller
    required property var authPanel
    required property Item targetItem
    required property string selectedState
    required property string captureDirectory

    function capture() {
        const expected = selectedState === "idle" ? GreeterController.Idle
            : selectedState === "auth" ? GreeterController.Auth
            : selectedState === "failure" ? GreeterController.Failure
            : GreeterController.Success;
        if (controller.phase !== expected) {
            console.error("Harness state mismatch for " + selectedState + ": " + controller.phase);
            Qt.quit();
            return;
        }
        targetItem.grabToImage(function(result) {
            const path = captureDirectory + "/nested-" + selectedState + ".png";
            if (!result.saveToFile(path))
                console.error("Harness capture failed");
            else
                console.info("Harness state captured");
            Qt.quit();
        });
    }

    Timer {
        interval: 1500
        running: root.selectedState !== "none"
        repeat: false
        onTriggered: {
            if (root.selectedState === "idle")
                root.capture();
            else {
                root.controller.wake();
                afterWake.start();
            }
        }
    }

    Timer {
        id: afterWake
        interval: 1100
        repeat: false
        onTriggered: {
            if (root.selectedState === "auth")
                root.capture();
            else if (root.selectedState === "auth-hold")
                return;
            else {
                root.authPanel.submit();
                afterSubmit.start();
            }
        }
    }

    Timer {
        id: afterSubmit
        interval: root.selectedState === "failure" ? 470 : 1650
        repeat: false
        onTriggered: root.capture()
    }
}
