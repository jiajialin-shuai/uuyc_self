import Foundation
import XCTest
@testable import UUDisplayCore

final class RemotePolicyTests: XCTestCase {
    private func legacyDevice(kind: String) throws -> DeviceConfig {
        let json = #"{"name":"legacy","kind":"KIND","width":2360,"height":1640,"hiDPI":true}"#
            .replacingOccurrences(of: "KIND", with: kind)
        return try JSONDecoder().decode(DeviceConfig.self, from: Data(json.utf8))
    }

    func testUpgradePreservesExistingComputerAndMobileBehavior() throws {
        XCTAssertFalse(try legacyDevice(kind: "computer").shouldAdjust)
        XCTAssertTrue(try legacyDevice(kind: "tablet").shouldAdjust)
        XCTAssertTrue(try legacyDevice(kind: "phone").shouldAdjust)
        var oldComputer = try legacyDevice(kind: "computer")
        oldComputer.automatic = true
        XCTAssertTrue(oldComputer.shouldAdjust)
    }

    func testNewComputerUsesDesktopResolutionAndOrdinaryScaling() {
        let cfg = DeviceConfig.make(name: "remote PC", kind: .computer)
        XCTAssertEqual(cfg.width, 1920)
        XCTAssertEqual(cfg.height, 1080)
        XCTAssertFalse(cfg.hiDPI)
        XCTAssertTrue(cfg.shouldAdjust)
        XCTAssertNil(cfg.validationError)
    }

    func testDeviceOptOutAndCustomResolutionSurviveRoundTrip() throws {
        let cfg = DeviceConfig(name: "remote Mac", kind: .computer, width: 3440, height: 1440,
                               hiDPI: false, automatic: false)
        let loaded = try JSONDecoder().decode(DeviceConfig.self, from: JSONEncoder().encode(cfg))
        XCTAssertEqual(cfg, loaded)
        XCTAssertFalse(loaded.shouldAdjust)
    }

    func testInvalidAndOddHiDPIInputNeverPassesValidation() {
        for width in [-1, 0, Int.max] {
            XCTAssertNotNil(DeviceConfig(name: "PC", kind: .computer, width: width, height: 1080).validationError)
        }
        XCTAssertNotNil(DeviceConfig(name: "PC", kind: .computer, width: 1920, height: 0).validationError)
        XCTAssertNotNil(DeviceConfig(name: "PC", kind: .computer, width: 1921, height: 1080).validationError)
        XCTAssertNil(DeviceConfig(name: "PC", kind: .computer, width: 1921, height: 1080, hiDPI: false).validationError)
    }

    func testEveryPresetHasValidDimensions() {
        for preset in Presets.all {
            XCTAssertNil(DeviceConfig(name: preset.name, kind: preset.kind, width: preset.width, height: preset.height).validationError)
        }
    }

    func testManualRestoreSurvivesAutomaticPreferenceChanges() {
        var state = RemoteSessionState()
        XCTAssertTrue(state.wantsPhysicalOff(automaticEnabled: true, virtualReady: true))
        state.restoreManually()
        XCTAssertTrue(state.keepsPhysicalOn)
        // 配置刷新、设备重新识别只改变自动设置，不能清除本次亮屏选择。
        XCTAssertFalse(state.wantsPhysicalOff(automaticEnabled: false, virtualReady: true))
        XCTAssertFalse(state.wantsPhysicalOff(automaticEnabled: true, virtualReady: true))
    }

    func testManualBlackoutRequiresReadyVirtualScreen() {
        var state = RemoteSessionState()
        state.restoreManually()
        state.blackoutManually()
        XCTAssertFalse(state.keepsPhysicalOn)
        XCTAssertFalse(state.wantsPhysicalOff(automaticEnabled: true, virtualReady: false))
        XCTAssertTrue(state.wantsPhysicalOff(automaticEnabled: false, virtualReady: true))
    }

    func testNextConnectionResetsManualOverride() {
        var state = RemoteSessionState()
        state.restoreManually()
        state.endSession()
        XCTAssertFalse(state.keepsPhysicalOn)
        XCTAssertTrue(state.wantsPhysicalOff(automaticEnabled: true, virtualReady: true))
        XCTAssertFalse(state.wantsPhysicalOff(automaticEnabled: false, virtualReady: true))
    }

    func testOldAppConfigDoesNotEnableBlackoutOrWatchdogOnUpgrade() throws {
        let data = Data(#"{"devices":[],"paused":false}"#.utf8)
        let cfg = try JSONDecoder().decode(AppConfig.self, from: data)
        XCTAssertFalse(cfg.shouldDisablePhysical)
        XCTAssertFalse(cfg.shouldRunWatchdog)
    }
}
