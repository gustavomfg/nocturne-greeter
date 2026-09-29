import QtQuick
import Quickshell.Services.Greetd

Item {
    id: root
    visible: false

    // Quickshell 0.3.1 exposes Greetd as a process-wide singleton. Tests may
    // replace it, while the production adapter defaults to the installed API.
    property var api: Greetd
    property bool active: false
    property bool responseRequired: false
    property bool ready: false
    property bool cancellationPoisoned: false
    property int generation: 0
    property string userId: ""
    property string sessionId: ""
    property string promptText: "Enter your password"
    property bool echoResponse: false

    readonly property bool safeMode: true

    signal prompt(string message, bool responseRequired, bool echoResponse, int attemptGeneration)
    signal message(string message, bool error, int attemptGeneration)
    signal failure(string message, int attemptGeneration)
    signal readyToLaunch(int attemptGeneration)
    signal backendError(string message, int attemptGeneration)
    signal launchBlocked(string message)

    function begin(user, session, attemptGeneration) {
        if (cancellationPoisoned) {
            backendError("Greetd attempt cancelled; restart the greeter before retrying", attemptGeneration);
            return false;
        }
        if (!api || !api.available) {
            backendError("Greetd socket is unavailable", attemptGeneration);
            return false;
        }
        if (api.state !== GreetdState.Inactive) {
            backendError("Greetd is already handling a session", attemptGeneration);
            return false;
        }
        if (!user || user.length === 0) {
            backendError("No user was selected for authentication", attemptGeneration);
            return false;
        }

        generation = attemptGeneration;
        userId = user;
        sessionId = session || "";
        active = true;
        ready = false;
        responseRequired = false;
        echoResponse = false;
        promptText = "Enter your password";
        api.createSession(userId);
        return true;
    }

    function respond(response, attemptGeneration) {
        if (!active || ready || !responseRequired || attemptGeneration !== generation)
            return false;
        if (!api || api.state !== GreetdState.Authenticating)
            return false;

        responseRequired = false;
        echoResponse = false;
        api.respond(response);
        response = "";
        return true;
    }

    function cancel(attemptGeneration) {
        if (!active || attemptGeneration !== generation)
            return;

        active = false;
        ready = false;
        responseRequired = false;
        echoResponse = false;
        cancellationPoisoned = true;

        if (api && api.available) {
            // The installed API has no attempt ID or cancel-completed signal.
            // Fail closed instead of reusing its singleton connection after a
            // cancellation, where a late event cannot be assigned safely.
            api.cancelSession();
        }
    }

    function requestSessionLaunch() {
        launchBlocked("Session launch is disabled in Nocturne Greeter 0.7");
        return false;
    }

    Connections {
        target: root.api

        function onAuthMessage(text, error, requiresResponse, echoResponse) {
            if (!root.active || root.ready)
                return;
            if (root.api.state !== GreetdState.Authenticating)
                return;

            if (requiresResponse) {
                if (error) {
                    root.active = false;
                    root.responseRequired = false;
                    root.echoResponse = false;
                    root.backendError("Greetd returned an invalid challenge", root.generation);
                    return;
                }
                root.responseRequired = true;
                root.promptText = text;
                root.echoResponse = echoResponse;
                root.prompt(text, true, echoResponse, root.generation);
            } else {
                // Quickshell's Greetd client acknowledges informational and
                // recoverable error messages itself; the UI must not respond.
                root.message(text, error, root.generation);
            }
        }

        function onAuthFailure(text) {
            if (!root.active)
                return;
            root.active = false;
            root.ready = false;
            root.responseRequired = false;
            root.echoResponse = false;
            root.failure(text, root.generation);
        }

        function onReadyToLaunch() {
            if (!root.active || root.api.state !== GreetdState.ReadyToLaunch)
                return;
            root.ready = true;
            root.responseRequired = false;
            root.echoResponse = false;
            root.readyToLaunch(root.generation);
        }

        function onError(text) {
            if (!root.active)
                return;
            root.active = false;
            root.ready = false;
            root.responseRequired = false;
            root.echoResponse = false;
            root.backendError(text, root.generation);
        }

        function onLaunched() {
            // This adapter never requests launch(). Reaching this signal would
            // mean another component bypassed the 0.7 launch barrier.
            root.active = false;
            root.ready = false;
            root.responseRequired = false;
            root.echoResponse = false;
            root.backendError("Unexpected session launch acknowledgement", root.generation);
        }
    }
}
