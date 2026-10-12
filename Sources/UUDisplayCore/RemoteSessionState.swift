/// 用户在一次连接中的物理屏选择；与设备规格和全局自动设置分离。
public struct RemoteSessionState {
    public enum Choice { case automatic, keepOn, off }
    public private(set) var choice: Choice = .automatic
    public init() {}
    public var keepsPhysicalOn: Bool { choice == .keepOn }
    public mutating func restoreManually() { choice = .keepOn }
    public mutating func blackoutManually() { choice = .off }
    public mutating func endSession() { choice = .automatic }
    public func wantsPhysicalOff(automaticEnabled: Bool, virtualReady: Bool) -> Bool {
        guard virtualReady else { return false }
        switch choice {
        case .automatic: return automaticEnabled
        case .keepOn: return false
        case .off: return true
        }
    }
}
