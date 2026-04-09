import SwiftUI

struct MenuBarView: View {
    @State private var layouts: [Layout] = []
    @State private var showingEditor = false
    @State private var editingLayout: Layout?

    private let store = LayoutStore()
    private let executor = LayoutExecutor()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pane")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            Divider()

            if layouts.isEmpty {
                Text("No layouts configured")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            } else {
                ForEach(layouts) { layout in
                    Button {
                        Task {
                            await executor.execute(layout)
                        }
                    } label: {
                        HStack {
                            Text(layout.name)
                            Spacer()
                            if let shortcut = layout.shortcut {
                                Text(shortcut)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
            }

            Divider()

            Button("New Layout...") {
                showingEditor = true
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            Button("Quit Pane") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .padding(.bottom, 8)
        }
        .frame(width: 250)
        .onAppear {
            loadLayouts()
        }
        // TODO: uncomment when LayoutEditorView is created
        // .sheet(isPresented: $showingEditor) {
        //     LayoutEditorView(layout: editingLayout) {
        //         loadLayouts()
        //     }
        // }
    }

    private func loadLayouts() {
        layouts = (try? store.loadAll()) ?? []
    }
}
