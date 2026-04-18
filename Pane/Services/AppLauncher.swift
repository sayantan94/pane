import AppKit

enum AppLauncherError: Error {
    case appNotFound(String)
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
        let app = try await NSWorkspace.shared.openApplication(at: appURL, configuration: config)

        // Wait for launch
        let deadline = Date().addingTimeInterval(5.0)
        while Date() < deadline {
            if app.isFinishedLaunching {
                try await Task.sleep(nanoseconds: 500_000_000)
                break
            }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        return app
    }

    func openNewWindow(bundleID: String) {
        guard let appName = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?
            .deletingPathExtension().lastPathComponent else { return }

        let script: String
        switch bundleID {
        case "com.googlecode.iterm2":
            script = "tell application \"iTerm\" to create window with default profile"
        case "com.apple.Terminal":
            script = "tell application \"Terminal\" to do script \"\""
        default:
            // Generic: activate the app (it will create/show a window)
            script = """
            tell application "\(appName)"
                activate
                try
                    make new document
                end try
            end tell
            """
        }

        NSLog("[Pane] Creating new window for \(appName)")
        if let s = NSAppleScript(source: script) {
            var error: NSDictionary?
            s.executeAndReturnError(&error)
        }
    }

    func openTerminalAtPath(_ path: String, terminalBundleID: String) {
        let escapedPath = path.replacingOccurrences(of: "\"", with: "\\\"")
        let script: String
        switch terminalBundleID {
        case "com.googlecode.iterm2":
            script = """
            tell application "iTerm"
                create window with default profile
                tell current session of current window
                    write text "cd \(escapedPath) && clear"
                end tell
            end tell
            """
        default:
            script = """
            tell application "Terminal"
                do script "cd \(escapedPath)"
                activate
            end tell
            """
        }

        if let s = NSAppleScript(source: script) {
            var error: NSDictionary?
            s.executeAndReturnError(&error)
        }
    }
}
