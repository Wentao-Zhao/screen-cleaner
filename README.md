# 屏幕清洁 / ScreenCleaner

一个 macOS 13+ 菜单栏小工具，用于临时进入「屏幕清洁模式」。进入后屏幕变黑、键盘输入被阻止，只保留鼠标点击退出按钮，适合擦拭屏幕时避免误触。

## 功能

App 图标采用深色屏幕与薄荷绿擦布。状态栏使用对应的单色「屏幕＋擦拭角」矢量图形，自动适应深浅色菜单栏。主图位于 `Resources/AppIcon.png`，运行 `zsh scripts/generate-app-icon.sh` 可重建 `.icns` 和状态栏预览。

- 进入清洁模式后，所有显示器显示纯黑背景。
- 主显示器中央显示「退出清洁模式」按钮。
- 阻止普通键盘输入、功能键区和常见系统快捷键。
- 鼠标保持可用，点击按钮只退出清洁模式，不退出 App。
- 默认按 `⌃⌥⌘C` 开始清洁；右键菜单中的「偏好设置」支持录入自定义组合键。
- 「偏好设置」支持关闭状态栏图标。隐藏后快捷键仍然有效；从「应用程序」再次打开屏幕清洁，可返回设置并恢复图标。
- 快捷键需要包含 Command、Control 或 Option。Esc 取消录入；新组合键被占用时保留旧设置。启动时注册失败会保留图标，避免无法操作。
- 菜单栏图标仅响应右键，菜单包含「开始屏幕清洁」「偏好设置」「开机自启」和「退出 App」。
- 开机自启默认关闭，可在右键菜单中切换。

## 限制

- 电源键、Touch ID、合盖、系统级安全快捷键等硬件或系统保留操作无法由普通 App 拦截。
- 首次启用键盘拦截需要辅助功能权限。
- 当前发布包未使用 Apple Developer ID 公证，首次打开时可能被 Gatekeeper 拦截。

## 安装

从 [GitHub Releases](https://github.com/Wentao-Zhao/screen-cleaner/releases/latest) 下载最新 DMG：

```text
ScreenCleaner-1.1.0-test.dmg
```

安装步骤：

1. 打开 DMG。
2. 将 `ScreenCleaner.app` 拖到 `Applications`。
3. 如果 macOS 阻止直接打开，请右键 `ScreenCleaner.app`，选择「打开」，并在系统提示中确认。
4. App 启动后不会显示 Dock 图标，只驻留在菜单栏。

## 使用

1. 右键菜单栏图标。
2. 点击「开始屏幕清洁」。
3. 第一次使用时，根据系统提示打开辅助功能权限：

   ```text
   系统设置 > 隐私与安全性 > 辅助功能
   ```

4. 勾选「屏幕清洁」。
5. 再次右键菜单栏图标并点击「开始屏幕清洁」。
6. 清洁完成后，点击屏幕中央的「退出清洁模式」按钮。

如果旧版本正在运行，请先从菜单栏右键图标选择「退出 App」，再替换安装。

## 构建

```bash
cd ScreenCleaner
./scripts/package-app.sh
```

生成文件：

```text
dist/ScreenCleaner.app
```

如果本机 Command Line Tools 存在 Swift SDK 小版本不匹配问题，可以指定已安装 SDK：

```bash
SCREEN_CLEANER_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/package-app.sh
```

## 生成 DMG

```bash
./scripts/package-dmg.sh
```

生成文件：

```text
dist/ScreenCleaner-1.1.0-test.dmg
```

DMG 内包含 App、`Applications` 快捷方式和首次打开说明，同时输出 `.sha256` 校验文件。

## 自动化检查

逻辑测试：

```bash
swift run ScreenCleanerLogicTests
zsh scripts/check-controls.sh
```

发布构建：

```bash
swift build -c release
```

## 签名与权限

本地打包默认使用 ad-hoc 签名，并写入稳定的 designated requirement，减少重复构建导致辅助功能授权失效的概率。

如果有 Apple Development 或 Developer ID 证书，可以通过环境变量指定：

```bash
SCREEN_CLEANER_SIGNING_IDENTITY="Developer ID Application: Your Name" \
  ./scripts/package-app.sh
```

从非常早期版本升级时，如果辅助功能权限异常，可以在系统设置的辅助功能列表中删除旧的「屏幕清洁」条目，然后重新打开当前版本并授权一次。
