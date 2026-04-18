import AppKit

final class AppIconProvider {
    static let shared = AppIconProvider()
    private var cache: [String: NSImage] = [:]
    private let lock = NSLock()

    func icon(for bundleID: String) -> NSImage? {
        guard !bundleID.isEmpty else { return nil }
        lock.lock(); defer { lock.unlock() }
        if let cached = cache[bundleID] { return cached }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache[bundleID] = icon
        return icon
    }
}
