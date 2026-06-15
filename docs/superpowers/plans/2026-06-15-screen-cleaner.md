# 屏幕清洁实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 构建一个 macOS 13+ 菜单栏应用，在清洁模式中拦截键盘输入、覆盖所有显示器，并允许通过主屏幕鼠标按钮退出。

**架构：** `CleaningSessionCoordinator` 负责状态和资源生命周期，通过协议依赖权限、键盘拦截和屏幕覆盖服务。AppKit 服务封装 `CGEventTap` 与 `NSWindow`，SwiftUI 只负责菜单栏和退出按钮。纯状态逻辑和屏幕选择策略使用 XCTest 验证。

**技术栈：** Swift 5.9 Package、SwiftUI、AppKit、ApplicationServices、CoreGraphics、XCTest

---

## 文件结构

- `Package.swift`：Swift Package 定义和 macOS 13 最低版本。
- `Sources/ScreenCleaner/ScreenCleanerApp.swift`：应用入口和菜单栏界面。
- `Sources/ScreenCleaner/CleaningSessionCoordinator.swift`：清洁会话状态机和依赖协议。
- `Sources/ScreenCleaner/AccessibilityPermissionManager.swift`：辅助功能权限检查与系统设置跳转。
- `Sources/ScreenCleaner/KeyboardEventBlocker.swift`：全局键盘事件 tap 生命周期。
- `Sources/ScreenCleaner/ScreenOverlayController.swift`：多显示器黑屏窗口。
- `Sources/ScreenCleaner/MenuBarIcon.swift`：显示器与扫把模板图标。
- `Tests/ScreenCleanerTests/CleaningSessionCoordinatorTests.swift`：状态与回滚测试。
- `Tests/ScreenCleanerTests/ScreenSelectionPolicyTests.swift`：主屏幕选择测试。
- `Resources/Info.plist`：应用包元数据。
- `scripts/package-app.sh`：构建并封装 `.app`。
- `README.md`：构建、运行和授权说明。

### 任务 1：初始化项目与失败测试

- [ ] 创建 `Package.swift`，包含可执行 target 和 test target。
- [ ] 创建协调器测试，定义权限不足、拦截失败、成功启动和退出行为。
- [ ] 创建屏幕选择策略测试，定义主屏幕只显示一次退出控件。
- [ ] 运行 `swift test`，确认因生产类型不存在而失败。

测试接口：

```swift
@MainActor
final class CleaningSessionCoordinator {
    private(set) var state: CleaningState
    func start()
    func stop()
}
```

### 任务 2：实现状态机最小逻辑

- [ ] 定义 `AccessibilityPermissionProviding`、`KeyboardBlocking` 和 `ScreenOverlayPresenting`。
- [ ] 实现 `CleaningSessionCoordinator.start()`：权限检查、启动 blocker、显示 overlay。
- [ ] 实现 `stop()`：关闭 overlay、停止 blocker、回到 idle。
- [ ] 运行 `swift test`，确认协调器与屏幕策略测试通过。

核心启动顺序：

```swift
guard permission.isTrusted else {
    permission.requestAccess()
    state = .needsPermission
    return
}

guard keyboardBlocker.start() else {
    state = .failed("无法锁定键盘输入")
    return
}

overlayPresenter.show(onExit: { [weak self] in self?.stop() })
state = .active
```

### 任务 3：实现 macOS 系统服务

- [ ] 使用 `AXIsProcessTrustedWithOptions` 实现权限管理器。
- [ ] 使用 `CGEvent.tapCreate` 实现键盘拦截，并在 tap 超时后重新启用。
- [ ] 使用 `NSScreen.screens`、`NSWindow` 和 `NSHostingView` 实现所有屏幕覆盖。
- [ ] 运行 `swift test` 和 `swift build`，确认服务可编译且逻辑测试通过。

事件掩码：

```swift
let mask = (1 << CGEventType.keyDown.rawValue)
    | (1 << CGEventType.keyUp.rawValue)
    | (1 << CGEventType.flagsChanged.rawValue)
```

### 任务 4：实现菜单栏界面与图标

- [ ] 使用 `MenuBarExtra` 和 `.menuBarExtraStyle(.window)` 创建菜单栏弹窗。
- [ ] 根据协调器状态显示开始按钮、权限说明和错误信息。
- [ ] 使用 `NSBezierPath` 绘制模板图标，扫把缩放为确认稿的 80%。
- [ ] 设置 accessory activation policy，不显示 Dock 图标。
- [ ] 运行 `swift build -c release`，确认无编译错误。

### 任务 5：打包、文档和验收

- [ ] 创建 `Info.plist` 和 `scripts/package-app.sh`。
- [ ] 创建 `README.md`，说明辅助功能授权、构建和运行方式。
- [ ] 运行 `swift test`。
- [ ] 运行 `swift build -c release`。
- [ ] 运行 `scripts/package-app.sh` 并检查 `dist/ScreenCleaner.app/Contents/MacOS/ScreenCleaner`。
- [ ] 检查 Git diff 和项目文件列表，确认规格需求均有对应实现。

