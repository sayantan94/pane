# Changelog

## 2.0.0 — 2026-04-18

Pane is now a general window arranger, not just a terminal launcher.

### New

- **Any app, any window.** Non-terminal apps (IntelliJ, VS Code, Cursor, Slack, Notion, Electron apps) are now positioned via the Accessibility API, fixing the old "every window doesn't understand the count message" error for apps that don't speak AppleScript.
- **Capture current windows.** Arrange windows by hand, click *Capture Current Windows*, name it. Pane saves the live positions as a layout with fractional frames that scale across resolutions. Uses `AXUIElement` + `CGWindowList` under the hood.
- **Custom drag-to-resize layouts.** New "Custom" grid option. Drag zones to move, drag the corner handles to resize. Snaps to halves, thirds, and quarters.
- **Auto-apply by display setup.** Tag a layout to auto-run when the same display arrangement returns (e.g. docking back to your external monitor). Backed by a SHA-256 fingerprint of screen name + resolution + count.
- **Per-zone terminal commands.** Add a list of commands to run after `cd` in iTerm or Terminal — `bun dev`, `tail -f log.out`, whatever you start a project with.
- **Visual display picker** for multi-monitor runs. Click the rectangle matching your monitor.
- **First-run WelcomeView** explains Automation permission up front.
- **AccessibilityPrimerView** auto-appears when a layout run hits an AX error, with live polling, a *Re-check* button, and a *Restart Pane* fallback for macOS's TCC cache bug.
- **Manage Apps** gained a dropdown of all installed apps under /Applications, /System/Applications, and ~/Applications. Free-text bundle ID entry still works for edge cases.
- **Richer layout previews** in the menu with real app icons rendered inside each zone.
- **Menu bar status icon** reflects execution state (running, success, error).

### Fixed

- **Info.plist + adhoc re-sign.** Pane.app now ships with an `Info.plist` (stable `CFBundleIdentifier = com.pane.app`, `LSUIElement`, `NSAppleEventsUsageDescription`). The Makefile re-signs adhoc after assembly so macOS can actually read the plist. Before this, every AppleEvent silently failed with "Not authorized to send Apple events" because macOS had no usage description to prompt with.
- **Custom drag compounding bug.** Drag gestures were adding cumulative translation to an already-updated frame each tick, accelerating the zone. Now captures the initial frame on drag start and computes `start + translation` every tick.
- **Move vs resize conflict.** The custom editor's resize handles now live in a separate hit layer so they win over the move gesture on the zone body.

### Requires

- macOS 13+
- Automation permission (prompted automatically on first terminal layout)
- Accessibility permission (required for non-terminal apps; Pane guides you through the grant)

## 1.0.0

- Initial release. Terminal-only workspace launcher with grid layouts, multi-monitor support, and hotkey-ready scaffolding.
