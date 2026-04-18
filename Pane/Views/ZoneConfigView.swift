import SwiftUI

struct ZoneConfigView: View {
    @Binding var zone: Zone
    @State private var apps: [CustomApp] = []

    private var isTerminal: Bool {
        let knownTerminals: Set<String> = ["com.googlecode.iterm2", "com.apple.Terminal"]
        if knownTerminals.contains(zone.appBundleID) { return true }
        return apps.first { $0.bundleID == zone.appBundleID }?.isTerminal ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formatZoneName(zone.position))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.accentColor)

            HStack(alignment: .top) {
                Text("App").font(.system(size: 12)).foregroundColor(.secondary).frame(width: 50, alignment: .trailing)
                VStack(alignment: .leading, spacing: 4) {
                    Picker("", selection: $zone.appBundleID) {
                        Text("None").tag("")
                        ForEach(apps) { app in
                            Text(app.name).tag(app.bundleID)
                        }
                        if !zone.appBundleID.isEmpty && !apps.contains(where: { $0.bundleID == zone.appBundleID }) {
                            Text("Custom: \(zone.appBundleID)").tag(zone.appBundleID)
                        }
                    }
                    .labelsHidden()
                    TextField("or type bundle ID, e.g. com.apple.Safari", text: $zone.appBundleID)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }
            }

            if !zone.appBundleID.isEmpty {
                HStack {
                    Text("Path").font(.system(size: 12)).foregroundColor(.secondary).frame(width: 50, alignment: .trailing)
                    TextField("~/projects/myapp", text: Binding(
                        get: { zone.path ?? "" },
                        set: { zone.path = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                }
            }

            if !zone.appBundleID.isEmpty && isTerminal {
                commandEditor
            }

            if NSScreen.screens.count > 1 {
                HStack {
                    Text("Display").font(.system(size: 12)).foregroundColor(.secondary).frame(width: 50, alignment: .trailing)
                    Picker("", selection: $zone.displayIndex) {
                        ForEach(0..<NSScreen.screens.count, id: \.self) { i in
                            Text(displayName(for: i)).tag(i)
                        }
                    }
                    .labelsHidden()
                }
            }
        }
        .padding(.vertical, 6)
        .onAppear { apps = CustomAppsStore().loadAll() }
    }

    private var commandEditor: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Run").font(.system(size: 12)).foregroundColor(.secondary).frame(width: 50, alignment: .trailing)
                Text("one per line, runs after cd").font(.system(size: 10)).foregroundColor(.secondary.opacity(0.7))
                Spacer()
            }
            TextEditor(text: Binding(
                get: { (zone.commands ?? []).joined(separator: "\n") },
                set: { newValue in
                    let lines = newValue.split(whereSeparator: \.isNewline).map(String.init)
                    zone.commands = lines.isEmpty ? nil : lines
                }
            ))
            .font(.system(size: 12, design: .monospaced))
            .frame(minHeight: 50, maxHeight: 80)
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.2)))
            .padding(.leading, 54)
        }
    }

    private func formatZoneName(_ pos: ZonePosition) -> String {
        if pos == .custom { return "Custom zone" }
        return pos.rawValue
            .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .capitalized
    }
}

// MARK: - Manage Apps

struct ManageAppsView: View {
    var onDone: (() -> Void)? = nil
    @State private var apps: [CustomApp] = []
    @State private var appName = ""
    @State private var installed: [InstalledApp] = []
    @State private var selectedInstalledID: String = ""
    private let store = CustomAppsStore()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Manage Apps")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            // Added apps
            if apps.isEmpty {
                Text("No apps added yet")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(apps) { app in
                            HStack(spacing: 8) {
                                Button {
                                    let id = app.bundleID
                                    DispatchQueue.main.async {
                                        store.remove(bundleID: id)
                                        apps = store.loadAll()
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)

                                Text(app.name).font(.system(size: 13))
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxHeight: 120)
            }

            Divider()

            // Add from installed apps dropdown
            VStack(alignment: .leading, spacing: 4) {
                Text("Pick from installed apps")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                HStack {
                    Picker("", selection: $selectedInstalledID) {
                        Text("Select an app…").tag("")
                        ForEach(availableInstalled) { app in
                            Text(app.name).tag(app.bundleID)
                        }
                    }
                    .labelsHidden()

                    Button("Add") { addFromInstalled() }
                        .disabled(selectedInstalledID.isEmpty)
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Add by name (fallback)
            VStack(alignment: .leading, spacing: 4) {
                Text("Or type a name / bundle ID")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                HStack {
                    TextField("e.g. iTerm, Safari, com.apple.Safari", text: $appName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .onSubmit { addByName() }

                    Button("Add") { addByName() }
                        .disabled(appName.isEmpty)
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .onAppear {
            apps = store.loadAll()
            installed = InstalledAppsScanner.scan()
        }
    }

    private var availableInstalled: [InstalledApp] {
        let existing = Set(apps.map { $0.bundleID })
        return installed.filter { !existing.contains($0.bundleID) }
    }

    private func addFromInstalled() {
        guard let picked = installed.first(where: { $0.bundleID == selectedInstalledID }) else { return }
        store.add(CustomApp(name: picked.name, bundleID: picked.bundleID))
        apps = store.loadAll()
        selectedInstalledID = ""
    }

    private func addByName() {
        let name = appName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        // Search common locations for the app
        let dirs = ["/Applications", "/System/Applications", "/System/Applications/Utilities", NSHomeDirectory() + "/Applications"]
        let possibleNames = ["\(name).app", name]

        for dir in dirs {
            for possible in possibleNames {
                let path = "\(dir)/\(possible)"
                if let bundle = Bundle(path: path),
                   let bundleID = bundle.bundleIdentifier {
                    let appDisplayName = possible.replacingOccurrences(of: ".app", with: "")
                    store.add(CustomApp(name: appDisplayName, bundleID: bundleID))
                    apps = store.loadAll()
                    appName = ""
                    return
                }
            }
        }

        // Try as bundle ID directly (e.g. com.googlecode.iterm2)
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: name) {
            let appDisplayName = url.deletingPathExtension().lastPathComponent
            store.add(CustomApp(name: appDisplayName, bundleID: name))
            apps = store.loadAll()
            appName = ""
            return
        }

        // Not found — show the name with error hint
        appName = "\(name) — not found"
    }
}
