// 设备类型、分辨率预设与配置持久化
import Foundation

public enum DeviceKind: String, Codable, CaseIterable, Identifiable {
    case computer, tablet, phone
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .computer: return "电脑"
        case .tablet: return "平板"
        case .phone: return "手机"
        }
    }
}

/// 横屏原生像素
public struct Preset: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let kind: DeviceKind
    public let width: Int
    public let height: Int
    public var label: String { "\(name)  \(width)×\(height)" }

    public init(id: String, name: String, kind: DeviceKind, width: Int, height: Int) {
        self.id = id; self.name = name; self.kind = kind; self.width = width; self.height = height
    }
}

public enum Presets {
    public static let customID = "custom"

    // 2026-10 联网核实：OPPO 官方规格页、Apple 技术规格页、GSMArena
    public static let all: [Preset] = [
        Preset(id: "computer-1080p", name: "电脑 1080p", kind: .computer, width: 1920, height: 1080),
        Preset(id: "computer-1440p", name: "电脑 2K", kind: .computer, width: 2560, height: 1440),
        Preset(id: "computer-4k", name: "电脑 4K", kind: .computer, width: 3840, height: 2160),
        Preset(id: "oppo-pad-3-pro", name: "OPPO Pad 3 Pro", kind: .tablet, width: 3000, height: 2120),
        Preset(id: "ipad-air-11", name: "iPad Air 11 英寸", kind: .tablet, width: 2360, height: 1640),
        Preset(id: "ipad-air-13", name: "iPad Air 13 英寸", kind: .tablet, width: 2732, height: 2048),
        Preset(id: "ipad-pro-11", name: "iPad Pro 11 英寸", kind: .tablet, width: 2420, height: 1668),
        Preset(id: "ipad-pro-13", name: "iPad Pro 13 英寸", kind: .tablet, width: 2752, height: 2064),
        Preset(id: "ipad-mini", name: "iPad mini", kind: .tablet, width: 2266, height: 1488),
        Preset(id: "iphone-17", name: "iPhone 17", kind: .phone, width: 2622, height: 1206),
        Preset(id: "oppo-reno13-pro", name: "OPPO Reno13 Pro", kind: .phone, width: 2800, height: 1272),
        Preset(id: "android-20x9", name: "其他安卓手机（20:9）", kind: .phone, width: 2400, height: 1080),
    ]

    public static func preset(id: String?) -> Preset? { all.first { $0.id == id } }

    /// 按 UU 中的设备名猜测预设
    public static func guess(name: String, kind: DeviceKind) -> Preset? {
        let n = name.lowercased()
        let rules: [(String, String)] = [
            ("pad 3 pro", "oppo-pad-3-pro"), ("ipad air", "ipad-air-11"), ("ipad pro", "ipad-pro-11"),
            ("ipad mini", "ipad-mini"), ("iphone", "iphone-17"), ("reno13 pro", "oppo-reno13-pro"),
        ]
        if let hit = rules.first(where: { n.contains($0.0) }), let p = preset(id: hit.1), p.kind == kind { return p }
        switch kind {
        case .tablet: return preset(id: "ipad-air-11")
        case .phone: return preset(id: "android-20x9")
        case .computer: return preset(id: "computer-1080p")
        }
    }

    /// 首次配置时的类型预填：UU「电脑」组 → 电脑；名称含 iPad/Pad → 平板；其余 → 手机
    public static func guessKind(name: String, isComputerGroup: Bool) -> DeviceKind {
        if isComputerGroup { return .computer }
        return name.lowercased().contains("pad") ? .tablet : .phone
    }
}

public struct DeviceConfig: Codable, Identifiable, Hashable {
    public var name: String
    public var kind: DeviceKind
    public var presetID: String?
    public var width: Int
    public var height: Int
    public var hiDPI: Bool = true
    /// 缺失时沿用旧版本行为：电脑不处理，手机和平板处理。
    public var automatic: Bool?
    public var shouldAdjust: Bool { automatic ?? (kind != .computer) }

    public init(name: String, kind: DeviceKind, presetID: String? = nil, width: Int, height: Int,
                hiDPI: Bool = true, automatic: Bool? = nil) {
        self.name = name; self.kind = kind; self.presetID = presetID
        self.width = width; self.height = height; self.hiDPI = hiDPI; self.automatic = automatic
    }

    public var validationError: String? {
        guard (640...8192).contains(width), (360...8192).contains(height) else {
            return "屏幕宽度须为 640–8192，高度须为 360–8192 像素。"
        }
        if hiDPI && (width % 2 != 0 || height % 2 != 0) {
            return "使用高清缩放时，屏幕宽和高都须为偶数。"
        }
        return nil
    }
    public var id: String { name }

    public var sizeLabel: String { "\(width)×\(height)\(hiDPI ? " 高清" : "")" }

    public static func make(name: String, kind: DeviceKind) -> DeviceConfig {
        let p = Presets.guess(name: name, kind: kind)
        return DeviceConfig(name: name, kind: kind, presetID: p?.id, width: p?.width ?? 1920, height: p?.height ?? 1080, hiDPI: kind != .computer, automatic: true)
    }
}

public struct AppConfig: Codable {
    public init() {}
    public var devices: [DeviceConfig] = []
    public var defaultDevice: String?
    public var lastDevice: String?
    public var paused = false
    /// 远程时关闭物理屏（缺省关闭，在设置里开启；可选类型以兼容旧配置文件）
    public var disablePhysical: Bool?
    public var shouldDisablePhysical: Bool { disablePhysical ?? false }
    /// 看门狗（兜底恢复物理屏）缺省关闭，只有用户在设置里开启才安装
    public var watchdogEnabled: Bool?
    public var shouldRunWatchdog: Bool { watchdogEnabled ?? false }
    /// 是否已看过首次启动功能导览
    public var tourShown: Bool?
}

