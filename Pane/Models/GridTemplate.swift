import Foundation

extension ZonePosition {
    func frame(in screen: CGRect) -> CGRect {
        let x = screen.origin.x
        let y = screen.origin.y
        let w = screen.size.width
        let h = screen.size.height

        switch self {
        case .leftHalf:
            return CGRect(x: x, y: y, width: w / 2, height: h)
        case .rightHalf:
            return CGRect(x: x + w / 2, y: y, width: w / 2, height: h)
        case .topHalf:
            return CGRect(x: x, y: y, width: w, height: h / 2)
        case .bottomHalf:
            return CGRect(x: x, y: y + h / 2, width: w, height: h / 2)
        case .leftThird:
            return CGRect(x: x, y: y, width: floor(w / 3), height: h)
        case .centerThird:
            return CGRect(x: x + floor(w / 3), y: y, width: ceil(w / 3), height: h)
        case .rightThird:
            return CGRect(x: x + floor(w / 3) * 2, y: y, width: w - floor(w / 3) * 2, height: h)
        case .leftTwoThirds:
            return CGRect(x: x, y: y, width: floor(w / 3) * 2, height: h)
        case .rightTwoThirds:
            return CGRect(x: x + floor(w / 3), y: y, width: w - floor(w / 3), height: h)
        case .topLeft:
            return CGRect(x: x, y: y, width: w / 2, height: h / 2)
        case .topRight:
            return CGRect(x: x + w / 2, y: y, width: w / 2, height: h / 2)
        case .bottomLeft:
            return CGRect(x: x, y: y + h / 2, width: w / 2, height: h / 2)
        case .bottomRight:
            return CGRect(x: x + w / 2, y: y + h / 2, width: w / 2, height: h / 2)
        case .maximize:
            return CGRect(x: x, y: y, width: w, height: h)
        }
    }
}
