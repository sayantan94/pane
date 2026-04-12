import Foundation

final class LayoutStore {
    private let directory: URL
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder = JSONDecoder()

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/pane/layouts")
    }

    func save(_ layout: Layout) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(layout)
        try data.write(to: directory.appendingPathComponent("\(layout.id.uuidString).json"))
    }

    func loadAll() throws -> [Layout] {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let files = try FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        return files.compactMap { url in
            try? decoder.decode(Layout.self, from: Data(contentsOf: url))
        }
    }

    func delete(_ id: UUID) throws {
        try FileManager.default.removeItem(
            at: directory.appendingPathComponent("\(id.uuidString).json")
        )
    }
}
