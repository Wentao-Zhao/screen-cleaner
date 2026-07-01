# 屏幕清洁

一个 macOS 13+ 菜单栏小工具。进入清洁模式后：

- 阻止普通键盘输入和系统键盘快捷键。
- 所有显示器显示纯黑背景。
- 仅主显示器中央显示“退出清洁模式”按钮。
- 鼠标保持可用，点击按钮即可恢复。
- 点击“退出清洁模式”只结束当前清洁会话，应用继续驻留菜单栏。
- 状态栏图标仅响应右键，菜单提供“开始屏幕清洁”、开机自启开关和“退出 App”。
- 开机自启默认关闭。

电源键、Touch ID 等硬件级操作无法由普通应用拦截。

## 构建

```bash
cd ScreenCleaner
./scripts/package-app.sh
```

生成文件：

```text
dist/ScreenCleaner.app
```

## 生成测试版 DMG

没有 Developer ID 证书时，可以生成用于小范围测试的未公证 DMG：

```bash
./scripts/package-dmg.sh
```

生成文件：

```text
dist/ScreenCleaner-1.0.0-test.dmg
```

DMG 内包含应用、`Applications` 快捷方式和首次打开说明。接收方安装后需要
右键 `ScreenCleaner.app`，选择“打开”，并在系统提示中再次确认。直接双击可能
被 Gatekeeper 阻止。

如果旧版本正在运行，先从菜单栏右键图标并选择“退出 App”，再替换安装。应用打开
后不会显示窗口，也不会出现在 Dock；它只驻留在菜单栏，后续操作都通过右键菜单栏
图标完成。

测试版适合熟人或内部测试。若要让普通用户正常双击安装，需要使用 Developer ID
证书签名并提交 Apple 公证。

当前机器的 Command Line Tools 存在默认 Swift SDK 小版本不匹配问题，可以指定已安装的兼容 SDK：

```bash
SCREEN_CLEANER_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  ./scripts/package-app.sh
```

## 运行

```bash
open dist/ScreenCleaner.app
```

首次点击“开始屏幕清洁”时，macOS 会请求辅助功能权限。进入：

```text
系统设置 > 隐私与安全性 > 辅助功能
```

允许“屏幕清洁”后，再次右键菜单栏图标并点击“开始屏幕清洁”。

本地打包使用稳定的 designated requirement，后续重新构建不会因为二进制
`CDHash` 改变而自动丢失授权。也可以通过
`SCREEN_CLEANER_SIGNING_IDENTITY` 指定 Apple Development 或 Developer ID
证书。

从旧版本升级时，需要在辅助功能列表中删除旧的“屏幕清洁”条目，重新打开
当前 [ScreenCleaner.app](dist/ScreenCleaner.app) 并授权一次。旧版本使用的是
仅匹配单次构建的临时签名，无法自动迁移。

## 自动化检查

逻辑测试：

```bash
SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
swift run --sdk "$SDK" ScreenCleanerLogicTests
```

发布构建：

```bash
SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
swift build -c release --sdk "$SDK"
```

使用完整 Xcode 且工具链匹配时，可以省略 `--sdk` 参数。
