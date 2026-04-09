import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyEngine = HotkeyEngine()
    private let store = LayoutStore()
    private let executor = LayoutExecutor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerHotkeys()
        hotkeyEngine.startListening()
    }

    func registerHotkeys() {
        guard let layouts = try? store.loadAll() else { return }

        for layout in layouts {
            guard let shortcut = layout.shortcut else { continue }
            let capturedLayout = layout
            hotkeyEngine.register(shortcut: shortcut) { [executor] in
                Task {
                    await executor.execute(capturedLayout)
                }
            }
        }
    }
}

@main
struct PaneApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Pane", systemImage: "rectangle.split.2x2") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        Window("Pane Setup", id: "onboarding") {
            OnboardingView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Settings {
            PreferencesView()
        }
    }
}
