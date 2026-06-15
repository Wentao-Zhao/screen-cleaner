# 屏幕清洁

一个 macOS 13+ 菜单栏小工具。进入清洁模式后：

- 阻止普通键盘输入和系统键盘快捷键。
- 所有显示器显示纯黑背景。
- 仅主显示器中央显示“退出清洁模式”按钮。
- 鼠标保持可用，点击按钮即可恢复。
- 状态栏图标左键打开控制弹窗，右键提供“退出 App”。

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

允许“屏幕清洁”后，再次点击菜单栏中的“开始屏幕清洁”。

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
