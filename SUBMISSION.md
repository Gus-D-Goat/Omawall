# Omawall Submission Notes

This file records the repository checks for plugin review.

## Repository

- The source repository is public: <https://github.com/GustavoDGoat/omawall->
- The repository root contains `manifest.json`, `BarWidget.qml`, `Panel.qml`, `README.md`, `LICENSE`, and `preview.png`.
- Installation, update, usage, and removal instructions are documented in [`README.md`](README.md).

## License and Dependencies

- The plugin is distributed under the MIT license in [`LICENSE`](LICENSE).
- Runtime dependencies are Omarchy Quattro and Quickshell, which are already provided by Omarchy.
- The plugin invokes only Omarchy's `omarchy-theme-bg-next` and `omarchy-notification-send` commands.
- No Rust, daemon, systemd service, second Quickshell process, network service, or third-party runtime package is required.

## Ownership and Assets

I, GustavoDGoat, own or have permission to submit the Omawall source code and `preview.png` asset in this repository.

## Configuration Consent

Omawall does not overwrite user configuration without an explicit user action:

- Installation does not enable the plugin automatically.
- Enabling, disabling, and removing the plugin use explicit Omarchy commands.
- Changing the interval or active state in the Omawall panel explicitly persists those selected values through Omarchy's inline settings API.
- Startup only reads the existing settings and applies defaults in memory when values are absent.
- Omawall does not create a separate configuration database, daemon, service, or background writer.
