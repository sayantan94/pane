# Pane

A macOS menu bar app that launches and arranges workspace layouts.

Configure named layouts — choose a grid arrangement, assign apps to zones with optional URLs and directory paths — then trigger them with a click or keyboard shortcut to launch and tile everything into place.

## Features

- Configure named workspace layouts via a visual editor
- Grid templates: halves, thirds, quarters, two-thirds, full screen
- Assign any app to a zone
- Optional URL for browser zones (opens the URL on trigger)
- Optional directory path for terminal zones (cd's to the path on trigger)
- Global keyboard shortcuts to trigger layouts instantly
- Launches missing apps automatically
- Menu bar app — lightweight, always running, no dock icon
- Launch at login support
- Layout data stored as human-readable JSON in `~/.config/pane/layouts/`

## Requirements

- macOS 13 (Ventura) or later
- Accessibility permission (for window positioning)

## Build

```bash
cd Pane
swift build -c release
```

## Run

```bash
.build/release/Pane
```

Or build with Xcode — open `Package.swift`.

## License

MIT
