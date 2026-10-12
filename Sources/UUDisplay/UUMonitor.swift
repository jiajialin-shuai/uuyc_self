// 监听 UU 被控状态：覆盖窗口，或 UU 被控服务持有的活跃显示器唤醒请求。
// 当前 UU 会话可能没有覆盖窗口；不能只检查窗口或常驻进程是否存在。
import CoreGraphics
import Darwin
import Foundation
import IOKit.pwr_mgt
import UUDisplayCore

final class UUMonitor {
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    private(set) var connected = false

    private var timer: Timer?
    private var lastSeen = Date.distantPast
    /// 切换主屏时覆盖窗口会短暂重建，断开需持续缺席这么久才算数
    private let debounce: TimeInterval = 1.5

    static func connectionPresent() -> Bool {
        let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        if list.contains(where: { ($0[kCGWindowOwnerName as String] as? String) == "UURemoteServer" }) { return true }
        return powerAssertionPresent()
    }

    private static func powerAssertionPresent() -> Bool {
        var assertions: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&assertions) == kIOReturnSuccess,
              let byPID = assertions?.takeRetainedValue() as? [NSNumber: [[String: Any]]] else { return false }
        for (pid, values) in byPID {
            let candidate = values.contains {
                UUConnectionSignal.matchesPowerAssertion(
                    name: $0[kIOPMAssertionNameKey] as? String,
                    type: $0[kIOPMAssertionTypeKey] as? String,
                    level: ($0[kIOPMAssertionLevelKey] as? NSNumber)?.intValue,
                    isUUServer: true)
            }
            if candidate && isUUServer(pid.int32Value) { return true }
        }
        return false
    }

    private static func isUUServer(_ pid: pid_t) -> Bool {
        var buffer = [CChar](repeating: 0, count: 4096)
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return false }
        let executable = URL(fileURLWithPath: String(cString: buffer))
        guard executable.lastPathComponent == "UURemoteServer",
              executable.deletingLastPathComponent().lastPathComponent == "Helpers",
              executable.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent == "Contents" else { return false }
        let appURL = executable.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return Bundle(url: appURL)?.bundleIdentifier == UUReader.bundleID
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.tick() }
        tick()
    }

    private func tick() {
        let now = Date()
        if UUMonitor.connectionPresent() {
            lastSeen = now
            if !connected {
                connected = true
                Log.info("检测到 UU 连入")
                onConnect?()
            }
        } else if connected, now.timeIntervalSince(lastSeen) > debounce {
            connected = false
            Log.info("检测到 UU 断开")
            onDisconnect?()
        }
    }
}
