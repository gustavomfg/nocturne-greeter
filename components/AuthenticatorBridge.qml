import QtQuick

Item {
    id: root
    visible: false

    property var controller
    property var backend
    property string selectedUser: ""
    property string selectedSession: ""
    property string promptText: "Enter your password"

    function beginIfNeeded(userId) {
        if (backend && !backend.active)
            backend.begin(userId || selectedUser, selectedSession);
    }

    Connections {
        target: root.controller

        function onPhaseChanged() {
            if (!root.backend)
                return;
            if (root.controller.phase === GreeterController.Wake)
                root.beginIfNeeded();
            else if (root.controller.phase === GreeterController.ReturnToIdle || root.controller.phase === GreeterController.Idle)
                root.backend.cancel();
        }

        function onAuthenticationRequested(username, secret) {
            if (!root.backend)
                return;
            root.beginIfNeeded(username);
            root.backend.respond(secret);
        }
    }

    Connections {
        target: root.backend

        function onPrompt(message, responseRequired, echoResponse, error) {
            // The current visual field is secret-only. Future adapters must handle
            // visible prompts as a distinct UI mode before real authentication.
            if (responseRequired && !echoResponse && !error)
                root.promptText = message;
        }

        function onFailure(message) {
            root.controller.rejectAuthentication(message);
        }

        function onReadyToLaunch() {
            root.controller.completeAuthentication();
        }
    }
}
