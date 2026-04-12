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
            HStack {
                Text("Pane")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button {
                    editingLayout = nil
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Status
            if case .running(let name) = executionState {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(name).font(.system(size: 11)).foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.vertical, 5)
            }
            if case .success(let msg) = executionState {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.system(size: 11))
                    Text(msg).font(.system(size: 11)).foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 14).padding(.vertical, 5)
            }
            if case .error(let msg) = executionState {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.system(size: 11))
                    Text(msg).font(.system(size: 11)).foregroundColor(.primary).lineLimit(3)
                    Spacer()
                    Button { executionState = .idle } label: {
                        Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundColor(.secondary)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 14).padding(.vertical, 5)
            }

            // Layouts
            if layouts.isEmpty {
                Text("No layouts — click + to create one")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(layouts) { layout in
                        LayoutRow(
                            layout: layout,
                            isRunning: isRunning(layout),
                            onRun: { triggerLayout(layout) },
                            onEdit: { editingLayout = layout; showingEditor = true },
                            onDelete: { try? store.delete(layout.id); loadLayouts() }
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            Divider()

            Button { NSApplication.shared.terminate(nil) } label: {
                Text("Quit").font(.system(size: 11)).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
        }
    }

    private func displayPicker(for layout: Layout) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button { displayPickerLayout = nil } label: {
                    Image(systemName: "chevron.left").font(.system(size: 11, weight: .medium))
                }.buttonStyle(.plain)
                Text("Pick display").font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            Divider()

            ForEach(0..<NSScreen.screens.count, id: \.self) { i in
                Button {
                    let target = layout
                    displayPickerLayout = nil
                    runLayout(target, onDisplay: i)
                } label: {
                    HStack {
                        Image(systemName: i == 0 ? "laptopcomputer" : "display")
                            .font(.system(size: 12)).frame(width: 20)
                        Text(displayName(for: i)).font(.system(size: 13))
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14).padding(.vertical, 8)
            }
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
                    Task {
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        if case .success = executionState { executionState = .idle }
                    }
                } else if !result.errors.isEmpty {
                    executionState = .error(result.errors.joined(separator: "\n"))
                } else {
                    executionState = .idle
                }
            }
        }
    }

    private func isRunning(_ layout: Layout) -> Bool {
        if case .running(let n) = executionState { return n == layout.name }
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
        HStack(spacing: 8) {
            Button(action: onRun) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8))
                        .foregroundColor(isHovered ? .accentColor : .secondary)
                    Text(layout.name)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    Spacer()
                    if isRunning {
                        ProgressView().controlSize(.mini)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isRunning)

            if isHovered && !isRunning {
                Button(action: onEdit) {
                    Image(systemName: "pencil").font(.system(size: 10)).foregroundColor(.secondary)
                }.buttonStyle(.plain)
                Button(action: onDelete) {
                    Image(systemName: "trash").font(.system(size: 10)).foregroundColor(.red)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 4).fill(isHovered ? Color.accentColor.opacity(0.1) : .clear))
        .onHover { isHovered = $0 }
    }
}
