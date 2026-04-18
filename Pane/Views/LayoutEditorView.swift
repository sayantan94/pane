import SwiftUI

struct LayoutEditorView: View {
    @State private var name: String
    @State private var selectedTemplate: GridTemplateOption?
    @State private var zones: [Zone]
    @State private var autoApply: Bool
    @State private var displayFingerprint: String?

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
            _autoApply = State(initialValue: layout.autoApply ?? false)
            _displayFingerprint = State(initialValue: layout.displayFingerprint)
        } else {
            self.existingID = nil
            _name = State(initialValue: "")
            _selectedTemplate = State(initialValue: nil)
            _zones = State(initialValue: [])
            _autoApply = State(initialValue: false)
            _displayFingerprint = State(initialValue: nil)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(existingID != nil ? "Edit Layout" : "New Layout")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("e.g. Coding", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                    }

                    // Grid
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Grid")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        GridTemplatePicker(selectedTemplate: $selectedTemplate)
                    }
                    .onChange(of: selectedTemplate?.id) { _ in updateZones() }

                    // Custom drag canvas
                    if selectedTemplate?.id == customGridTemplateID {
                        CustomLayoutEditor(zones: $zones)
                    }

                    // Zones
                    if !zones.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Zones")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            ForEach($zones) { $zone in
                                ZoneConfigView(zone: $zone)
                                Divider()
                            }
                        }
                    }

                    autoApplySection
                }
                .padding(16)
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { NSApp.keyWindow?.close() }
                Button("Save") { saveLayout() }
                    .disabled(name.isEmpty || selectedTemplate == nil)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 400, height: 460)
    }

    private func updateZones() {
        guard let template = selectedTemplate else { zones = []; return }
        if template.id == customGridTemplateID {
            let hasCustom = zones.contains { $0.position == .custom }
            if !hasCustom {
                zones = [
                    Zone(
                        position: .custom,
                        appBundleID: "",
                        path: nil,
                        displayIndex: 0,
                        commands: nil,
                        customFrame: CustomFrame(x: 0, y: 0, w: 0.5, h: 1),
                        spaceIndex: nil
                    ),
                    Zone(
                        position: .custom,
                        appBundleID: "",
                        path: nil,
                        displayIndex: 0,
                        commands: nil,
                        customFrame: CustomFrame(x: 0.5, y: 0, w: 0.5, h: 1),
                        spaceIndex: nil
                    ),
                ]
            }
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
            zones: zones,
            displayFingerprint: displayFingerprint,
            autoApply: autoApply
        )
        if let existingID { layout.id = existingID }
        try? store.save(layout)
        onSave?()
        NSApp.keyWindow?.close()
    }

    private var autoApplySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Automatic")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Toggle(isOn: $autoApply) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Auto-apply when this display setup returns")
                        .font(.system(size: 11))
                    Text(displayFingerprint == nil
                         ? "No display setup is remembered yet."
                         : "Remembered setup: \(displayFingerprint!)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.checkbox)
            .onChange(of: autoApply) { newValue in
                if newValue && displayFingerprint == nil {
                    displayFingerprint = DisplayFingerprint.current()
                }
            }
            if autoApply {
                Button {
                    displayFingerprint = DisplayFingerprint.current()
                } label: {
                    Text("Use current display setup")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
    }
}
