import Foundation
import CoreGraphics

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
    case custom
}

struct CustomFrame: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat

    func rect(in screen: CGRect) -> CGRect {
        CGRect(
            x: screen.origin.x + x * screen.size.width,
            y: screen.origin.y + y * screen.size.height,
            width: w * screen.size.width,
            height: h * screen.size.height
        )
    }
}

struct Zone: Codable, Identifiable {
    var id = UUID()
    var position: ZonePosition
    var appBundleID: String
    var path: String?
    var displayIndex: Int
    var commands: [String]?
    var customFrame: CustomFrame?
    var spaceIndex: Int?

    enum CodingKeys: String, CodingKey {
        case position, appBundleID, path, displayIndex, commands, customFrame, spaceIndex
    }
}

struct Layout: Codable, Identifiable {
    var id = UUID()
    var name: String
    var gridTemplate: String
    var zones: [Zone]
    var displayFingerprint: String?
    var autoApply: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, gridTemplate, zones, displayFingerprint, autoApply
    }
}
