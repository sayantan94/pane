import AppKit

struct InstalledApp: Identifiable, Hashable {
    var id: String { bundleID }
    let name: String
    let bundleID: String
    let path: String
}

enum InstalledAppsScanner {
    static func scan() -> [InstalledApp] {
        let dirs = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications",
        ]

        var seen = Set<String>()
        var results: [InstalledApp] = []
        let fm = FileManager.default

        for dir in dirs {
            guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for entry in contents where entry.hasSuffix(".app") {
                let path = "\(dir)/\(entry)"
                guard let bundle = Bundle(path: path), let bundleID = bundle.bundleIdentifier else { continue }
                if seen.contains(bundleID) { continue }
                seen.insert(bundleID)
                let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? entry.replacingOccurrences(of: ".app", with: "")
                results.append(InstalledApp(name: name, bundleID: bundleID, path: path))
            }
        }
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
