import AppKit

enum WindowManagerError: Error {
    case windowNotFound
    case positionFailed
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

        let script = NSAppleScript(source: """
        tell application "\(appName)"
            activate
            set bounds of front window to {\(x1), \(y1), \(x2), \(y2)}
        end tell
        """)

        var error: NSDictionary?
        script?.executeAndReturnError(&error)

        if let error {
            let errMsg = error[NSAppleScript.errorMessage] as? String ?? "unknown"
            NSLog("[Pane] set bounds failed for \(appName): \(errMsg)")
            throw WindowManagerError.positionFailed
        }

        NSLog("[Pane] Positioned \(appName) to {\(x1), \(y1), \(x2), \(y2)}")
    }
}
