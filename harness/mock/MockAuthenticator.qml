import QtQuick

Item {
    id: root
    visible: false

    property bool active: false
    property bool awaitingResult: false
    property string outcome: "failure"
    property int responseDelay: 360

    signal prompt(string message, bool responseRequired, bool echoResponse, bool error)
    signal message(string message, bool error)
    signal failure(string message)
    signal readyToLaunch

    function begin(username, sessionId) {
        void username;
        void sessionId;
        if (active)
            return;
        active = true;
        awaitingResult = false;
        prompt("Enter your password", true, false, false);
    }

    function respond(secret) {
        // Never retain, print, or compare the secret in the harness.
        void secret;
        if (!active || awaitingResult)
            return;
        awaitingResult = true;
        resultTimer.restart();
    }

    function cancel() {
        resultTimer.stop();
        awaitingResult = false;
        active = false;
    }

    Timer {
        id: resultTimer
        interval: root.responseDelay
        repeat: false

        onTriggered: {
            root.active = false;
            root.awaitingResult = false;
            if (root.outcome === "success")
                root.readyToLaunch();
            else
                root.failure("UNLOCK UNAVAILABLE · ISOLATED MOCK");
        }
    }
}
