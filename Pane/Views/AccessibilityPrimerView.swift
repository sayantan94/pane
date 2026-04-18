import SwiftUI
import AppKit

struct AccessibilityPrimerView: View {
    var onGranted: (() -> Void)?
    var onDismiss: (() -> Void)?

    @State private var trusted: Bool = WindowSnapshotter.isAccessibilityTrusted()
    @State private var pollTimer: Timer?
    @State private var pollTicks: Int = 0

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44))
                .foregroundColor(.accentColor)

            VStack(spacing: 4) {
                Text("Pane needs Accessibility")
                    .font(.system(size: 20, weight: .semibold))
                Text("So it can position non-scriptable apps like IntelliJ, VS Code, Cursor, and Slack.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }

            VStack(alignment: .leading, spacing: 12) {
                bullet(num: 1, title: "Open Accessibility settings",
                       body: "Click the button below. It jumps directly to Privacy & Security → Accessibility.")
                bullet(num: 2, title: "Turn Pane on",
                       body: "Find Pane in the list and flip the switch. You may need to click the lock and enter your password.")
                bullet(num: 3, title: "Come back here",
                       body: "This view watches for the permission in real time and moves forward automatically.")
            }
            .padding(.horizontal, 4)

            if pollTicks > 0 && !trusted {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.mini)
                    Text("Watching for permission…")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 10) {
                Button("Open Accessibility Settings") {
                    PermissionsHelper.openAccessibilitySettings()
                }
                if trusted {
                    Button("Done") { onGranted?() }
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Re-check") {
                        trusted = WindowSnapshotter.isAccessibilityTrusted()
                        if trusted {
                            stopPolling()
                            onGranted?()
                        }
                    }
                }
            }
            .padding(.top, 4)

            if pollTicks > 6 && !trusted {
                VStack(spacing: 4) {
                    Text("Already granted but Pane still says no?")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("macOS sometimes caches the old answer. Restart Pane to refresh.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Restart Pane") { restartApp() }
                        .font(.system(size: 11))
                }
            }

            if onDismiss != nil {
                Button("Not now") { onDismiss?() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(28)
        .frame(width: 460)
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    private func startPolling() {
        guard pollTimer == nil else { return }
        trusted = WindowSnapshotter.isAccessibilityTrusted()
        if trusted { onGranted?(); return }
        pollTicks = 0
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            pollTicks += 1
            let nowTrusted = WindowSnapshotter.isAccessibilityTrusted()
            if nowTrusted {
                trusted = true
                stopPolling()
                onGranted?()
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func restartApp() {
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
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
