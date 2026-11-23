import AppKit
import ScreenCleanerCore

@MainActor
final class CleanerPreferencesWindowController: NSWindowController, NSWindowDelegate {
  var onShortcutChanged: ((CleaningShortcut) -> String?)?
  var onVisibilityChanged: ((Bool) -> Void)?
  var onRecordingChanged: ((Bool) -> Void)?
  var onStart: (() -> Void)?
  var onQuit: (() -> Void)?
  private let preferences: CleanerPreferences
  private let recorder = CleaningShortcutRecorder()
  private let iconSwitch = NSSwitch()
  private let message = NSTextField(wrappingLabelWithString: "")

  init(preferences: CleanerPreferences) {
    self.preferences = preferences
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 242),
      styleMask: [.titled, .closable], backing: .buffered, defer: false)
    window.title = "屏幕清洁 · 偏好设置"
    window.isReleasedWhenClosed = false
    super.init(window: window)
    window.delegate = self
    let content = NSStackView()
    content.orientation = .vertical
    content.alignment = .leading
    content.spacing = 18
    content.translatesAutoresizingMaskIntoConstraints = false
    window.contentView!.addSubview(content)
    NSLayoutConstraint.activate([
      content.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 24),
      content.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -24),
      content.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 22),
    ])
    let shortcutRow = NSStackView(views: [NSTextField(labelWithString: "启动快捷键"), recorder])
    shortcutRow.spacing = 22
    recorder.widthAnchor.constraint(equalToConstant: 218).isActive = true
    recorder.setAccessibilityLabel("启动快捷键")
    content.addArrangedSubview(shortcutRow)
    let iconRow = NSStackView(views: [NSTextField(labelWithString: "显示状态栏图标"), iconSwitch])
    iconRow.spacing = 20
    iconSwitch.setAccessibilityLabel("显示状态栏图标")
    iconSwitch.target = self
    iconSwitch.action = #selector(visibilityChanged)
    content.addArrangedSubview(iconRow)
    let hint = NSTextField(wrappingLabelWithString:
      "点击快捷键后按下新组合键，Esc 取消。\n隐藏图标后仍可用快捷键启动；再次打开「屏幕清洁」可回到这里。")
    hint.font = .systemFont(ofSize: 12)
    hint.textColor = .secondaryLabelColor
    content.addArrangedSubview(hint)
    hint.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
    message.font = .systemFont(ofSize: 12)
    message.textColor = .systemRed
    content.addArrangedSubview(message)
    message.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
    let start = NSButton(title: "开始屏幕清洁", target: self, action: #selector(startCleaning))
    let quit = NSButton(title: "退出 App", target: self, action: #selector(quitApplication))
    start.bezelStyle = .rounded
    quit.bezelStyle = .rounded
    content.addArrangedSubview(NSStackView(views: [start, quit]))
    recorder.onRecordingChanged = { [weak self] in self?.onRecordingChanged?($0) }
    recorder.onCapture = { [weak self] shortcut in
      guard let self else { return }
      self.message.stringValue = self.onShortcutChanged?(shortcut) ?? ""
      self.reloadControls()
    }
    reloadControls()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  func show(message: String = "") {
    reloadControls()
    self.message.stringValue = message
    window?.center()
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func windowWillClose(_ notification: Notification) { recorder.finishRecording() }
  func windowDidResignKey(_ notification: Notification) { recorder.finishRecording() }

  private func reloadControls() {
    recorder.shortcut = preferences.shortcut
    iconSwitch.state = preferences.showsMenuBarIcon ? .on : .off
  }

  @objc private func visibilityChanged() {
    onVisibilityChanged?(iconSwitch.state == .on)
  }

  @objc private func startCleaning() {
    recorder.finishRecording()
    onStart?()
  }

  @objc private func quitApplication() { onQuit?() }
}

final class CleaningShortcutRecorder: NSButton {
  var shortcut = CleaningShortcut.default { didSet { if !isRecording { title = shortcut.displayName } } }
  var onCapture: ((CleaningShortcut) -> Void)?
  var onRecordingChanged: ((Bool) -> Void)?
  private var isRecording = false

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    title = shortcut.displayName
    bezelStyle = .rounded
    target = self
    action = #selector(beginRecording)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }
  override var acceptsFirstResponder: Bool { true }

  @objc private func beginRecording() {
    window?.makeFirstResponder(self)
    isRecording = true
    title = "请按下新的组合键…"
    onRecordingChanged?(true)
  }

  func finishRecording() {
    guard isRecording else { return }
    isRecording = false
    title = shortcut.displayName
    onRecordingChanged?(false)
  }

  override func resignFirstResponder() -> Bool {
    finishRecording()
    return super.resignFirstResponder()
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    guard isRecording else { return super.performKeyEquivalent(with: event) }
    capture(event)
    return true
  }

  override func keyDown(with event: NSEvent) {
    if isRecording { capture(event) } else { super.keyDown(with: event) }
  }

  private func capture(_ event: NSEvent) {
    if event.keyCode == 53 { finishRecording(); return }
    var modifiers: ShortcutModifiers = []
    if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
    if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
    if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
    if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
    let names: [UInt16: String] = [
      36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 117: "⌦",
      123: "←", 124: "→", 125: "↓", 126: "↑", 115: "Home", 119: "End", 116: "Page Up", 121: "Page Down",
      122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7",
      100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
      106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20",
    ]
    let name = names[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased() ?? ""
    let candidate = CleaningShortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers, keyName: name)
    guard candidate.isValid else { title = "请带上 ⌘、⌃ 或 ⌥"; return }
    onCapture?(candidate)
    finishRecording()
  }
}
