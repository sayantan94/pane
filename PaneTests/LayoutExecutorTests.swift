import Testing
import Foundation
@testable import Pane

@Test func executorResolvesScreenFramesForZones() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let zones = [
        Zone(position: .leftHalf, appBundleID: "com.apple.Terminal",
             url: nil, path: nil, displayIndex: 0),
        Zone(position: .rightHalf, appBundleID: "com.google.Chrome",
             url: nil, path: nil, displayIndex: 0),
    ]

    let frames = LayoutExecutor.resolveFrames(zones: zones, screens: [screen])

    #expect(frames.count == 2)
    #expect(frames[0] == CGRect(x: 0, y: 0, width: 960, height: 1080))
    #expect(frames[1] == CGRect(x: 960, y: 0, width: 960, height: 1080))
}

@Test func executorFallsBackToMainScreenForInvalidDisplayIndex() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let zones = [
        Zone(position: .maximize, appBundleID: "com.apple.Finder",
             url: nil, path: nil, displayIndex: 5),
    ]

    let frames = LayoutExecutor.resolveFrames(zones: zones, screens: [screen])

    #expect(frames.count == 1)
    #expect(frames[0] == CGRect(x: 0, y: 0, width: 1920, height: 1080))
}
