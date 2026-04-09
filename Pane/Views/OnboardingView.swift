import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAccessibilityGranted = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.split.2x2")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Welcome to Pane")
                .font(.title)
                .fontWeight(.bold)

            Text("Pane needs Accessibility access to move and resize windows on your screen.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            if isAccessibilityGranted {
                Label("Accessibility Granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                Button("Grant Accessibility Access") {
                    AccessibilityHelper.promptIfNeeded()
                    Task {
                        for _ in 0..<30 {
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            if AccessibilityHelper.isTrusted {
                                isAccessibilityGranted = true
                                return
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if isAccessibilityGranted {
                Button("Get Started") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(width: 400, height: 350)
        .onAppear {
            isAccessibilityGranted = AccessibilityHelper.isTrusted
        }
    }
}
