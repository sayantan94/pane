import SwiftUI

@main
struct PaneApp: App {
    var body: some Scene {
        MenuBarExtra("Pane", systemImage: "rectangle.split.2x2") {
            Text("Pane — Workspace Launcher")
                .padding()
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
