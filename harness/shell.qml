import QtQuick
import Quickshell
import "components"
import "mock"

ShellRoot {
    id: root

    Component.onCompleted: Quickshell.watchFiles = false

    MockIdentity {
        id: fixture
    }

    MockAuthenticator {
        id: mockBackend
        outcome: Quickshell.env("NOCTURNE_MOCK_OUTCOME") === "success" ? "success" : "failure"
    }

    GreeterWindow {
        id: greeter
        username: fixture.displayName
        loginUser: fixture.userId
        hostname: fixture.hostname
        statusModel: fixture
        promptText: boundary.promptText
        previewShortcutsEnabled: false
        sessionContextText: "Selected session · mock"
        powerUnavailableText: "Unavailable in isolated harness"
        windowTitle: "Nocturne Umbra · Isolated"
    }

    AuthenticatorBridge {
        id: boundary
        controller: greeter.controller
        backend: mockBackend
        selectedUser: fixture.userId
        selectedSession: fixture.sessionId
    }

    HarnessScenario {
        controller: greeter.controller
        authPanel: greeter.authPanel
        targetItem: greeter.captureTarget
        selectedState: Quickshell.env("NOCTURNE_HARNESS_SCENARIO") || "none"
        captureDirectory: Quickshell.env("NOCTURNE_HARNESS_CAPTURE_DIR") || ""
    }

    HarnessMetrics {
        greeter: greeter
        metricsEnabled: Quickshell.env("NOCTURNE_HARNESS_METRICS") === "1"
    }
}
