import AppKit
import CryptoKit

enum DisplayFingerprint {
    static func current() -> String {
        let screens = NSScreen.screens
        let parts = screens.enumerated().map { (i, s) -> String in
            let w = Int(s.frame.size.width)
            let h = Int(s.frame.size.height)
            let name = s.localizedName
            return "\(i):\(name):\(w)x\(h)"
        }
        let joined = parts.joined(separator: "|") + "|count=\(screens.count)"
        let digest = SHA256.hash(data: Data(joined.utf8))
        return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}
