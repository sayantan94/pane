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
        NSLog("[Pane] Executing layout: \(layout.name) on display \(displayIndex)")

        let screens = NSScreen.screens
        let targetScreen = displayIndex < screens.count ? screens[displayIndex] : screens[0]
        let screenFrame = targetScreen.visibleFrame
        let currentSpace = spaceManager.currentSpaceID()

        var result = ExecutionResult()

        for zone in layout.zones {
            let frame = zone.position.frame(in: screenFrame)
            do {
                let app = try await appLauncher.launchIfNeeded(bundleID: zone.appBundleID)

                if let path = zone.path, !path.isEmpty {
                    appLauncher.openTerminalAtPath(path, terminalBundleID: zone.appBundleID)
                } else {
                    appLauncher.openNewWindow(bundleID: zone.appBundleID)
                }
                try? await Task.sleep(nanoseconds: 600_000_000)

                if let spaceID = currentSpace {
                    let wids = windowIDs(for: app)
                    if !wids.isEmpty {
                        spaceManager.moveWindows(wids, toSpace: spaceID)
                        try? await Task.sleep(nanoseconds: 300_000_000)
                    }
                }

                app.activate()
                try? await Task.sleep(nanoseconds: 200_000_000)
                try windowManager.positionWindow(of: app, to: frame)
                result.successes.append(app.localizedName ?? zone.appBundleID)
            } catch {
                let appName = NSWorkspace.shared.runningApplications
                    .first { $0.bundleIdentifier == zone.appBundleID }?.localizedName ?? zone.appBundleID
                let msg = "\(appName): \(error.localizedDescription)"
                result.errors.append(msg)
                NSLog("[Pane] FAILED zone \(zone.position): \(error)")
            }
        }
        NSLog("[Pane] Layout execution complete")
        return result
    }
}
