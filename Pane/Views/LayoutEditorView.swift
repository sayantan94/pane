import SwiftUI

struct LayoutEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var shortcut: String
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
            _shortcut = State(initialValue: layout.shortcut ?? "")
            _selectedTemplate = State(
                initialValue: gridTemplateOptions.first { $0.id == layout.gridTemplate }
            )
            _zones = State(initialValue: layout.zones)
        } else {
            self.existingID = nil
            _name = State(initialValue: "")
            _shortcut = State(initialValue: "")
            _selectedTemplate = State(initialValue: nil)
            _zones = State(initialValue: [])
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Layout Name")
                        .font(.headline)
                    TextField("e.g. Coding", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Shortcut (optional)")
                        .font(.headline)
                    TextField("e.g. ctrl+option+1", text: $shortcut)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Grid Template")
                        .font(.headline)
                    GridTemplatePicker(selectedTemplate: $selectedTemplate)
                }
                .onChange(of: selectedTemplate?.id) { _ in
                    updateZones()
                }

                if !zones.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Configure Zones")
                            .font(.headline)
                        ForEach($zones) { $zone in
                            ZoneConfigView(zone: $zone)
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Cancel") {
                        dismiss()
                    }
                    Button("Save") {
                        saveLayout()
                    }
                    .disabled(name.isEmpty || selectedTemplate == nil)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .frame(width: 600)
        .frame(minHeight: 500)
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
            return Zone(position: position, appBundleID: "", url: nil, path: nil, displayIndex: 0)
        }
    }

    private func saveLayout() {
        guard let template = selectedTemplate else { return }

        var layout = Layout(
            name: name,
            shortcut: shortcut.isEmpty ? nil : shortcut,
            gridTemplate: template.id,
            zones: zones
        )

        if let existingID {
            layout.id = existingID
        }

        try? store.save(layout)
        onSave?()
        dismiss()
    }
}
