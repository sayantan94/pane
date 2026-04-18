import SwiftUI

enum ExecutionState: Equatable {
    case idle, running(String), success(String), error(String)
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.running(let a), .running(let b)): return a == b
        case (.success(let a), .success(let b)): return a == b
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

struct MenuBarView: View {
    @State private var layouts: [Layout] = []
    @State private var showingManageApps = false
    @State private var displayPickerLayout: Layout?
    @ObservedObject private var executionHolder = ExecutionStateHolder.shared

    private let store = LayoutStore()

    var body: some View {
        VStack(spacing: 0) {
            if showingManageApps {
                manageAppsSection
            } else if let layout = displayPickerLayout {
                displayPickerSection(for: layout)
            } else {
                mainSection
            }
        }
        .frame(width: 260)
        .onAppear { loadLayouts() }
    }

    private var mainSection: some View {
        VStack(spacing: 0) {
            statusBanner

            menuButton("Manage Apps", icon: "square.grid.2x2") { showingManageApps = true }

            Divider().padding(.vertical, 2)

            if CustomAppsStore().loadAll().isEmpty {
                Text("Add your apps to get started")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if layouts.isEmpty {
                Text("No layouts yet")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(layouts) { layout in
                    menuItem(layout)
                }
            }

            Divider().padding(.vertical, 2)

            menuButton("New Layout", icon: "plus") {
                openEditorWindow(layout: nil)
            }

            menuButton("Capture Current Windows", icon: "camera.viewfinder") {
                openSnapshotWindow()
            }

            Divider().padding(.vertical, 2)

            menuButton("Quit Pane", icon: "power") { NSApplication.shared.terminate(nil) }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch executionHolder.state {
        case .idle: EmptyView()
        case .running(let name):
            HStack(spacing: 6) {
                ProgressView().controlSize(.mini)
                Text(name).font(.system(size: 11)).foregroundColor(.secondary)
                Spacer()
            }.padding(.horizontal, 12).padding(.vertical, 4)
        case .success(let msg):
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 10)).foregroundColor(.green)
                Text(msg).font(.system(size: 11))
                Spacer()
            }.padding(.horizontal, 12).padding(.vertical, 4)
        case .error(let msg):
            errorBanner(msg)
        }
    }

    @ViewBuilder
    private func errorBanner(_ msg: String) -> some View {
        let isAutomation = PermissionsHelper.isAutomationError(msg)
        let isAccessibility = PermissionsHelper.isAccessibilityError(msg)
        let headline: String = {
            if isAutomation { return "macOS blocked Pane from controlling your apps" }
            if isAccessibility { return "Pane needs Accessibility to move non-scriptable apps" }
            return msg
        }()
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundColor(.orange)
                Text(headline)
                    .font(.system(size: 11)).lineLimit(3)
                Spacer()
                Button { executionHolder.state = .idle } label: {
                    Image(systemName: "xmark").font(.system(size: 7, weight: .bold)).foregroundColor(.secondary)
                }.buttonStyle(.plain)
            }
            if isAutomation {
                Button {
                    PermissionsHelper.openAutomationSettings()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill").font(.system(size: 9))
                        Text("Open Automation settings").font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)
            } else if isAccessibility {
                Button {
                    AppDelegate.shared.showAccessibilityPrimer()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill").font(.system(size: 9))
                        Text("Show me how to grant it").font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 4)
    }

    private func menuItem(_ layout: Layout) -> some View {
        Button { triggerLayout(layout) } label: {
            HStack(spacing: 8) {
                miniPreview(layout)
                Text(layout.name).lineLimit(1)
                Spacer()
                if layout.autoApply == true {
                    Image(systemName: "arrow.triangle.2.circlepath.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                if isRunning(layout) { ProgressView().controlSize(.mini) }
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle())
        .disabled(isRunning(layout))
        .contextMenu {
            Button("Edit") { openEditorWindow(layout: layout) }
            Divider()
            Button("Delete", role: .destructive) { try? store.delete(layout.id); loadLayouts() }
        }
    }

    private func miniPreview(_ layout: Layout) -> some View {
        let template = gridTemplateOptions.first { $0.id == layout.gridTemplate }
        let W: CGFloat = 52
        let H: CGFloat = 32
        let zonesByPos = Dictionary(layout.zones.map { ($0.position, $0) }, uniquingKeysWith: { a, _ in a })
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.secondary.opacity(0.18), lineWidth: 0.5))
                .frame(width: W, height: H)
            if let template {
                let b = CGRect(x: 1.5, y: 1.5, width: W - 3, height: H - 3)
                ForEach(Array(template.zones.enumerated()), id: \.offset) { _, pos in
                    let f = pos.frame(in: b)
                    ZStack {
                        RoundedRectangle(cornerRadius: 2).fill(Color.accentColor.opacity(0.14))
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.accentColor.opacity(0.35), lineWidth: 0.5))
                        if let bundleID = zonesByPos[pos]?.appBundleID,
                           !bundleID.isEmpty,
                           let icon = AppIconProvider.shared.icon(for: bundleID) {
                            let iconSize = min(f.width, f.height) * 0.62
                            Image(nsImage: icon)
                                .resizable().interpolation(.medium).aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)
                        }
                    }
                    .frame(width: max(f.width - 1, 1), height: max(f.height - 1, 1))
                    .offset(x: f.minX + 0.5, y: f.minY + 0.5)
                }
            }
        }
        .frame(width: W, height: H)
    }

    private func menuButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 10)).foregroundColor(.secondary).frame(width: 16)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle())
    }

    // MARK: - Manage Apps (inline)

    @ViewBuilder
    private var manageAppsSection: some View {
        VStack(spacing: 0) {
            menuButton("Back", icon: "chevron.left") { showingManageApps = false }
            Divider().padding(.vertical, 2)
            ManageAppsView(onDone: { showingManageApps = false })
        }
        .padding(.vertical, 4)
    }

    private func displayPickerSection(for layout: Layout) -> some View {
        VStack(spacing: 0) {
            menuButton("Back", icon: "chevron.left") { displayPickerLayout = nil }
            Divider().padding(.vertical, 2)
            Text("Pick a display")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            DisplayArrangementPicker(layout: layout) { i in
                let target = layout
                displayPickerLayout = nil
                runLayout(target, onDisplay: i)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }.padding(.vertical, 4)
    }

    private func triggerLayout(_ layout: Layout) {
        paneDebug("[Pane] triggerLayout: \(layout.name), screens: \(NSScreen.screens.count)")
        if NSScreen.screens.count > 1 {
            displayPickerLayout = layout
        } else {
            runLayout(layout, onDisplay: 0)
        }
    }

    private func runLayout(_ layout: Layout, onDisplay: Int) {
        AppDelegate.shared.runLayout(layout, onDisplay: onDisplay)
    }

    private func isRunning(_ layout: Layout) -> Bool {
        if case .running(let n) = executionHolder.state { return n == layout.name }; return false
    }

    private func loadLayouts() { layouts = (try? store.loadAll()) ?? [] }

    private func openEditorWindow(layout: Layout?) {
        let editor = LayoutEditorView(layout: layout) { loadLayouts() }
        let controller = NSHostingController(rootView: editor)
        let window = NSWindow(contentViewController: controller)
        window.title = layout != nil ? "Edit Layout" : "New Layout"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 400, height: 460))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openSnapshotWindow() {
        AppDelegate.shared.closePopover()
        let snap = SnapshotView { loadLayouts() }
        let controller = NSHostingController(rootView: snap)
        let window = NSWindow(contentViewController: controller)
        window.title = "Capture Layout"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 440, height: 520))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct MenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13))
            .foregroundColor(.primary)
            .background(RoundedRectangle(cornerRadius: 4).fill(configuration.isPressed ? Color.accentColor.opacity(0.15) : Color.clear))
    }
}

struct DisplayArrangementPicker: View {
    let layout: Layout
    var onPick: (Int) -> Void
    @State private var hovered: Int?

    private let maxWidth: CGFloat = 240
    private let maxHeight: CGFloat = 130

    var body: some View {
        let screens = NSScreen.screens
        let bbox = unionFrame(of: screens)
        let scale = min(maxWidth / max(bbox.width, 1), maxHeight / max(bbox.height, 1))
        let W = bbox.width * scale
        let H = bbox.height * scale

        return ZStack(alignment: .topLeading) {
            ForEach(0..<screens.count, id: \.self) { i in
                let s = screens[i].frame
                let x = (s.origin.x - bbox.origin.x) * scale
                // NSScreen uses bottom-left origin; flip for top-left layout.
                let y = (bbox.maxY - s.maxY) * scale
                let w = s.width * scale
                let h = s.height * scale
                let isHover = (hovered == i)
                Button { onPick(i) } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.accentColor.opacity(isHover ? 0.28 : 0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.accentColor.opacity(isHover ? 0.9 : 0.5), lineWidth: isHover ? 1.5 : 1)
                            )
                        VStack(spacing: 3) {
                            Image(systemName: screenSymbol(for: i))
                                .font(.system(size: min(w, h) > 60 ? 16 : 12))
                                .foregroundColor(.accentColor)
                            if h > 44 {
                                Text(displayName(for: i))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .padding(.horizontal, 4)
                            }
                        }
                    }
                    .frame(width: w, height: h)
                    .contentShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .onHover { hovered = $0 ? i : (hovered == i ? nil : hovered) }
                .offset(x: x, y: y)
            }
        }
        .frame(width: W, height: H)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func unionFrame(of screens: [NSScreen]) -> CGRect {
        guard let first = screens.first else { return CGRect(x: 0, y: 0, width: 1, height: 1) }
        return screens.dropFirst().reduce(first.frame) { $0.union($1.frame) }
    }

    private func screenSymbol(for i: Int) -> String {
        let screen = NSScreen.screens[i]
        return screen == NSScreen.main ? "laptopcomputer" : "display"
    }
}
