# Production-like tree (local simulation only)

`scripts/stage-isolated-greeter.sh` generates `usr/share/nocturne-greeter/`
inside this project. It contains the shared visual QML, assets, QSB, and the
`GreetdAuthenticator.qml` adapter. The mock backend and runnable harness shell
are added to a temporary copy by `scripts/run-isolated-greeter.sh`.

The staged adapter does not provide a configured greeter entrypoint and never
calls `Greetd.launch()`.

This directory is not an installable package or an active login configuration.
Nothing here is copied to the host's `/usr` or `/etc`.
