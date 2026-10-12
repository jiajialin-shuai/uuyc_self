import XCTest
@testable import UUDisplayCore

final class UUConnectionSignalTests: XCTestCase {
    func testActiveUUServerDisplayAssertionSignalsConnection() {
        XCTAssertTrue(UUConnectionSignal.matchesPowerAssertion(
            name: "UURemote Disable Display Sleep", type: "PreventUserIdleDisplaySleep", level: 255, isUUServer: true))
    }

    func testBackgroundAndExpiredAssertionsDoNotSignalConnection() {
        let cases: [(String?, String?, Int?, Bool)] = [
            ("Wake Up Display", "UserIsActive", 255, true),
            ("UURemote Disable Idle System Sleep", "PreventUserIdleSystemSleep", 255, true),
            ("UURemote Disable Display Sleep", "PreventUserIdleDisplaySleep", 0, true),
            ("UURemote Disable Display Sleep", "PreventUserIdleDisplaySleep", 255, false),
            (nil, "PreventUserIdleDisplaySleep", 255, true),
            ("UURemote Disable Display Sleep", nil, 255, true),
            ("UURemote Disable Display Sleep", "PreventUserIdleDisplaySleep", nil, true),
        ]
        for (name, type, level, isServer) in cases {
            XCTAssertFalse(UUConnectionSignal.matchesPowerAssertion(name: name, type: type, level: level, isUUServer: isServer))
        }
    }
}
