![Pane](assets/banner.svg)

---

**Pane** is a macOS menu bar app that launches and arranges terminal windows in configurable layouts.

Pick a grid template, assign terminals to zones with optional directory paths, and trigger it — Pane opens new windows and tiles them into position. Works across multiple monitors.

![Screenshot](assets/img.png)

---

### Install

**Option 1: Download DMG** (no Xcode needed)

1. Download `Pane.dmg` from [Releases](https://github.com/sayantan94/pane/releases/latest)
2. Open the DMG and drag Pane to Applications
3. First launch: right-click Pane.app → **Open** (bypasses Gatekeeper since the app isn't notarized)

**Option 2: Build from source**

Requires Xcode Command Line Tools:

```bash
xcode-select --install   # skip if already installed
git clone https://github.com/sayantan94/pane.git
cd pane
make install
open /Applications/Pane.app
```

### First Launch

- macOS will ask to allow Automation for your terminal app (iTerm, Terminal, etc.) — click **OK**
- If you see "can't be opened because Apple cannot check it for malicious software": right-click → Open

### Usage

1. Click the menu bar icon
2. Click **+** to create a layout
3. Pick a grid (halves, thirds, quarters)
4. Assign a terminal and directory path to each zone
5. Click the layout name to trigger it
6. With multiple monitors: pick which display to use

Layouts are stored as JSON in `~/.config/pane/layouts/`.

### License

MIT
