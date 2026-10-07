# Omawall

Omawall automatically changes your Omarchy wallpaper at the interval you choose.

## Features

- Automatic wallpaper rotation
- When a theme's wallpapers are exhausted, automatically switches to the next theme (alphabetical, wrapping around) and keeps rotating there
- Skipped themes are never auto-selected: White, Rose Pine, Catppuccin Latte, Flexoki Light, Lupine
- Preset intervals from 1 minute to 2 hours
- Pause and resume
- Manual next wallpaper action
- Persistent interval and active state
- Native Omarchy Quattro panel
- No daemon, second shell, network, or external runtime dependency

## Installation

```sh
omarchy plugin add https://github.com/GustavoDGoat/omawall-.git --yes
omarchy plugin enable io.github.GustavoDGoat.omawall
```

The first command installs the public repository without enabling it. The second command is an explicit user choice that adds Omawall to the bar. The plugin is placed in the center bar section by default and starts active with a 10-minute interval.

To update an existing installation:

```sh
omarchy plugin update io.github.GustavoDGoat.omawall --yes
omarchy-shell shell rescanPlugins
```

## Usage

Click the Omawall icon in the bar to open the panel. Choose an interval, pause or resume automatic rotation, or change the wallpaper immediately with **Next wallpaper**. Press Escape to close the panel.

When the panel is open, Omawall shows an approximate countdown. The countdown timer stops when the panel closes.

## Architecture

Omawall is a single `bar-widget` plugin. `BarWidget.qml` owns one native QML timer and starts one short-lived `scripts/next.sh` process when the timer fires. `scripts/next.sh` advances within the current theme exactly like `omarchy-theme-bg-next`, but when the current wallpaper is the last one in the theme it switches to the next eligible theme via `omarchy-theme-set` (which starts that theme on its first wallpaper). `Panel.qml` provides the controls and only runs its low-frequency countdown timer while visible.

Settings are stored through Omarchy's inline bar-widget settings in `~/.config/omarchy/shell.json`. Only the active state and selected interval are persisted.

Omawall does not overwrite user configuration during startup or installation. The shell configuration is changed only when the user explicitly enables or removes the plugin through an Omarchy command, or changes Omawall settings in the panel.

## Performance

While the panel is closed, Omawall does not poll, scan wallpaper directories, watch files, load images, or update a countdown. It waits on the selected QML timer until the next scheduled change.

## Dependencies and Commands

The plugin uses functionality already installed by Omarchy:

- `omarchy-theme-bg-next` to request the next background (via `scripts/next.sh`)
- `omarchy-theme-set` to switch to the next theme once a theme's wallpapers are exhausted (via `scripts/next.sh`)
- `omarchy-notification-send` to report a failed wallpaper change
- Quickshell `Timer`, `Process`, and `execDetached` APIs

No user-controlled value is included in either command. The interval is kept as a numeric QML value and is never passed to a shell command.

## Removal

```sh
omarchy plugin remove io.github.GustavoDGoat.omawall
```

Removing the plugin removes its bar entry. No daemon, service, or separate configuration file is created.

## License

MIT

See [`LICENSE`](LICENSE).

## Submission Checklist

- Public repository: [github.com/GustavoDGoat/omawall-](https://github.com/GustavoDGoat/omawall-)
- Installation and removal instructions are documented above.
- The MIT license is included in [`LICENSE`](LICENSE).
- All external commands and Quickshell APIs are documented above.
- The author, `GustavoDGoat`, owns this plugin and has permission to submit its source and preview asset.
- User configuration is changed only by explicit installation, enable/disable, removal, or panel setting actions.
