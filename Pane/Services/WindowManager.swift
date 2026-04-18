import AppKit

enum WindowManagerError: Error, LocalizedError {
    case windowNotFound
    case positionFailed(String)

    var errorDescription: String? {
        switch self {
        case .windowNotFound: return "No window found"
        case .positionFailed(let msg): return msg
        }
    }
}

final class WindowManager {

    func positionWindow(of app: NSRunningApplication, to frame: CGRect) throws {
        guard let appName = app.localizedName else {
            throw WindowManagerError.windowNotFound
        }

        let primaryHeight = NSScreen.screens.first?.frame.height ?? 900
        let x1 = Int(frame.origin.x)
        let y1 = Int(primaryHeight - frame.origin.y - frame.size.height)
        let x2 = x1 + Int(frame.size.width)
        let y2 = y1 + Int(frame.size.height)

        // Try app-specific AppleScript first, fall back to generic
        let script: String
        switch app.bundleIdentifier {
        case "com.googlecode.iterm2":
            script = """
            tell application "iTerm"
                activate
                if (count of windows) > 0 then
                    set bounds of front window to {\(x1), \(y1), \(x2), \(y2)}
                else
                    error "No iTerm windows open"
                end if
            end tell
            """
        default:
            script = """
            tell application "\(appName)"
                activate
                if (count of windows) > 0 then
                    set bounds of front window to {\(x1), \(y1), \(x2), \(y2)}
                else
                    error "No windows open for \(appName)"
                end if
            end tell
            """
        }

        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)

        if let error {
            let errMsg = error[NSAppleScript.errorMessage] as? String ?? "unknown"
            paneDebug("[Pane] set bounds failed for \(appName): \(errMsg)")
            throw WindowManagerError.positionFailed(errMsg)
        }

        paneDebug("[Pane] Positioned \(appName) to {\(x1), \(y1), \(x2), \(y2)}")
    }
}
