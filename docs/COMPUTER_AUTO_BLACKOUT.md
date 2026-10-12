# 电脑连接自动熄屏

## 已确认的需求

1. 支持通过 UU 远程从 Windows/Mac 电脑连接本机，沿用手机和平板的虚拟屏流程。
2. 每台设备配置自动处理开关、虚拟屏分辨率与高清缩放；电脑初始规格为 1920×1080、普通缩放，可改为 2K/4K 或自定义。
3. 连接时：识别配置 → 创建虚拟屏 → 确认上线、设主屏成功 → 按全局设置熄灭物理屏。
4. 手动恢复屏幕：保留虚拟屏，本次连接内保持亮屏；下次连接恢复自动策略。物理屏采用扩展桌面，暂不添加镜像功能。
5. 结束时：先恢复物理屏，再删除虚拟屏并恢复布局；保留原有恢复快捷键与后台守护。
6. 提供会话内手动熄屏入口。用户主动再次熄屏可以取消本次亮屏覆盖。

## 实现范围

- `UUDisplayCore`：设备配置、旧配置兼容、分辨率校验、会话级亮屏覆盖；纯逻辑测试不调用显示 API。
- `Config.swift`：配置存储与测试目录隔离。
- `Coordinator.swift`：按设备开关处理电脑；未知设备仅使用明确配置的默认设备，不拿上次设备猜测。
- `SetupWizard.swift` / `SettingsWindow.swift` / `StatusBarController.swift`：电脑规格、自动处理开关、手动熄屏与本次保持亮屏状态。
- `DisplayManager.swift` / `PhysicalDisplays.swift`：虚拟屏准备成功后熄屏、逐项检查事务结果、保留恢复顺序。
- `README.md` / 导览 / 构建脚本：fork 的功能、构建与使用说明。

## 兼容与限制

- 保留上游 MIT 许可证。
- 旧配置缺少新开关时，电脑仍不调整，手机和平板仍自动处理。新添加的电脑默认允许自动处理。
- 全局熄屏默认开关保持上游行为，实际使用时在设置中开启；不会因构建或测试自动修改系统屏幕。
- 创建/关闭显示器依赖未公开的 macOS API，UU 识别依赖其窗口结构；系统或 UU 更新后需要重新验收。
- 目前按单控制端连接设计。首次切换到虚拟屏可能需要在 UU 的显示面板选中它。
- 当前虚拟屏刷新率沿用上游 60 Hz；本次不承诺高帧率游戏体验。

## 验收

- [x] fork 在用户账号下创建成功，并设置 `origin` 与 `upstream`。
- [x] 新电脑配置默认值、旧配置兼容、无效尺寸、亮屏覆盖与下一会话重置测试通过（9 项 XCTest）。
- [x] Release App 构建与签名检查通过（1.1.0，ad-hoc 签名）。
- [ ] 设置界面实际打开，电脑尺寸和自动处理开关可操作。
- [ ] 真实电脑端 UU 连入：虚拟屏工作，iMac 背光熄灭，远程画面和键鼠连续正常。
- [ ] 远程中手动点亮：远程仍可操作，本次保持亮屏；再次手动熄屏可用。
- [ ] 断开、重连、程序正常退出与异常退出后恢复正确。

## 当前状态

2026-10-12：基于上游 `6d4e8450a5bcc757b3856e578edb555f3439ffc2` 完成第一版实现；fork 为 `https://github.com/jiajialin-shuai/uuyc_self`，分支 `feat/computer-auto-blackout`。

已验证：`scripts/test.sh` 9/9 通过；`SIGN_IDENTITY=- scripts/build-app.sh` 成功且 `codesign --verify --strict --deep` 通过。

工具链：系统 `xcode-select` 指向 Command Line Tools，其中没有 XCTest；测试脚本在本次命令内使用已安装的 `/Applications/Xcode-beta.app`，不修改系统选择。App 可用 Command Line Tools 构建。

界面预览：使用 `UUDISPLAY_DATA_DIR=.../build/preview-data` 与 `--preview-settings`，不读取真实设备，不执行显示器切换，不安装后台守护。App 已启动，CUA 检查时 Mac 锁定，界面验收待解锁。

真实远程验收尚未进行，不能以单元测试或签名检查证明背光已熄灭或 UU 画面连续。
