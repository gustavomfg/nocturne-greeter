import QtQuick
import QtTest
import "../components"
import "../harness/mock"

TestCase {
    id: testCase
    name: "NocturneIsolatedHarness"
    when: windowShown
    visible: true
    width: 900
    height: 500

    MockIdentity {
        id: fixture
    }

    GreeterController {
        id: controller
    }

    MockAuthenticator {
        id: backend
        responseDelay: 60
    }

    AuthenticatorBridge {
        id: boundary
        controller: controller
        backend: backend
        selectedUser: fixture.userId
        selectedSession: fixture.sessionId
    }

    AuthPanel {
        id: authPanel
        width: 400
        height: 260
        controller: controller
        username: fixture.displayName
        loginUser: fixture.userId
        promptText: boundary.promptText
        previewShortcutsEnabled: false
    }

    SystemChrome {
        id: isolatedStatus
        width: 800
        height: 40
        controller: controller
    }

    SignalSpy {
        id: authSpy
        target: controller
        signalName: "authenticationRequested"
    }

    SignalSpy {
        id: previewSuccessSpy
        target: controller
        signalName: "previewSuccessRequested"
    }

    Connections {
        target: controller
        function onFocusInputRequested() {
            authPanel.focusInput();
        }
        function onClearInputRequested() {
            authPanel.clearInput();
        }
        function onPhaseChanged() {
            if (controller.phase === GreeterController.Authenticating || controller.phase === GreeterController.Success || controller.phase === GreeterController.Idle)
                testCase.forceActiveFocus();
            else if (controller.phase === GreeterController.Failure)
                authPanel.focusInput();
        }
    }

    function cleanup() {
        backend.cancel();
        backend.outcome = "failure";
        if (!controller.isIdle)
            controller.returnToIdle();
        wait(500);
        authPanel.clearInput();
        authSpy.clear();
        previewSuccessSpy.clear();
    }

    function test_fixtureIsNotHostIdentity() {
        compare(fixture.userId, "umbra-fixture");
        compare(fixture.sessionId, "hyprland-mock");
        verify(fixture.availableSessions.length >= 2);
        verify(!fixture.canPowerOff);
        verify(!fixture.networkAvailable);
        verify(!fixture.audioAvailable);
        verify(!fixture.batteryAvailable);
    }

    function test_secretPromptAndFailure() {
        controller.wake();
        verify(backend.active);
        compare(boundary.promptText, "Enter your password");
        authPanel.inputField.text = "wrong";
        authPanel.submit();
        compare(authSpy.count, 1);
        compare(authSpy.signalArguments[0][0], fixture.userId);
        compare(controller.phase, GreeterController.Authenticating);
        compare(authPanel.inputField.text, "");
        wait(90);
        compare(controller.phase, GreeterController.Failure);
        wait(430);
        compare(controller.phase, GreeterController.Auth);
    }

    function test_mockReadyToLaunchUsesExistingSuccessMotion() {
        backend.outcome = "success";
        controller.wake();
        authPanel.inputField.text = "dummy";
        authPanel.submit();
        wait(90);
        compare(controller.phase, GreeterController.Success);
        compare(previewSuccessSpy.count, 0);
        compare(authPanel.inputField.text, "");
        wait(1450);
        verify(controller.successProgress > .99);
    }

    function test_cancelPreventsLateResult() {
        controller.wake();
        authPanel.inputField.text = "dummy";
        authPanel.submit();
        compare(controller.phase, GreeterController.Authenticating);
        controller.returnToIdle();
        wait(550);
        compare(controller.phase, GreeterController.Idle);
        verify(!backend.active);
        compare(controller.failureProgress, 0);
        compare(controller.successProgress, 0);
    }

    function test_ctrlEnterCannotRequestPreviewSuccess() {
        controller.wake();
        authPanel.focusInput();
        keyClick(Qt.Key_A);
        keyClick(Qt.Key_Return, Qt.ControlModifier);
        compare(previewSuccessSpy.count, 0);
        compare(authSpy.count, 1);
        compare(controller.phase, GreeterController.Authenticating);
    }

    function test_optionalStatusDefaultsDoNotLoadUserServices() {
        compare(isolatedStatus.networkAvailable, false);
        compare(isolatedStatus.audioAvailable, false);
        compare(isolatedStatus.batteryAvailable, false);
    }
}
