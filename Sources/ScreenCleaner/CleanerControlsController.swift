import AppKit
import ScreenCleanerCore

@MainActor
final class CleanerControlsController {
  private let preferences: CleanerPreferences
  private let onStart: () -> Void
  private var shortcutRegistered = false
  private var preferencesController: CleanerPreferencesWindowController?
  var onIconVisibilityChanged: ((Bool) -> Void)?
  private lazy var hotKey = CleaningHotKeyMonitor { [weak self] in self?.onStart() }

  init(preferences: CleanerPreferences = CleanerPreferences(), onStart: @escaping () -> Void) {
    self.preferences = preferences
    self.onStart = onStart
  }

  var showsIcon: Bool {
    CleanerEntryPolicy.showsIcon(preferred: preferences.showsMenuBarIcon, shortcutRegistered: shortcutRegistered)
  }

  func start() {
    shortcutRegistered = hotKey.register(preferences.shortcut) == 0
    onIconVisibilityChanged?(showsIcon)
    if !shortcutRegistered {
      showPreferences(message: "启动快捷键被占用或无法注册，请重新录入。状态栏图标暂时保留。")
    }
  }

  func stop() { hotKey.stop() }

  func applyShortcut(_ shortcut: CleaningShortcut) -> String? {
    let result = hotKey.register(shortcut)
    guard result == 0 else {
      shortcutRegistered = hotKey.register(preferences.shortcut) == 0
      onIconVisibilityChanged?(showsIcon)
      return "快捷键无法注册（错误码 \(result)），请换一个组合键。"
    }
    preferences.shortcut = shortcut
    shortcutRegistered = true
    onIconVisibilityChanged?(showsIcon)
    return nil
  }

  func showPreferences(message: String = "") {
    if preferencesController == nil {
      let controller = CleanerPreferencesWindowController(preferences: preferences)
      controller.onShortcutChanged = { [weak self] in self?.applyShortcut($0) }
      controller.onVisibilityChanged = { [weak self] visible in
        guard let self else { return }
        self.preferences.showsMenuBarIcon = visible
        self.onIconVisibilityChanged?(self.showsIcon)
      }
      controller.onRecordingChanged = { [weak self] recording in
        guard let self else { return }
        if recording {
          self.hotKey.stop()
        } else {
          self.shortcutRegistered = self.hotKey.register(self.preferences.shortcut) == 0
          self.onIconVisibilityChanged?(self.showsIcon)
        }
      }
      controller.onStart = onStart
      controller.onQuit = { NSApp.terminate(nil) }
      preferencesController = controller
    }
    preferencesController?.show(message: message)
  }
}
