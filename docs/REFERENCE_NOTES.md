# Reference study

This prototype reuses no third-party source code, shaders, fonts, or image assets. The references informed the component boundaries, preview workflow, and future greeter integration only.

## Themes

- [Keyitdev/sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme) — inspected its theme variants, config-driven background choices, and test-mode workflow. The repository declares GPL-3.0; no code or media was copied.
- [hyprltm/ltmnight-sddm-theme](https://github.com/hyprltm/ltmnight-sddm-theme) — inspected its `Components/` and `Shaders/` split, adaptive layout notes, hostname/session chrome, and shader packaging. The repository declares AGPL-3.0; no code or media was copied.
- [ROXOI SDDM](https://github.com/rajendrapancholi/roxoi-sddm) — inspected the separation of auth, user selection, system buttons, and virtual keyboard components. The repository declares MIT; no code or media was copied.

## Integration and framework docs

- [SDDM theming guide](https://github.com/sddm/sddm/wiki/Theming) — reviewed its `sddm` greeter proxy, login/session/user models, power capability flags, and test mode. This project does not import the SDDM proxy or call its methods yet.
- [Quickshell guide](https://quickshell.outfoxxed.me/docs/guide/introduction/) — used for local `--path` execution, screen-aware windows, composable QML files, event-driven status, and `SystemClock` guidance.
- [Quickshell type reference](https://quickshell.outfoxxed.me/docs/types/) — confirmed the available PipeWire, UPower, and NetworkManager integrations. This prototype reads those states only; it does not change network, audio, or power settings.

## First-pass design choices (historical)

The result keeps the star field sparse, lets the accretion structure carry the purple light, and reserves monospace for compact system labels. It uses installed Fira Sans and JetBrains Mono NL without bundling either font. Animation timing is state-driven; the idle shader clock updates at 8.3 Hz and only speeds up during interaction.

## Second pass — Umbra

The existing architecture and reference study were retained. The visual composition, mark, icon family and analytic sphere/ring shader are original project work. Noto Sans Light and Adwaita Sans replace the previous pairing; monospace is restricted to optional debug text. No source, media or font files from the referenced themes were imported. The hero uses analytic depth intersection and cast shadow rather than video or a runtime 3D dependency. See ART_DIRECTION_REVIEW.md for the observed results and limits.
