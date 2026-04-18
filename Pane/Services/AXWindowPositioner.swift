import AppKit
import ApplicationServices

enum AXWindowPositioner {
    static func position(app: NSRunningApplication, to frame: CGRect) throws {
        guard AXIsProcessTrusted() else {
            throw WindowManagerError.positionFailed("Accessibility permission is required to position this app. Open System Settings → Privacy & Security → Accessibility and enable Pane.")
        }

        let primaryHeight = NSScreen.screens.first?.frame.height ?? 900
        // AX uses top-left origin on the primary screen. Incoming frame is in
        // NSScreen coords (bottom-left origin).
        var pos = CGPoint(
            x: frame.origin.x,
            y: primaryHeight - frame.origin.y - frame.size.height
        )
        var size = frame.size

        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        var winsRef: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &winsRef)
        guard status == .success,
              let windows = winsRef as? [AXUIElement],
              let targetWindow = pickWindow(from: windows)
        else {
            throw WindowManagerError.windowNotFound
        }

        guard let posVal = AXValueCreate(.cgPoint, &pos),
              let sizeVal = AXValueCreate(.cgSize, &size) else {
            throw WindowManagerError.positionFailed("AXValueCreate failed")
        }

        // Some apps ignore the first set during a pending window animation; set twice.
        let posErr1 = AXUIElementSetAttributeValue(targetWindow, kAXPositionAttribute as CFString, posVal)
        let sizeErr1 = AXUIElementSetAttributeValue(targetWindow, kAXSizeAttribute as CFString, sizeVal)
        AXUIElementSetAttributeValue(targetWindow, kAXPositionAttribute as CFString, posVal)
        AXUIElementSetAttributeValue(targetWindow, kAXSizeAttribute as CFString, sizeVal)

        if posErr1 != .success && sizeErr1 != .success {
            throw WindowManagerError.positionFailed("Window could not be moved (AX error \(posErr1.rawValue)/\(sizeErr1.rawValue)).")
        }
    }

    private static func pickWindow(from windows: [AXUIElement]) -> AXUIElement? {
        // Prefer the main/focused window; fall back to the first visible, non-minimized window.
        for window in windows {
            if boolAttribute(window, kAXMainAttribute) == true { return window }
        }
        for window in windows {
            if boolAttribute(window, kAXMinimizedAttribute) != true { return window }
        }
        return windows.first
    }

    private static func boolAttribute(_ element: AXUIElement, _ attribute: String) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return (value as? Bool)
    }

    static func awaitWindow(app: NSRunningApplication, timeout: TimeInterval = 3.0) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var winsRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &winsRef) == .success,
               let windows = winsRef as? [AXUIElement],
               !windows.isEmpty {
                return true
            }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
        return false
    }
}
