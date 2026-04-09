import Testing
import Foundation
@testable import Pane

@Test func leftHalfFrame() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let frame = ZonePosition.leftHalf.frame(in: screen)

    #expect(frame.origin.x == 0)
    #expect(frame.origin.y == 0)
    #expect(frame.size.width == 960)
    #expect(frame.size.height == 1080)
}

@Test func rightHalfFrame() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let frame = ZonePosition.rightHalf.frame(in: screen)

    #expect(frame.origin.x == 960)
    #expect(frame.origin.y == 0)
    #expect(frame.size.width == 960)
    #expect(frame.size.height == 1080)
}

@Test func topLeftQuarterFrame() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let frame = ZonePosition.topLeft.frame(in: screen)

    #expect(frame.origin.x == 0)
    #expect(frame.origin.y == 0)
    #expect(frame.size.width == 960)
    #expect(frame.size.height == 540)
}

@Test func bottomRightQuarterFrame() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let frame = ZonePosition.bottomRight.frame(in: screen)

    #expect(frame.origin.x == 960)
    #expect(frame.origin.y == 540)
    #expect(frame.size.width == 960)
    #expect(frame.size.height == 540)
}

@Test func leftThirdFrame() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let frame = ZonePosition.leftThird.frame(in: screen)

    #expect(frame.origin.x == 0)
    #expect(frame.origin.y == 0)
    #expect(frame.size.width == 640)
    #expect(frame.size.height == 1080)
}

@Test func rightTwoThirdsFrame() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let frame = ZonePosition.rightTwoThirds.frame(in: screen)

    #expect(frame.origin.x == 640)
    #expect(frame.origin.y == 0)
    #expect(frame.size.width == 1280)
    #expect(frame.size.height == 1080)
}

@Test func maximizeFrame() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let frame = ZonePosition.maximize.frame(in: screen)

    #expect(frame.origin.x == 0)
    #expect(frame.origin.y == 0)
    #expect(frame.size.width == 1920)
    #expect(frame.size.height == 1080)
}

@Test func frameWithOffsetScreen() {
    let screen = CGRect(x: 1920, y: 0, width: 2560, height: 1440)
    let frame = ZonePosition.leftHalf.frame(in: screen)

    #expect(frame.origin.x == 1920)
    #expect(frame.origin.y == 0)
    #expect(frame.size.width == 1280)
    #expect(frame.size.height == 1440)
}
