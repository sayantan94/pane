import SwiftUI
import AppKit

struct SnapshotView: View {
    var onSaved: (() -> Void)?

    @State private var layoutName: String = ""
    @State private var displayIndex: Int = 0
    @State private var windows: [SnapshottedWindow] = []
    @State private var axTrusted: Bool = WindowSnapshotter.isAccessibilityTrusted()
    @State private var autoApply: Bool = false

    private let store = LayoutStore()
    private let snapshotter = WindowSnapshotter()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if !axTrusted {
                axPrompt
            } else {
                captureContent
            }
            Divider()
            footer
        }
        .frame(width: 440, height: 520)
        .onAppear {
            axTrusted = WindowSnapshotter.isAccessibilityTrusted()
            refresh()
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "camera.viewfinder").foregroundColor(.accentColor)
            Text("Capture Layout")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var axPrompt: some View {
        AccessibilityPrimerView(onGranted: {
            axTrusted = true
            refresh()
        })
        .frame(maxHeight: .infinity)
    }

    private var captureContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                    TextField("e.g. Coding", text: $layoutName)
                        .textFieldStyle(.roundedBorder)
                }

                if NSScreen.screens.count > 1 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Display").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                        Picker("", selection: $displayIndex) {
                            ForEach(0..<NSScreen.screens.count, id: \.self) { i in
                                Text(displayName(for: i)).tag(i)
                            }
                        }
                        .labelsHidden()
                        .onChange(of: displayIndex) { _ in refresh() }
                    }
                }

                HStack {
                    Text("Captured windows").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                    Spacer()
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }

                if windows.isEmpty {
                    Text("No recognized windows on this display.\nAdd apps in Manage Apps, then try again.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                } else {
                    SnapshotCanvas(windows: windows, displayIndex: displayIndex)
                        .frame(height: 160)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.05)))

                    VStack(spacing: 4) {
                        ForEach(Array(windows.enumerated()), id: \.offset) { _, win in
                            windowRow(win)
                        }
                    }
                }

                Toggle(isOn: $autoApply) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Auto-apply when this display setup returns")
                            .font(.system(size: 11))
                        Text("Pane will run this layout when the same monitors are plugged in.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
            }
            .padding(16)
        }
    }

    private func windowRow(_ w: SnapshottedWindow) -> some View {
        HStack(spacing: 8) {
            if let bundleID = w.app.bundleIdentifier,
               let icon = AppIconProvider.shared.icon(for: bundleID) {
                Image(nsImage: icon).resizable().frame(width: 18, height: 18)
            }
            Text(w.app.localizedName ?? w.app.bundleIdentifier ?? "App")
                .font(.system(size: 12))
            if let cwd = w.cwd {
                Text(cwd).font(.system(size: 10)).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            Text("\(Int(w.frame.width))×\(Int(w.frame.height))")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.06)))
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Cancel", role: .cancel) { NSApp.keyWindow?.close() }
            Button("Save Layout") { save() }
                .disabled(layoutName.isEmpty || windows.isEmpty || !axTrusted)
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private func refresh() {
        guard WindowSnapshotter.isAccessibilityTrusted() else {
            axTrusted = false
            windows = []
            return
        }
        axTrusted = true
        windows = snapshotter.snapshot(onDisplay: displayIndex)
    }

    private func save() {
        let zones = WindowSnapshotter.proposedZones(from: windows, onDisplay: displayIndex)
        let layout = Layout(
            name: layoutName,
            gridTemplate: customGridTemplateID,
            zones: zones,
            displayFingerprint: DisplayFingerprint.current(),
            autoApply: autoApply
        )
        try? store.save(layout)
        onSaved?()
        NSApp.keyWindow?.close()
    }
}

struct SnapshotCanvas: View {
    let windows: [SnapshottedWindow]
    let displayIndex: Int

    var body: some View {
        GeometryReader { geo in
            let screens = NSScreen.screens
            let screen = displayIndex < screens.count ? screens[displayIndex].frame : (screens.first?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1200))
            let aspect = screen.width / screen.height
            let pad: CGFloat = 10
            let size = fittedSize(available: CGSize(width: geo.size.width - pad * 2, height: geo.size.height - pad * 2), aspect: aspect)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    .frame(width: size.width, height: size.height)
                ForEach(Array(windows.enumerated()), id: \.offset) { _, w in
                    let rx = (w.frame.origin.x - screen.origin.x) / screen.width
                    // NSScreen coords: bottom-left origin. Flip Y for UI top-left layout.
                    let ry = (screen.maxY - w.frame.maxY) / screen.height
                    let rw = w.frame.width / screen.width
                    let rh = w.frame.height / screen.height
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.2))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.accentColor.opacity(0.6), lineWidth: 1))
                        if let bundleID = w.app.bundleIdentifier,
                           let icon = AppIconProvider.shared.icon(for: bundleID) {
                            Image(nsImage: icon).resizable().aspectRatio(contentMode: .fit)
                                .frame(width: min(size.width * rw, size.height * rh) * 0.5)
                        }
                    }
                    .frame(width: max(size.width * rw - 2, 1), height: max(size.height * rh - 2, 1))
                    .offset(x: size.width * rx + 1, y: size.height * ry + 1)
                }
            }
            .frame(width: size.width, height: size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func fittedSize(available: CGSize, aspect: CGFloat) -> CGSize {
        if available.width / aspect <= available.height {
            return CGSize(width: available.width, height: available.width / aspect)
        } else {
            return CGSize(width: available.height * aspect, height: available.height)
        }
    }
}
