import Foundation

struct CustomApp: Codable, Identifiable {
    var id: String { bundleID }
    let name: String
    let bundleID: String
    var isTerminal: Bool = false
}

final class CustomAppsStore {
    private let fileURL: URL

    init() {
        self.fileURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/pane/custom-apps.json")
    }

    func loadAll() -> [CustomApp] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([CustomApp].self, from: data)) ?? []
    }

    func save(_ apps: [CustomApp]) {
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(apps) {
            try? data.write(to: fileURL)
        }
    }

    func add(_ app: CustomApp) {
        var apps = loadAll()
        if !apps.contains(where: { $0.bundleID == app.bundleID }) {
            apps.append(app)
            save(apps)
        }
    }

    func toggleTerminal(bundleID: String) {
        var apps = loadAll()
        if let index = apps.firstIndex(where: { $0.bundleID == bundleID }) {
            apps[index] = CustomApp(name: apps[index].name, bundleID: apps[index].bundleID, isTerminal: !apps[index].isTerminal)
            save(apps)
        }
    }

    func remove(bundleID: String) {
        var apps = loadAll()
        apps.removeAll { $0.bundleID == bundleID }
        save(apps)
    }
}
