import SwiftUI

@main
struct PaneApp: App {
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
