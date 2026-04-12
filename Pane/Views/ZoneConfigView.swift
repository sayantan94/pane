import SwiftUI

let supportedBundleIDs: Set<String> = [
    "com.apple.Terminal",
    "com.googlecode.iterm2",
    "dev.warp.Warp-Stable",
]

struct ZoneConfigView: View {
    @Binding var zone: Zone
    @State private var installedApps: [(name: String, bundleID: String)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formatZoneName(zone.position))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.accentColor)

            HStack(spacing: 6) {
                Picker("", selection: $zone.appBundleID) {
                    Text("Select terminal...").tag("")
                    ForEach(installedApps, id: \.bundleID) { app in
                        Text(app.name).tag(app.bundleID)
                    }
                }
                .labelsHidden()

                if NSScreen.screens.count > 1 {
                    Picker("", selection: $zone.displayIndex) {
                        ForEach(0..<NSScreen.screens.count, id: \.self) { i in
                            Text(displayName(for: i)).tag(i)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }
            }

            if !zone.appBundleID.isEmpty {
                TextField("Directory path (optional)", text: Binding(
                    get: { zone.path ?? "" },
                    set: { zone.path = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.1)))
        .onAppear { loadInstalledApps() }
    }

    private func formatZoneName(_ pos: ZonePosition) -> String {
        pos.rawValue
            .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .capitalized
    }

    private func loadInstalledApps() {
        let dirs = ["/Applications", "/System/Applications", "/System/Applications/Utilities", NSHomeDirectory() + "/Applications"]
        var apps: [(name: String, bundleID: String)] = []
        for dir in dirs {
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for item in contents where item.hasSuffix(".app") {
                if let bundle = Bundle(path: "\(dir)/\(item)"),
                   let bundleID = bundle.bundleIdentifier,
                   supportedBundleIDs.contains(bundleID) {
                    apps.append((name: item.replacingOccurrences(of: ".app", with: ""), bundleID: bundleID))
                }
            }
        }
        installedApps = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
