# Greetd protocol integration 0.7

## Scope and result

Nocturne 0.7 adds an authentication adapter for the installed
`Quickshell.Services.Greetd` QML API and exercises that API against a local,
unprivileged protocol fixture inside the existing nested KWin harness. The
fixture implements only the IPC messages needed by the scenarios; it does not
run greetd, PAM, or session commands.

**0.7 does not perform real PAM authentication and does not replace the host display manager.**

The host's `display-manager.service` was queried read-only during this work and
reported `plasmalogin.service` active/running. No greetd executable was found.
The host service was not changed.

## Quickshell API found locally

The installed package is Quickshell **0.3.1-1.1**. The installed QML type
information is
`/usr/lib/qt6/qml/Quickshell/Services/Greetd/quickshell-service-greetd.qmltypes`;
the matching upstream source inspected was tag `v0.3.1`. The QML import is:

```qml
import Quickshell.Services.Greetd
```

It provides the non-creatable singleton `Greetd` and enum `GreetdState`.

| API surface | Installed API |
| --- | --- |
| Read-only properties | `available: bool`, `state: GreetdState`, `user: string` |
| Methods | `createSession(user: string)`, `cancelSession()`, `respond(response: string)`, `launch(command: string[], environment: string[], quit: bool)` with shorter overloads |
| Authentication signals | `authMessage(message, error, responseRequired, echoResponse)`, `authFailure(message)`, `readyToLaunch()` |
| Other signals | `launched()`, `error(error)`, `stateChanged()`, `userChanged()` |
| States | `Inactive`, `Authenticating`, `ReadyToLaunch`, `Launching`, `Launched` |

`createSession(user)` begins authentication through the configured greetd
connection when `available` is true and the state is `Inactive`. `state` moves
through `Authenticating` while challenges are handled, then `ReadyToLaunch` on
successful authentication. `user` reports the API's current greetd user.
During `Authenticating`, `authMessage` can request a response or report a
message that needs no response. `respond()` submits a response only for an
outstanding challenge. `authFailure` is the authentication rejection event;
`error(error)` reports a general API/connection error. The adapter maps the
former to the controller's authentication FAILURE and the latter to a
fail-closed backend error. `stateChanged` and `userChanged` report property
updates.

`readyToLaunch` means authentication succeeded and a session may be launched;
it does not mean that a session has started. `launch()` sends a separate
session-start request and advances through `Launching` to `Launched`, after
which Quickshell can quit according to the `quit` argument. The API's
`launched()` signal is unexpected in this adapter and is treated as an error.
The 0.7 adapter never calls `launch()`.

In the inspected Quickshell implementation, informational and error
`authMessage`s without a response are acknowledged by the client itself. The
adapter displays them and does not call `respond()` for them. Challenges that
require input are delivered as `responseRequired=true`, with `echoResponse`
preserved. The API uses the `GREETD_SOCK` environment variable to locate the
socket. The installed API has no per-attempt identifier and no signal stating
that cancellation has fully completed.

The internal adapter carries `userId` and the selected `sessionId` as attempt
context. The installed API's `createSession()` accepts only the user; it has no
session-selection argument. The adapter does not turn the selected session
into a command or launch request.

## greetd IPC is a different layer

The greetd IPC protocol is carried over a Unix stream socket selected by
`GREETD_SOCK`. Each message is UTF-8 JSON preceded by a 32-bit native-endian
length. The relevant requests are `create_session`,
`post_auth_message_response`, `cancel_session`, and `start_session`. Authentication
messages distinguish `visible`, `secret`, `info`, and `error`; an
`auth_error` response indicates rejected authentication, while a generic error
is a protocol/operation error. A successful authentication response makes the
daemon ready to accept `start_session`. This IPC shape comes from
`greetd-ipc(7)`; it is not the same API as Quickshell's QML signals and methods.

## Internal contract and flow

`GreeterController` remains unaware of greetd. `AuthenticatorBridge` owns the
attempt generation and maps either the mock or the greetd adapter into these
events:

| Internal operation/event | Meaning |
| --- | --- |
| `begin(user, session, generation)` | Begin an attempt with the selected identity and session context |
| `prompt(text, responseRequired, echoResponse, generation)` | Present a response challenge and its echo mode |
| `message(text, error, generation)` | Present information/error that does not request a response |
| `respond(value, generation)` | Submit only for the active response-required prompt |
| `cancel(generation)` | Cancel the matching attempt |
| `failure(text, generation)` | Authentication rejection; enter the existing FAILURE motion |
| `readyToLaunch(generation)` | Authentication is ready; enter the existing SUCCESS motion |
| `backendError(text, generation)` | Adapter/socket/state error; enter FAILURE and allow Escape/restart handling |

```mermaid
flowchart TD
    A[WAKE] --> B[begin user and session context]
    B --> C[AUTH prompt with response mode]
    C --> D[submit response]
    D --> C
    D --> E[AUTHENTICATING informational/error message]
    E --> C
    D --> F[authentication failure]
    F --> G[FAILURE then retry]
    D --> H[readyToLaunch]
    H --> I[SUCCESS animation]
    I --> J[black]
    J -. no 0.7 launch call .-> K[session not started]
    C --> L[Escape/cancel]
    L --> A
```

The bridge increments an internal generation when an attempt begins and
invalidates that generation on cancellation. Every backend event carries its
generation; events from an old attempt are ignored. Repeated submissions are
ignored after the current response-required flag is cleared. Prompt serials
allow the UI/tests to distinguish successive challenges. Duplicate terminal
failure events cannot trigger a second failure transition after the attempt is
closed. Failure can retry through the same bridge without putting greetd states
into the controller.

The panel stays within the existing Umbra composition. Secret prompts use
masked text; visible prompts use normal text. A prompt is not assumed to be a
password. Informational/error messages have no submit semantics. The input is
cleared on submit, cancellation, and state changes as appropriate; the mock
does not retain or compare supplied values. The UI caps a response at 256
characters.

## Secrets and memory limits

The adapter, bridge, mock, and protocol fixture do not log or include response
values in diagnostics. The fixture counts message types only and deliberately
does not inspect, retain, or echo the `response` field. The local Quickshell
Greetd implementation's debug output was observed to redact the response as
`<CENSORED>`. Test assertions observe a no-argument submission signal instead
of storing signal arguments that contain input.

Clearing a `TextInput` and dropping QML/JavaScript string references reduces
retention, but QML/JS strings do not provide a secure memory-zeroization
guarantee. This implementation does not claim one.

## Cancellation limitation

The Quickshell singleton does not tag signals with attempt IDs. Its
`cancelSession()` method changes the singleton state, but the public API does
not report when all callbacks from that connection are drained. The adapter
therefore fails closed after cancelling a real Greetd attempt: it marks that
adapter instance poisoned, ignores further events for the old generation, and
refuses another `begin()` until the greeter process is restarted. This avoids
assigning a late singleton signal to a new attempt. The mock can exercise
Escape followed by a new attempt because it has explicit generation-tagged
events. A production-quality retry/cancel policy needs a supported correlation
boundary or a process-lifecycle design verified in the future VM phase.

## Launch barrier

`GreetdAuthenticator.requestSessionLaunch()` always returns `false` and emits
only a blocked diagnostic. There is no call to `Greetd.launch()` in the
adapter, bridge, or harness. `readyToLaunch` drives the existing SUCCESS
animation and then black; it is not forwarded to a session launcher.

The local IPC fixture also treats `start_session` as forbidden: it increments
a counter and replies with an error, and it contains no code to execute the
requested command. Every exercised scenario ended with
`start_session=0`. Thus the 0.7 adapter's ready-to-launch behavior was exercised,
and the session-launch boundary was checked without creating a real session.
The fixture-runner also scans the Quickshell log for the OTP canary used by the
multi-prompt scenario and fails if it appears; observed API logs redact
responses as `<CENSORED>`.

## Mock and harness

The mock scenarios include `password-success`, `password-failure`,
`multi-prompt`, `multi-prompt-failure`, `visible-prompt`,
`informational-message`, `error-message`, `cancel-during-prompt`, and
`late-response-after-cancel`. The local protocol fixture supports the same
core protocol scenarios except the mock-only `multi-prompt-failure` variant,
and runs only under the isolated harness.
The harness creates its own Wayland socket, HOME, runtime/cache directories,
and optional session bus, and removes its temporary runtime on normal exit or
Ctrl+C. The fixture is launched inside that temporary runtime. It does not
depend on the host's personal session bus or the host's greetd socket.

Run the deterministic QML and mock tests with:

```sh
./scripts/test-greeter.sh
```

Run the actual installed Quickshell Greetd module against the local IPC fixture
under nested KWin with:

```sh
./scripts/test-greetd-protocol.sh
```

The suite captures FAILURE and then a fresh prompt after the first
`authFailure`; the runner requires at least two `create_session` requests for
that retry case.

Individual fixture runs are also available through
`scripts/run-isolated-greeter.sh --auth-backend greetd-fixture
--auth-scenario <scenario> --scenario <capture-state>`. This runs no host
greetd service.

For real-adapter runs, the harness explicitly calls
`GreetdAuthenticator.requestSessionLaunch()` and requires it to return `false`;
the fixture's `start_session` counter independently verifies that no IPC
launch request was emitted.

The QML test runner cannot load Quickshell's binary service plugin in this
setup. The genuine module/API path is consequently covered by running the
installed `quickshell` executable in the nested harness; the QML tests do not
pretend a mock QML type proves module integration.

## Validation performed

On the installed Quickshell 0.3.1 / Qt 6.11.2 environment, the final run
reported 37 Qt Quick tests passed, with no failures or skips. `qmllint`, the
shader build, `glslangValidator`, `bash -n scripts/*.sh`, staging, and
`git diff --check` passed. The nine nested API/fixture scenarios passed,
including the failure-to-retry case (`create_session=2`) and all with
`start_session=0`. The SUCCESS capture was black. Ctrl+C cleanup was exercised
with both mock and fixture backends; temporary runtime directories were
removed and test logs retained under `logs/isolated-greeter/`. The inspected
Quickshell logs contained censored response fields and no response canary,
binding-loop warning, shader failure, or crash.

## Proof status

**Proved here:** the installed Quickshell 0.3.1 Greetd QML API imports and
executes against the local IPC fixture; its success/failure/prompt/message and
cancel paths reach the adapter; the generation guard, controller transitions,
UI response modes, mock scenarios, nested Wayland isolation, blocked launch
boundary, and black SUCCESS endpoint are covered by available tests/captures.

**Simulated:** the credentials, authentication result, and `readyToLaunch`
result in the fixture/mock. The fixture speaks the local greetd IPC shape but
does not authenticate via PAM. Session launch is deliberately blocked.

**Not proved:** real PAM, login of any user, real greetd daemon operation,
seat/DRM ownership, greeter account permissions, real session launch, boot-time
startup, TTY recovery, or operation before a user session exists. Those belong
in an isolated VM in a later phase.

## References

- Installed package and local `quickshell-service-greetd.qmltypes` for the
  exact available API/type signatures.
- [Quickshell 0.3.0 Greetd API reference](https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Greetd/Greetd/)
  and [Quickshell v0.3.1 Greetd QML source](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/services/greetd/qml.hpp).
- [Quickshell v0.3.1 greetd connection implementation](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/services/greetd/connection.cpp).
- [Upstream greetd IPC protocol specification, `greetd-ipc(7)`](https://github.com/kennylevinsen/greetd/blob/master/man/greetd-ipc-7.scd).
