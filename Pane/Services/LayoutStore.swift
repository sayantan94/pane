import Foundation

final class LayoutStore {
    private let directory: URL

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            self.directory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".config/pane/layouts")
        }
    }

    func save(_ layout: Layout) throws {
        try ensureDirectory()
        let fileURL = directory.appendingPathComponent("\(layout.id.uuidString).json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(layout)
        try data.write(to: fileURL)
    }

    func loadAll() throws -> [Layout] {
        try ensureDirectory()
        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        return try files.compactMap { fileURL in
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(Layout.self, from: data)
        }
    }

    func delete(_ id: UUID) throws {
        let fileURL = directory.appendingPathComponent("\(id.uuidString).json")
        try FileManager.default.removeItem(at: fileURL)
    }

    private func ensureDirectory() throws {
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }
    }
}
