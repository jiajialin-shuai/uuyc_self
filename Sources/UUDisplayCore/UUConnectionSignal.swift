/// 严格匹配 UU 被控服务的活跃显示器唤醒请求，排除常驻服务和普通防睡眠请求。
public enum UUConnectionSignal {
    public static func matchesPowerAssertion(name: String?, type: String?, level: Int?, isUUServer: Bool) -> Bool {
        isUUServer && name == "UURemote Disable Display Sleep"
            && type == "PreventUserIdleDisplaySleep" && level == 255
    }
}
