import QtQuick

Item {
    id: root

    property var controller
    visible: false

    Connections {
        target: root.controller

        function onAuthenticationRequested(username, secret) {
            // This preview intentionally discards the submitted passphrase.
            // Replace this adapter with SDDM/PAM before using it as a greeter.
            void username;
            void secret;
            rejectionTimer.restart();
        }

        function onPreviewSuccessRequested() {
            if (root.controller.phase !== GreeterController.Authenticating)
                return;
            rejectionTimer.stop();
            successTimer.restart();
        }

        function onPhaseChanged() {
            if (root.controller.phase !== GreeterController.Authenticating) {
                rejectionTimer.stop();
                successTimer.stop();
            }
        }
    }

    Timer {
        id: rejectionTimer
        // Match the preview's success latency; the delay represents a result, not an idle animation hold.
        interval: 360
        repeat: false

        onTriggered: root.controller.rejectAuthentication("BACKEND OFFLINE · PREVIEW ONLY")
    }

    Timer {
        id: successTimer
        interval: 360
        repeat: false

        onTriggered: root.controller.completePreviewSuccess()
    }
}
