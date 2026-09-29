import QtQuick

Item {
    id: root
    visible: false

    property var controller
    property var backend
    property string selectedUser: ""
    property string selectedSession: ""
    property string promptText: "Enter your password"
    property bool responseRequired: false
    property bool echoResponse: false
    property int promptSerial: 0
    property int generation: 0
    property bool attemptActive: false
    property bool retryAfterFailure: false

    readonly property bool sessionLaunchAllowed: false

    function beginIfNeeded(userHint) {
        if (attemptActive)
            return true;

        if (!backend || typeof backend.begin !== "function") {
            controller.rejectAuthentication("Authentication backend unavailable");
            return false;
        }

        generation += 1;
        const thisGeneration = generation;
        const userId = userHint || selectedUser;
        responseRequired = false;
        echoResponse = false;
        attemptActive = true;
        retryAfterFailure = false;

        const started = backend.begin(userId, selectedSession, thisGeneration);
        if (started === false && generation === thisGeneration) {
            attemptActive = false;
            responseRequired = false;
            controller.rejectAuthentication("Authentication backend unavailable");
            return false;
        }
        return true;
    }

    function cancelAttempt() {
        if (!attemptActive)
            return;

        const cancelledGeneration = generation;
        generation += 1;
        attemptActive = false;
        retryAfterFailure = false;
        responseRequired = false;
        echoResponse = false;

        if (backend && typeof backend.cancel === "function")
            backend.cancel(cancelledGeneration);
    }

    function requestSessionLaunch() {
        // 0.7 ends at readyToLaunch. There is deliberately no launch path here.
        return false;
    }

    Connections {
        target: root.controller

        function onPhaseChanged() {
            if (!root.controller || !root.backend)
                return;

            if (root.controller.phase === GreeterController.Wake)
                root.beginIfNeeded();
            else if (root.controller.phase === GreeterController.ReturnToIdle
                     || root.controller.phase === GreeterController.Idle)
                root.cancelAttempt();
            else if (root.controller.phase === GreeterController.Auth && root.retryAfterFailure)
                root.beginIfNeeded();
        }

        function onAuthenticationRequested(username, response) {
            if (!root.attemptActive && !root.beginIfNeeded(username))
                return;
            if (!root.responseRequired || !root.backend || typeof root.backend.respond !== "function")
                return;

            const thisGeneration = root.generation;
            root.responseRequired = false;
            root.echoResponse = false;
            root.backend.respond(response, thisGeneration);
            response = "";
        }
    }

    Connections {
        target: root.backend

        function onPrompt(message, responseRequired, echoResponse, attemptGeneration) {
            if (!root.attemptActive || attemptGeneration !== root.generation)
                return;
            if (!responseRequired)
                return;

            root.promptText = message;
            root.responseRequired = true;
            root.echoResponse = echoResponse;
            root.promptSerial += 1;
            root.controller.presentPrompt(message, true, echoResponse);
        }

        function onMessage(message, error, attemptGeneration) {
            if (!root.attemptActive || attemptGeneration !== root.generation)
                return;
            root.controller.presentMessage(message, error);
        }

        function onFailure(message, attemptGeneration) {
            if (!root.attemptActive || attemptGeneration !== root.generation)
                return;

            root.attemptActive = false;
            root.responseRequired = false;
            root.echoResponse = false;
            root.retryAfterFailure = true;
            root.controller.rejectAuthentication(message);
        }

        function onReadyToLaunch(attemptGeneration) {
            if (!root.attemptActive || attemptGeneration !== root.generation)
                return;

            root.responseRequired = false;
            root.echoResponse = false;
            root.retryAfterFailure = false;
            root.controller.completeAuthentication();
        }

        function onBackendError(message, attemptGeneration) {
            if (!root.attemptActive || attemptGeneration !== root.generation)
                return;

            root.attemptActive = false;
            root.responseRequired = false;
            root.echoResponse = false;
            root.retryAfterFailure = false;
            root.controller.rejectAuthentication(message);
        }
    }
}
