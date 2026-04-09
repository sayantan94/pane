import AppKit

final class LayoutExecutor {
    private let appLauncher = AppLauncher()
    private let windowManager = WindowManager()

    static func resolveFrames(zones: [Zone], screens: [CGRect]) -> [CGRect] {
        zones.map { zone in
            let screenIndex = zone.displayIndex < screens.count ? zone.displayIndex : 0
            let screen = screens.isEmpty
                ? CGRect(x: 0, y: 0, width: 1920, height: 1080)
                : screens[screenIndex]
            return zone.position.frame(in: screen)
        }
    }

    func execute(_ layout: Layout) async {
        let screens = NSScreen.screens.map { $0.visibleFrame }
        let frames = Self.resolveFrames(zones: layout.zones, screens: screens)

        for (index, zone) in layout.zones.enumerated() {
            let frame = frames[index]

            do {
                let app = try await appLauncher.launchIfNeeded(bundleID: zone.appBundleID)

                if let url = zone.url {
                    try await appLauncher.openURL(url, inBrowser: zone.appBundleID)
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }

                if let path = zone.path {
                    appLauncher.openTerminalAtPath(path, terminalBundleID: zone.appBundleID)
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }

                try windowManager.positionWindow(of: app, to: frame)
            } catch {
                print("Failed to set up zone \(zone.position): \(error)")
            }
        }
    }
}
