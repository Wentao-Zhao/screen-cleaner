# 屏幕清洁测试版 DMG 设计规格

## 目标

为未配置 Developer ID 证书的屏幕清洁应用生成可分享的测试版 DMG。

## 内容

- `ScreenCleaner.app`：当前发布构建。
- `Applications`：指向系统“应用程序”目录的快捷方式。
- `首次打开说明.txt`：说明未公证测试版的安装和首次打开步骤。

## 分发限制

- 应用继续使用临时签名，不执行 Apple 公证。
- 接收方首次启动时可能遇到 Gatekeeper 拦截，需要右键应用并选择“打开”。
- 若辅助功能权限已存在旧条目，需要删除旧条目后重新授权当前应用。

## 输出

脚本读取 `Info.plist` 的版本号，生成：

```text
dist/ScreenCleaner-<version>-test.dmg
```

DMG 使用 `UDZO` 压缩格式，并在生成后通过 `hdiutil verify` 验证。
