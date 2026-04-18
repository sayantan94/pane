import SwiftUI
import AppKit

struct WelcomeView: View {
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "rectangle.split.2x2.fill")
                .font(.system(size: 44))
                .foregroundColor(.accentColor)

            VStack(spacing: 4) {
                Text("Welcome to Pane")
                    .font(.system(size: 20, weight: .semibold))
                Text("One click to arrange your windows.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                bullet(num: 1, title: "macOS will ask for permission",
                       body: "The first time you run a layout, macOS will prompt Pane to control iTerm, Terminal, and any other apps in your layout. Click OK for each.")
                bullet(num: 2, title: "If you miss the prompt",
                       body: "Open System Settings → Privacy & Security → Automation and turn Pane on for the apps you want to arrange.")
                bullet(num: 3, title: "Add apps, build a layout, click it",
                       body: "Use Manage Apps to add what you use, then New Layout to pick a grid and assign apps to zones.")
            }
            .padding(.horizontal, 4)

            HStack(spacing: 10) {
                Button("Open Automation Settings") {
                    PermissionsHelper.openAutomationSettings()
                }
                Button("Got it") { onDone() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 4)
        }
        .padding(28)
        .frame(width: 460)
    }

    private func bullet(num: Int, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(num)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(body).font(.system(size: 11)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
