import AppKit

struct ExecutionResult {
    var successes: [String] = []
    var errors: [String] = []
    var isFullSuccess: Bool { errors.isEmpty && !successes.isEmpty }
}

final class LayoutExecutor {
    private let appLauncher = AppLauncher()
    private let windowManager = WindowManager()
    private let spaceManager = SpaceManager()

    func execute(_ layout: Layout, onDisplay displayIndex: Int = 0) async -> ExecutionResult {
        paneDebug("[Pane] Executing layout: \(layout.name) on display \(displayIndex)")

        let screens = NSScreen.screens
        let targetScreen = displayIndex < screens.count ? screens[displayIndex] : screens[0]
        let screenFrame = targetScreen.visibleFrame
        let currentSpace = spaceManager.currentSpaceID()
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 900

        var result = ExecutionResult()

        for zone in layout.zones {
            let frame: CGRect
            if zone.position == .custom, let custom = zone.customFrame {
                frame = custom.rect(in: screenFrame)
            } else {
                frame = zone.position.frame(in: screenFrame)
            }
            let x1 = Int(frame.origin.x)
            let y1 = Int(primaryHeight - frame.origin.y - frame.size.height)
            let x2 = x1 + Int(frame.size.width)
            let y2 = y1 + Int(frame.size.height)
            let bounds = "{\(x1), \(y1), \(x2), \(y2)}"

            paneDebug("[Pane] Zone: bundleID=\(zone.appBundleID) bounds=\(bounds)")
            do {
                let app = try await appLauncher.launchIfNeeded(bundleID: zone.appBundleID)
                let appName = app.localizedName ?? zone.appBundleID

                if Self.isTerminal(bundleID: zone.appBundleID) {
                    try await positionTerminal(
                        bundleID: zone.appBundleID,
                        appName: appName,
                        path: zone.path,
                        commands: zone.commands ?? [],
                        bounds: bounds
                    )
                } else {
                    try await positionWithAX(app: app, frame: frame)
                }

                // Move to current space if needed
                if let spaceID = currentSpace {
                    let wids = windowIDs(for: app)
                    if !wids.isEmpty {
                        spaceManager.moveWindows(wids, toSpace: spaceID)
                    }
                }

                paneDebug("[Pane]   OK: \(appName)")
                result.successes.append(appName)
            } catch {
                let appName = NSWorkspace.shared.runningApplications
                    .first { $0.bundleIdentifier == zone.appBundleID }?.localizedName ?? zone.appBundleID
                let msg = "\(appName): \(error.localizedDescription)"
                result.errors.append(msg)
                paneDebug("[Pane]   FAILED: \(error)")
            }
        }
        paneDebug("[Pane] Done: \(result.successes.count) ok, \(result.errors.count) failed")
        return result
    }

    private static let terminalBundleIDs: Set<String> = [
        "com.googlecode.iterm2",
        "com.apple.Terminal",
    ]

    private static func isTerminal(bundleID: String) -> Bool {
        if terminalBundleIDs.contains(bundleID) { return true }
        return CustomAppsStore().loadAll().first { $0.bundleID == bundleID }?.isTerminal ?? false
    }

    private func positionTerminal(
        bundleID: String,
        appName: String,
        path: String?,
        commands: [String],
        bounds: String
    ) async throws {
        let script = makeScript(
            bundleID: bundleID,
            appName: appName,
            path: path,
            commands: commands,
            bounds: bounds
        )
        try? await Task.sleep(nanoseconds: 300_000_000)

        var scriptError: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&scriptError)
        if let scriptError {
            let errMsg = scriptError[NSAppleScript.errorMessage] as? String ?? "unknown"
            paneDebug("[Pane]   Script failed: \(errMsg)")
            throw WindowManagerError.positionFailed(errMsg)
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
    }

    private func positionWithAX(app: NSRunningApplication, frame: CGRect) async throws {
        app.activate()
        _ = await AXWindowPositioner.awaitWindow(app: app, timeout: 3.0)
        try? await Task.sleep(nanoseconds: 200_000_000)
        do {
            try AXWindowPositioner.position(app: app, to: frame)
        } catch {
            paneDebug("[Pane]   AX position failed: \(error)")
            throw error
        }
    }

    private func makeScript(bundleID: String, appName: String, path: String?, commands: [String], bounds: String) -> String {
        let hasPath = path != nil && !path!.isEmpty
        let escapedPath = (path ?? "").replacingOccurrences(of: "\"", with: "\\\"")
        let escapedAppName = appName.replacingOccurrences(of: "\"", with: "\\\"")
        let cleanCommands = commands.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        switch bundleID {
        case "com.googlecode.iterm2":
            var lines: [String] = []
            lines.append("tell application \"iTerm\"")
            lines.append("    activate")
            lines.append("    set newWindow to (create window with default profile)")
            lines.append("    tell current session of newWindow")
            if hasPath {
                lines.append("        write text \"cd \(escapedPath) && clear\"")
            }
            for cmd in cleanCommands {
                let esc = cmd.replacingOccurrences(of: "\"", with: "\\\"")
                lines.append("        write text \"\(esc)\"")
            }
            lines.append("    end tell")
            lines.append("    set bounds of newWindow to \(bounds)")
            lines.append("end tell")
            return lines.joined(separator: "\n")

        case "com.apple.Terminal":
            var lines: [String] = []
            lines.append("tell application \"Terminal\"")
            lines.append("    activate")
            if hasPath {
                lines.append("    do script \"cd \(escapedPath) && clear\"")
            } else {
                lines.append("    do script \"\"")
            }
            for cmd in cleanCommands {
                let esc = cmd.replacingOccurrences(of: "\"", with: "\\\"")
                lines.append("    do script \"\(esc)\" in front window")
            }
            lines.append("    set bounds of front window to \(bounds)")
            lines.append("end tell")
            return lines.joined(separator: "\n")

        default:
            return """
            tell application "\(escapedAppName)"
                activate
                try
                    make new document
                end try
                delay 0.3
                if (count of windows) > 0 then
                    set bounds of front window to \(bounds)
                end if
            end tell
            """
        }
    }
}
