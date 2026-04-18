import AppKit
import ApplicationServices

struct SnapshottedWindow {
    let app: NSRunningApplication
    let frame: CGRect
    let cwd: String?
}

final class WindowSnapshotter {
    static func isAccessibilityTrusted(prompt: Bool = false) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func snapshot(onDisplay displayIndex: Int) -> [SnapshottedWindow] {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return [] }
        let targetScreen = displayIndex < screens.count ? screens[displayIndex] : screens[0]
        let screenFrame = targetScreen.frame
        let primaryHeight = screens.first?.frame.height ?? 900

        let customApps = CustomAppsStore().loadAll()
        let allowedBundleIDs = Set(customApps.map { $0.bundleID })

        var results: [SnapshottedWindow] = []
        let running = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular
                && !($0.isTerminated)
                && ($0.bundleIdentifier.map(allowedBundleIDs.contains) ?? false)
        }

        for app in running {
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let axWindows = windowsRef as? [AXUIElement] else { continue }

            var frontmostOnDisplay: (AXUIElement, CGRect)?
            for window in axWindows {
                guard let frame = Self.windowFrame(window) else { continue }
                // Convert AX coordinate (top-left origin on primary screen) to NSScreen global (bottom-left).
                let flipped = CGRect(
                    x: frame.origin.x,
                    y: primaryHeight - frame.origin.y - frame.size.height,
                    width: frame.size.width,
                    height: frame.size.height
                )
                let center = CGPoint(x: flipped.midX, y: flipped.midY)
                if screenFrame.contains(center) {
                    frontmostOnDisplay = (window, flipped)
                    break
                }
            }

            if let (_, flipped) = frontmostOnDisplay {
                let cwd: String? = Self.terminalCWD(bundleID: app.bundleIdentifier ?? "")
                results.append(SnapshottedWindow(app: app, frame: flipped, cwd: cwd))
            }
        }
        return results
    }

    private static func windowFrame(_ window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success else {
            return nil
        }
        var origin = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(posRef as! AXValue, .cgPoint, &origin),
              AXValueGetValue(sizeRef as! AXValue, .cgSize, &size) else {
            return nil
        }
        return CGRect(origin: origin, size: size)
    }

    private static func terminalCWD(bundleID: String) -> String? {
        switch bundleID {
        case "com.googlecode.iterm2":
            let script = """
            tell application "iTerm"
                try
                    return (get variable named "session.path" of current session of current window)
                on error
                    return ""
                end try
            end tell
            """
            return runAppleScriptString(script)
        case "com.apple.Terminal":
            let script = """
            tell application "Terminal"
                try
                    set theTab to selected tab of front window
                    set theTitle to custom title of theTab
                    return ""
                on error
                    return ""
                end try
            end tell
            """
            _ = runAppleScriptString(script)
            return nil
        default:
            return nil
        }
    }

    private static func runAppleScriptString(_ source: String) -> String? {
        var errorDict: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let descriptor = script.executeAndReturnError(&errorDict)
        if errorDict != nil { return nil }
        let value = descriptor.stringValue
        return (value?.isEmpty == false) ? value : nil
    }

    static func proposedZones(from windows: [SnapshottedWindow], onDisplay displayIndex: Int) -> [Zone] {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return [] }
        let target = displayIndex < screens.count ? screens[displayIndex] : screens[0]
        let frame = target.frame
        guard frame.width > 0, frame.height > 0 else { return [] }

        return windows.map { w in
            let rx = (w.frame.origin.x - frame.origin.x) / frame.width
            let ry = (w.frame.origin.y - frame.origin.y) / frame.height
            let rw = w.frame.size.width / frame.width
            let rh = w.frame.size.height / frame.height
            let clamped = CustomFrame(
                x: max(0, min(1, rx)),
                y: max(0, min(1, ry)),
                w: max(0.05, min(1, rw)),
                h: max(0.05, min(1, rh))
            )
            return Zone(
                position: .custom,
                appBundleID: w.app.bundleIdentifier ?? "",
                path: w.cwd,
                displayIndex: displayIndex,
                commands: nil,
                customFrame: clamped,
                spaceIndex: nil
            )
        }
    }
}
