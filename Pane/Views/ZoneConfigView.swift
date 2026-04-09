import SwiftUI

struct ZoneConfigView: View {
    @Binding var zone: Zone
    @State private var installedApps: [(name: String, bundleID: String)] = []

    private let knownBrowserBundleIDs: Set<String> = [
        "com.google.Chrome",
        "com.apple.Safari",
        "org.mozilla.firefox",
        "com.microsoft.edgemac",
        "com.brave.Browser",
        "company.thebrowser.Browser",
    ]

    private let knownTerminalBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "net.kovidgoyal.kitty",
        "com.github.wez.wezterm",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(zone.position.rawValue)
                    .font(.headline)
                    .textCase(.none)
                Spacer()
            }

            HStack {
                Text("App:")
                    .frame(width: 50, alignment: .trailing)
                Picker("", selection: $zone.appBundleID) {
                    Text("Select an app...").tag("")
                    ForEach(installedApps, id: \.bundleID) { app in
                        Text(app.name).tag(app.bundleID)
                    }
                }
                .labelsHidden()
            }

            if knownBrowserBundleIDs.contains(zone.appBundleID) {
                HStack {
                    Text("URL:")
                        .frame(width: 50, alignment: .trailing)
                    TextField("https://example.com", text: Binding(
                        get: { zone.url ?? "" },
                        set: { zone.url = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
            }

            if knownTerminalBundleIDs.contains(zone.appBundleID) {
                HStack {
                    Text("Path:")
                        .frame(width: 50, alignment: .trailing)
                    TextField("/Users/you/project", text: Binding(
                        get: { zone.path ?? "" },
                        set: { zone.path = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.05)))
        .onAppear {
            loadInstalledApps()
        }
    }

    private func loadInstalledApps() {
        let fileManager = FileManager.default
        let appDirs = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications",
        ]

        var apps: [(name: String, bundleID: String)] = []

        for dir in appDirs {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: dir) else { continue }
            for item in contents where item.hasSuffix(".app") {
                let path = "\(dir)/\(item)"
                if let bundle = Bundle(path: path),
                   let bundleID = bundle.bundleIdentifier
                {
                    let name = item.replacingOccurrences(of: ".app", with: "")
                    apps.append((name: name, bundleID: bundleID))
                }
            }
        }

        installedApps = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
