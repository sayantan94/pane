import AppKit

enum AppLauncherError: Error {
    case appNotFound(String)
    case launchFailed(String)
    case timeout(String)
}

final class AppLauncher {
    func launchIfNeeded(bundleID: String) async throws -> NSRunningApplication {
        if let running = NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == bundleID })
        {
            running.activate()
            return running
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleID
        ) else {
            throw AppLauncherError.appNotFound(bundleID)
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = false

        let app = try await NSWorkspace.shared.openApplication(
            at: appURL,
            configuration: config
        )

        try await waitForWindow(app: app, timeout: 5.0)

        return app
    }

    func openURL(_ urlString: String, inBrowser bundleID: String) async throws {
        guard let url = URL(string: urlString) else { return }

        let config = NSWorkspace.OpenConfiguration()
        guard let browserURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleID
        ) else {
            throw AppLauncherError.appNotFound(bundleID)
        }

        config.activates = false
        try await NSWorkspace.shared.open(
            [url],
            withApplicationAt: browserURL,
            configuration: config
        )
    }

    func openTerminalAtPath(_ path: String, terminalBundleID: String) {
        let script: String
        switch terminalBundleID {
        case "com.apple.Terminal":
            script = """
            tell application "Terminal"
                do script "cd \(path.replacingOccurrences(of: "\"", with: "\\\""))"
                activate
            end tell
            """
        case "com.googlecode.iterm2":
            script = """
            tell application "iTerm"
                create window with default profile command "cd \(path.replacingOccurrences(of: "\"", with: "\\\"")) && clear"
            end tell
            """
        default:
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-b", terminalBundleID]
            try? process.run()
            return
        }

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    private func waitForWindow(app: NSRunningApplication, timeout: TimeInterval) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !app.isFinishedLaunching {
                try await Task.sleep(nanoseconds: 200_000_000)
                continue
            }

            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var windowRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(
                appElement,
                kAXWindowsAttribute as CFString,
                &windowRef
            )
            if result == .success, let windows = windowRef as? [AXUIElement], !windows.isEmpty {
                return
            }

            try await Task.sleep(nanoseconds: 200_000_000)
        }

        throw AppLauncherError.timeout(app.bundleIdentifier ?? "unknown")
    }
}
