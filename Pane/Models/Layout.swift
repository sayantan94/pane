import Foundation

enum ZonePosition: String, Codable, CaseIterable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case leftThird
    case centerThird
    case rightThird
    case leftTwoThirds
    case rightTwoThirds
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case maximize
}

struct Zone: Codable, Identifiable {
    var id = UUID()
    var position: ZonePosition
    var appBundleID: String
    var url: String?
    var path: String?
    var displayIndex: Int

    enum CodingKeys: String, CodingKey {
        case position, appBundleID, url, path, displayIndex
    }
}

struct Layout: Codable, Identifiable {
    var id = UUID()
    var name: String
    var shortcut: String?
    var gridTemplate: String
    var zones: [Zone]

    enum CodingKeys: String, CodingKey {
        case name, shortcut, gridTemplate, zones
    }
}
