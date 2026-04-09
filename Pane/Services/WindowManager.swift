import ApplicationServices
import AppKit

enum WindowManagerError: Error {
    case noAccessibility
    case windowNotFound
    case positionFailed
}

final class WindowManager {
    func positionWindow(
        of app: NSRunningApplication,
        to frame: CGRect
    ) throws {
        guard AccessibilityHelper.isTrusted else {
            throw WindowManagerError.noAccessibility
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var windowRef: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowRef
        )

        guard windowResult == .success,
              let windows = windowRef as? [AXUIElement],
              let window = windows.first
        else {
            throw WindowManagerError.windowNotFound
        }

        var position = CGPoint(x: frame.origin.x, y: frame.origin.y)
        var size = CGSize(width: frame.size.width, height: frame.size.height)

        guard let positionValue = AXValueCreate(.cgPoint, &position),
              let sizeValue = AXValueCreate(.cgSize, &size)
        else {
            throw WindowManagerError.positionFailed
        }

        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
    }
}
