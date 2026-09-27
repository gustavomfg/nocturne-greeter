# Production-like tree (local simulation only)

`scripts/stage-isolated-greeter.sh` generates `usr/share/nocturne-greeter/`
inside this project. It contains only shared visual QML, assets, and QSB.
The mock backend and runnable shell are added to a temporary copy by
`scripts/run-isolated-greeter.sh`.

This directory is not an installable package or an active login configuration.
Nothing here is copied to the host's `/usr` or `/etc`.
