import SwiftUI

enum ExecutionState {
    case idle
    case running(String)
    case success(String)
    case error(String)
}

struct MenuBarView: View {
    @State private var layouts: [Layout] = []
    @State private var showingEditor = false
    @State private var editingLayout: Layout?
    @State private var displayPickerLayout: Layout?
    @State private var executionState: ExecutionState = .idle

    private let store = LayoutStore()
    private let executor = LayoutExecutor()

    var body: some View {
        VStack(spacing: 0) {
            if let layout = displayPickerLayout {
                displayPicker(for: layout)
            } else {
                mainView
            }
        }
        .frame(width: 260)
        .onAppear { loadLayouts() }
        .sheet(isPresented: $showingEditor) {
            LayoutEditorView(layout: editingLayout) { loadLayouts() }
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "rectangle.split.2x2")
                    .font(.system(size: 12))
                    .foregroundColor(warmAccent)
                Text("Pane")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button {
                    editingLayout = nil
                    showingEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Status bar
            statusView

            // Layouts
            if layouts.isEmpty {
                VStack(spacing: 8) {
                    Text("No layouts")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("Click + to create one")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .padding(.vertical, 28)
            } else {
                VStack(spacing: 1) {
                    ForEach(layouts) { layout in
                        LayoutRow(
                            layout: layout,
                            isRunning: isRunning(layout),
                            onRun: { triggerLayout(layout) },
                            onEdit: {
                                editingLayout = layout
                                showingEditor = true
                            },
                            onDelete: {
                                try? store.delete(layout.id)
                                loadLayouts()
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            Divider().opacity(0.15).padding(.horizontal, 12)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit Pane")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch executionState {
        case .idle:
            EmptyView()
        case .running(let name):
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Running \(name)...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.03))
        case .success(let msg):
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
                Text(msg)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.05))
        case .error(let msg):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                Text(msg)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                Spacer()
                Button {
                    executionState = .idle
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.05))
        }
    }

    private func displayPicker(for layout: Layout) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    displayPickerLayout = nil
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Text("Pick a display")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            VStack(spacing: 2) {
                ForEach(0..<NSScreen.screens.count, id: \.self) { i in
                    Button {
                        let target = layout
                        displayPickerLayout = nil
                        runLayout(target, onDisplay: i)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: i == 0 ? "laptopcomputer" : "display")
                                .font(.system(size: 11))
                                .foregroundColor(warmAccent)
                            Text(displayName(for: i))
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private func triggerLayout(_ layout: Layout) {
        if NSScreen.screens.count > 1 {
            displayPickerLayout = layout
        } else {
            runLayout(layout, onDisplay: 0)
        }
    }

    private func runLayout(_ layout: Layout, onDisplay: Int) {
        executionState = .running(layout.name)
        Task {
            let result = await executor.execute(layout, onDisplay: onDisplay)
            await MainActor.run {
                if result.isFullSuccess {
                    executionState = .success("\(layout.name) — \(result.successes.count) windows")
                    // Auto-dismiss after 3s
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        if case .success = executionState { executionState = .idle }
                    }
                } else if result.errors.isEmpty {
                    executionState = .idle
                } else {
                    executionState = .error(result.errors.joined(separator: "\n"))
                }
            }
        }
    }

    private func isRunning(_ layout: Layout) -> Bool {
        if case .running(let name) = executionState { return name == layout.name }
        return false
    }

    private func loadLayouts() {
        layouts = (try? store.loadAll()) ?? []
    }
}

struct LayoutRow: View {
    let layout: Layout
    let isRunning: Bool
    let onRun: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onRun) {
                HStack(spacing: 8) {
                    if isRunning {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Circle()
                            .fill(warmAccent.opacity(isHovered ? 1 : 0.6))
                            .frame(width: 6, height: 6)
                    }
                    Text(layout.name)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .disabled(isRunning)

            if isHovered && !isRunning {
                HStack(spacing: 6) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
        )
        .onHover { isHovered = $0 }
    }
}
