import QtQuick
import "../components"

Item {
    id: root
    visible: false

    required property var controller
    required property var authPanel
    required property var boundary
    required property var backend
    required property Item targetItem
    required property string selectedState
    required property string captureDirectory
    property bool fastBackend: false
    property int promptSerial: 0

    function capture() {
        const expected = selectedState === "idle" || selectedState === "cancel-during-prompt" || selectedState === "late-response-after-cancel" ? GreeterController.Idle
            : selectedState === "retry" ? GreeterController.Auth
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

    Connections {
        target: root.boundary
        function onPromptSerialChanged() {
            root.promptSerial = root.boundary.promptSerial;
            if (root.selectedState === "success" && root.promptSerial > 1)
                secondResponse.start();
        }
    }

    Timer {
        interval: 1500
        running: root.selectedState !== "none"
        repeat: false
        onTriggered: {
            if (root.selectedState === "idle")
                root.capture();
            else {
                if (root.fastBackend && root.backend.requestSessionLaunch() !== false) {
                    console.error("Greetd session launch barrier failed");
                    Qt.quit();
                    return;
                }
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
            else if (root.selectedState === "cancel-during-prompt" || root.selectedState === "late-response-after-cancel") {
                root.controller.returnToIdle();
                afterCancel.start();
            }
            else if (root.selectedState === "retry") {
                root.authPanel.submit();
                afterRetry.start();
            }
            else {
                root.authPanel.submit();
                afterSubmit.start();
            }
        }
    }

    Timer {
        id: afterSubmit
        interval: root.selectedState === "failure" ? (root.fastBackend ? 160 : 470) : 1650
        repeat: false
        onTriggered: root.capture()
    }

    Timer {
        id: secondResponse
        interval: 300
        repeat: false
        onTriggered: {
            if (!root.boundary.responseRequired)
                return;
            root.authPanel.inputField.text = "123456";
            root.authPanel.submit();
        }
    }

    Timer {
        id: afterCancel
        interval: 650
        repeat: false
        onTriggered: root.capture()
    }

    Timer {
        id: afterRetry
        interval: 700
        repeat: false
        onTriggered: root.capture()
    }
}
