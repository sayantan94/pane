import SwiftUI

struct LayoutEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedTemplate: GridTemplateOption?
    @State private var zones: [Zone]

    private let store = LayoutStore()
    private let existingID: UUID?
    var onSave: (() -> Void)?

    init(layout: Layout? = nil, onSave: (() -> Void)? = nil) {
        self.onSave = onSave
        if let layout {
            self.existingID = layout.id
            _name = State(initialValue: layout.name)
            _selectedTemplate = State(
                initialValue: gridTemplateOptions.first { $0.id == layout.gridTemplate }
            )
            _zones = State(initialValue: layout.zones)
        } else {
            self.existingID = nil
            _name = State(initialValue: "")
            _selectedTemplate = State(initialValue: nil)
            _zones = State(initialValue: [])
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(existingID != nil ? "Edit Layout" : "New Layout")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider().opacity(0.15)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("e.g. Coding", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                    }

                    // Grid template
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Layout")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        GridTemplatePicker(selectedTemplate: $selectedTemplate)
                    }
                    .onChange(of: selectedTemplate?.id) { _ in updateZones() }

                    // Zone configs
                    if !zones.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Apps")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            ForEach($zones) { $zone in
                                ZoneConfigView(zone: $zone)
                            }
                        }
                    }
                }
                .padding(16)
            }

            Divider().opacity(0.15)

            // Footer
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .foregroundColor(.secondary)
                Button {
                    saveLayout()
                } label: {
                    Text("Save")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(warmAccent)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(name.isEmpty || selectedTemplate == nil)
            }
            .padding(16)
        }
        .frame(width: 460, height: 480)
    }

    private func updateZones() {
        guard let template = selectedTemplate else {
            zones = []
            return
        }
        zones = template.zones.map { position in
            if let existing = zones.first(where: { $0.position == position }) {
                return existing
            }
            return Zone(position: position, appBundleID: "", path: nil, displayIndex: 0)
        }
    }

    private func saveLayout() {
        guard let template = selectedTemplate else { return }
        var layout = Layout(
            name: name,
            gridTemplate: template.id,
            zones: zones
        )
        if let existingID { layout.id = existingID }
        try? store.save(layout)
        onSave?()
        dismiss()
    }
}
