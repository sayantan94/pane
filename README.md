![Pane](assets/banner.svg)

---

**Pane** is a macOS menu bar app that launches and arranges terminal windows in configurable layouts.

Pick a grid template, assign terminals to zones with optional directory paths, and trigger it. Pane opens new windows and tiles them into position. Works across multiple monitors.

![Screenshot](assets/img.png)

---

### Install

**Download the DMG** from [Releases](https://github.com/sayantan94/pane/releases/latest), open it, drag Pane to Applications. No Xcode needed.

On first launch, macOS may say it can't verify the app. Just right-click on Pane.app and choose Open.

**Or build from source** if you prefer:

```bash
xcode-select --install   # skip if you already have it
git clone https://github.com/sayantan94/pane.git
cd pane
make install
open /Applications/Pane.app
```

### Getting started

Click the menu bar icon and hit + to create a layout. Pick a grid (halves, thirds, quarters), assign a terminal and directory path to each zone, save it.

Click the layout name to run it. If you have multiple monitors, it'll ask which display to use.

macOS will ask to allow Automation for your terminal app the first time. Just allow it.

Layouts are stored as JSON in `~/.config/pane/layouts/`.

### License

MIT
