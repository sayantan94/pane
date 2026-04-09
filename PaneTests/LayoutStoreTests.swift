import Testing
import Foundation
@testable import Pane

@Test func saveAndLoadLayout() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("pane-test-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let store = LayoutStore(directory: tempDir)

    let layout = Layout(
        name: "Test",
        shortcut: "ctrl+option+1",
        gridTemplate: "left-half+right-half",
        zones: [
            Zone(
                position: .leftHalf,
                appBundleID: "com.apple.Terminal",
                url: nil,
                path: "/tmp",
                displayIndex: 0
            ),
        ]
    )

    try store.save(layout)

    let loaded = try store.loadAll()
    #expect(loaded.count == 1)
    #expect(loaded[0].name == "Test")
    #expect(loaded[0].zones[0].appBundleID == "com.apple.Terminal")
}

@Test func deleteLayout() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("pane-test-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let store = LayoutStore(directory: tempDir)

    let layout = Layout(
        name: "ToDelete",
        shortcut: nil,
        gridTemplate: "maximize",
        zones: []
    )

    try store.save(layout)
    #expect(try store.loadAll().count == 1)

    try store.delete(layout.id)
    #expect(try store.loadAll().count == 0)
}

@Test func updateLayout() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("pane-test-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let store = LayoutStore(directory: tempDir)

    var layout = Layout(
        name: "Original",
        shortcut: nil,
        gridTemplate: "maximize",
        zones: []
    )

    try store.save(layout)

    layout.name = "Updated"
    try store.save(layout)

    let loaded = try store.loadAll()
    #expect(loaded.count == 1)
    #expect(loaded[0].name == "Updated")
}

@Test func loadAllFromEmptyDirectory() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("pane-test-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let store = LayoutStore(directory: tempDir)
    let loaded = try store.loadAll()

    #expect(loaded.isEmpty)
}
