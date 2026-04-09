import Testing
import Foundation
@testable import Pane

@Test func layoutEncodesToJSON() throws {
    let layout = Layout(
        name: "Coding",
        shortcut: "ctrl+option+1",
        gridTemplate: "left-half+right-half",
        zones: [
            Zone(
                position: .leftHalf,
                appBundleID: "com.apple.Terminal",
                url: nil,
                path: "/Users/test/project",
                displayIndex: 0
            ),
            Zone(
                position: .rightHalf,
                appBundleID: "com.google.Chrome",
                url: "https://github.com",
                path: nil,
                displayIndex: 0
            ),
        ]
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
    let data = try encoder.encode(layout)
    let json = String(data: data, encoding: .utf8)!

    #expect(json.contains("\"name\" : \"Coding\""))
    #expect(json.contains("\"appBundleID\" : \"com.apple.Terminal\""))
    #expect(json.contains("\"url\" : \"https://github.com\""))
    #expect(json.contains("\"path\" : \"/Users/test/project\""))
}

@Test func layoutDecodesFromJSON() throws {
    let json = """
    {
        "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
        "name": "Coding",
        "shortcut": "ctrl+option+1",
        "gridTemplate": "left-half+right-half",
        "zones": [
            {
                "position": "leftHalf",
                "appBundleID": "com.apple.Terminal",
                "path": "/Users/test/project",
                "displayIndex": 0
            }
        ]
    }
    """

    let data = json.data(using: .utf8)!
    let layout = try JSONDecoder().decode(Layout.self, from: data)

    #expect(layout.name == "Coding")
    #expect(layout.shortcut == "ctrl+option+1")
    #expect(layout.zones.count == 1)
    #expect(layout.zones[0].position == .leftHalf)
    #expect(layout.zones[0].appBundleID == "com.apple.Terminal")
    #expect(layout.zones[0].path == "/Users/test/project")
    #expect(layout.zones[0].url == nil)
}

@Test func layoutHasStableID() {
    let layout1 = Layout(
        name: "Test",
        shortcut: nil,
        gridTemplate: "maximize",
        zones: []
    )
    let layout2 = Layout(
        name: "Test",
        shortcut: nil,
        gridTemplate: "maximize",
        zones: []
    )

    #expect(layout1.id != layout2.id)
}
