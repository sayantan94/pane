import AppKit
import CoreGraphics

final class SpaceManager {
    private let conn: Int

    private typealias GetConnectionFunc = @convention(c) () -> Int
    private typealias CopySpacesFunc = @convention(c) (Int) -> CFArray?
    private typealias MoveWindowsFunc = @convention(c) (Int, CFArray, Int) -> Void

    private let copySpacesFn: CopySpacesFunc?
    private let moveWindowsFn: MoveWindowsFunc?

    init() {
        let cg = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_NOW)

        if let sym = dlsym(cg, "CGSGetDefaultConnection") {
            self.conn = unsafeBitCast(sym, to: GetConnectionFunc.self)()
        } else {
            self.conn = 0
        }

        self.copySpacesFn = dlsym(cg, "CGSCopyManagedDisplaySpaces")
            .map { unsafeBitCast($0, to: CopySpacesFunc.self) }

        self.moveWindowsFn = dlsym(cg, "CGSMoveWindowsToManagedSpace")
            .map { unsafeBitCast($0, to: MoveWindowsFunc.self) }
    }

    func currentSpaceID() -> Int? {
        guard let fn = copySpacesFn,
              let displays = fn(conn) as? [[String: Any]],
              let display = displays.first,
              let currentSpace = display["Current Space"] as? [String: Any],
              let spaceID = currentSpace["id64"] as? Int else { return nil }
        return spaceID
    }

    func moveWindows(_ windowIDs: [CGWindowID], toSpace spaceID: Int) {
        guard let fn = moveWindowsFn, !windowIDs.isEmpty else { return }
        fn(conn, windowIDs.map { NSNumber(value: $0) } as CFArray, spaceID)
    }
}

func windowIDs(for app: NSRunningApplication) -> [CGWindowID] {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return [] }
    return list.compactMap { info -> CGWindowID? in
        guard let pid = info[kCGWindowOwnerPID as String] as? Int,
              pid == Int(app.processIdentifier),
              let wid = info[kCGWindowNumber as String] as? CGWindowID,
              let layer = info[kCGWindowLayer as String] as? Int,
              layer == 0 else { return nil }
        return wid
    }
}
