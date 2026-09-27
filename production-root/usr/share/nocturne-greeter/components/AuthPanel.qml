pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    property var controller
    property string username: "user"
    property string loginUser: username
    property string promptText: "Enter your password"
    property real scaleFactor: 1
    property bool debugMode: false
    property bool previewShortcutsEnabled: false
    property alias inputField: passwordInput
    readonly property real identityReveal: Math.max(0, Math.min(1, (controller.authReveal - .36) / .64))
    readonly property real fieldReveal: Math.max(0, Math.min(1, (controller.authReveal - .50) * 2))
    readonly property real hintReveal: Math.max(0, Math.min(1, (controller.authReveal - .68) / .32))
    readonly property real failureCopyHandoff: .7
    readonly property bool preparingAuthentication: controller.phase === GreeterController.Authenticating || controller.phase === GreeterController.Success
    readonly property int passwordDotCapacity: Math.max(0, Math.floor((passphraseArea.width - submitButton.width - 18 * root.scaleFactor) / (16 * root.scaleFactor)))
    readonly property int visiblePasswordDots: Math.min(passwordInput.length, passwordDotCapacity)
    function focusInput() {
        passwordInput.forceActiveFocus();
    }
    function clearInput() {
        passwordInput.clear();
    }
    function wakeWithInitialText(text) {
        if (!controller.isIdle)
            return;
        controller.wake();
        if (text.length === 0)
            return;
        passwordInput.insert(passwordInput.cursorPosition, text);
        controller.noteKey();
    }
    function submit(previewSuccess) {
        if (!controller.acceptsKeyboardInput)
            return;
        const submittedSecret = passwordInput.text;
        if (previewSuccess && previewShortcutsEnabled)
            controller.requestPreviewSuccess(username, submittedSecret);
        else
            controller.requestAuthentication(loginUser, submittedSecret);
        passwordInput.clear();
    }
    Column {
        y: (1 - root.identityReveal) * 12
        opacity: root.identityReveal * (1 - root.controller.authenticationTension * .08)
        spacing: 10 * root.scaleFactor
        Text {
            text: "Welcome back,"
            color: "#A6A6B0"
            font.family: "Adwaita Sans"
            font.pixelSize: 15 * root.scaleFactor
        }
        Text {
            width: root.width
            text: root.username
            elide: Text.ElideRight
            color: "#F2F2F3"
            font.family: "Adwaita Sans"
            font.pixelSize: 37 * root.scaleFactor
            font.weight: Font.Normal
            font.letterSpacing: -.6 * root.scaleFactor
        }
    }
    Item {
        id: passphraseArea
        x: (1 - root.fieldReveal) * -9
        y: 110 * root.scaleFactor
        width: parent.width
        height: 60 * root.scaleFactor
        opacity: root.fieldReveal * (1 - root.controller.authenticationTension * .12)
        Item {
            anchors.left: parent.left
            anchors.right: submitButton.left
            anchors.rightMargin: 18 * root.scaleFactor
            height: parent.height
            clip: true
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10 * root.scaleFactor
                Repeater {
                    id: passwordDots
                    objectName: "passwordDots"
                    model: root.visiblePasswordDots
                    delegate: Rectangle {
                        required property int index
                        width: 5 * root.scaleFactor
                        height: width
                        radius: width / 2
                        color: "#F2F2F3"
                        opacity: index === root.visiblePasswordDots - 1 ? .75 + .25 * root.controller.typingPulse : .75
                        scale: index === root.visiblePasswordDots - 1
                               ? 1 + root.controller.typingPulse * .16 : 1
                    }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.promptText
                visible: passwordInput.length === 0
                color: "#92929E"
                font.family: "Adwaita Sans"
                font.pixelSize: 15 * root.scaleFactor
            }
            TextInput {
                id: passwordInput
                anchors.fill: parent
                enabled: root.controller.acceptsKeyboardInput
                activeFocusOnPress: true
                echoMode: TextInput.Password
                maximumLength: 256
                color: "transparent"
                selectionColor: "transparent"
                selectedTextColor: "transparent"
                cursorVisible: false
                inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                Accessible.name: "Password"
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.controller.returnToIdle();
                        event.accepted = true;
                    } else if (root.previewShortcutsEnabled && event.key === Qt.Key_Q && (event.modifiers & Qt.ControlModifier)) {
                        Qt.quit();
                        event.accepted = true;
                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
                        root.submit(true);
                        event.accepted = true;
                    }
                }
                onTextEdited: root.controller.noteKey()
                onAccepted: root.submit()
            }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: passwordInput.activeFocus ? 42 * root.scaleFactor : 18 * root.scaleFactor
            height: 1
            color: passwordInput.activeFocus ? "#A78BFA" : "#34343D"
            opacity: 1 - root.controller.authenticationTension * .18
            Behavior on width {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 160
                }
            }
        }
        IconButton {
            id: submitButton
            objectName: "submitButton"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 44 * root.scaleFactor
            height: width
            icon: "../assets/icons/arrow.svg"
            label: "Unlock"
            scaleFactor: root.scaleFactor
            enabled: root.controller.acceptsKeyboardInput
            onClicked: root.submit()
        }
    }
    Text {
        y: 196 * root.scaleFactor + (1 - root.hintReveal) * 8
        width: parent.width
        wrapMode: Text.WordWrap
        opacity: root.hintReveal * (root.controller.phase === GreeterController.Failure ? Math.max(0, 1 - root.controller.failureProgress / root.failureCopyHandoff) : root.preparingAuthentication ? Math.abs(1 - 2 * root.controller.authenticationTension) : 1 - root.controller.authenticationTension)
        text: root.controller.phase === GreeterController.Failure && !root.controller.failureResolving ? "Preparing your space" : root.preparingAuthentication && root.controller.authenticationTension >= .5 ? "Preparing your space" : "Enter to unlock  ·  Esc to return"
        color: "#777781"
        font.family: "Adwaita Sans"
        font.pixelSize: 12 * root.scaleFactor
    }
    Text {
        y: 196 * root.scaleFactor + (1 - root.hintReveal) * 8
        width: parent.width
        wrapMode: Text.WordWrap
        opacity: root.hintReveal * (root.controller.phase === GreeterController.Failure ? Math.max(0, Math.min(1, (root.controller.failureProgress - root.failureCopyHandoff) / (1 - root.failureCopyHandoff))) : 0)
        text: "Couldn't unlock. Try again."
        color: "#A78BFA"
        font.family: "Adwaita Sans"
        font.pixelSize: 12 * root.scaleFactor
    }
    Text {
        y: 238 * root.scaleFactor
        width: parent.width
        visible: root.debugMode
        text: "Preview only · Ctrl+Enter: success\n" + root.controller.statusMessage
        color: "#A6A6B0"
        font.family: "Adwaita Mono"
        font.pixelSize: 10 * root.scaleFactor
    }
}
