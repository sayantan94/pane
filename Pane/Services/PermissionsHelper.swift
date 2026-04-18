import AppKit

enum PermissionsHelper {
    static func isAutomationError(_ message: String) -> Bool {
        let lower = message.lowercased()
        return lower.contains("not authorized")
            || lower.contains("apple events")
            || lower.contains("procnotpermitted")
            || message.contains("-1743")
    }

    static func isAccessibilityError(_ message: String) -> Bool {
        let lower = message.lowercased()
        return lower.contains("accessibility permission")
    }

    static func openAutomationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
