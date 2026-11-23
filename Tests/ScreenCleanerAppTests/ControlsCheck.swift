import AppKit
import Carbon
import ScreenCleanerCore

@main
@MainActor
enum ControlsCheck {
  static var checks = 0
  static var failures = 0

  static func main() {
    NSApplication.shared.setActivationPolicy(.accessory)
    let suite = "ScreenCleaner.ControlsTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let preferences = CleanerPreferences(defaults: defaults)
    let custom = CleaningShortcut(keyCode: 79, modifiers: [.control, .option, .command], keyName: "F18")
    preferences.shortcut = custom
    preferences.showsMenuBarIcon = false
    var starts = 0
    let controls = CleanerControlsController(preferences: preferences) { starts += 1 }
    var visible: Bool?
    controls.onIconVisibilityChanged = { visible = $0 }
    controls.start()
    check(visible == false, "configured shortcut permits a hidden status icon at launch")

    var event: EventRef?
    CreateEvent(nil, OSType(kEventClassKeyboard), UInt32(kEventHotKeyPressed), 0, 0, &event)
    var id = EventHotKeyID(signature: 0x53434C4E, id: 1)
    SetEventParameter(event!, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                      MemoryLayout<EventHotKeyID>.size, &id)
    SendEventToEventTarget(event!, GetApplicationEventTarget())
    ReleaseEvent(event!)
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    check(starts == 1, "hotkey event invokes the same cleaning callback once without polling")

    let replacement = CleaningShortcut(keyCode: 80, modifiers: [.control, .option, .command], keyName: "F19")
    check(controls.applyShortcut(replacement) == nil && preferences.shortcut == replacement,
          "custom shortcut registration persists only after success")
    let reservation = CleaningHotKeyMonitor {}
    check(reservation.register(custom) == noErr, "previous hotkey is released on replacement")
    check(controls.applyShortcut(custom) != nil, "occupied hotkey is rejected")
    check(preferences.shortcut == replacement && visible == false, "conflict preserves the working shortcut and icon choice")
    reservation.stop()

    controls.showPreferences()
    guard let window = NSApp.windows.first(where: { $0.title == "屏幕清洁 · 偏好设置" }),
          let content = window.contentView else {
      check(false, "preferences can be opened when icon is hidden")
      finish()
      return
    }
    content.layoutSubtreeIfNeeded()
    let descendants = views(content)
    let toggle = descendants.compactMap { $0 as? NSSwitch }.first!
    check(toggle.state == .off, "preferences reflect hidden icon preference")
    toggle.performClick(nil)
    check(preferences.showsMenuBarIcon && visible == true, "icon can be restored from preferences")

    let recorder = descendants.compactMap { $0 as? CleaningShortcutRecorder }.first!
    check(recorder.title == replacement.displayName, "recorder displays saved shortcut")
    recorder.performClick(nil)
    check(reservation.register(replacement) == noErr, "recording temporarily releases the current shortcut")
    reservation.stop()
    let escape = key(code: 53, character: "\u{1b}", modifiers: [], window: window)
    recorder.keyDown(with: escape)
    check(preferences.shortcut == replacement && recorder.title == replacement.displayName, "Escape cancels recording")
    check(reservation.register(replacement) != noErr, "cancel restores the previous global shortcut")
    recorder.performClick(nil)
    let capture = key(code: 79, character: "", modifiers: [.control, .option, .command], window: window)
    check(recorder.performKeyEquivalent(with: capture), "recording captures Command combinations")
    check(preferences.shortcut.keyCode == 79, "captured combination is registered and persisted")
    window.close()
    check(starts == 1, "editing preferences never starts cleaning")
    controls.stop()
    check(reservation.register(preferences.shortcut) == noErr, "shutdown unregisters shortcut")
    reservation.stop()
    preferences.shortcut = custom
    preferences.showsMenuBarIcon = false
    check(reservation.register(custom) == noErr, "reserve a shortcut before testing startup conflict")
    let recovery = CleanerControlsController(preferences: preferences) {}
    recovery.start()
    check(recovery.showsIcon && !preferences.showsMenuBarIcon, "startup conflict forces an icon without overwriting user choice")
    check(NSApp.windows.contains(where: { $0.title == "屏幕清洁 · 偏好设置" && $0.isVisible }),
          "startup conflict opens recovery settings")
    recovery.stop()
    reservation.stop()
    finish()
  }

  private static func views(_ root: NSView) -> [NSView] { [root] + root.subviews.flatMap(views) }
  private static func check(_ value: Bool, _ message: String) {
    checks += 1
    if !value { failures += 1; print("FAIL: \(message)") }
  }
  private static func finish() {
    print(failures == 0 ? "PASS: \(checks) native controls checks" : "FAIL: \(failures)/\(checks)")
    exit(failures == 0 ? 0 : 1)
  }
  private static func key(code: UInt16, character: String, modifiers: NSEvent.ModifierFlags, window: NSWindow) -> NSEvent {
    NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0,
      windowNumber: window.windowNumber, context: nil, characters: character,
      charactersIgnoringModifiers: character, isARepeat: false, keyCode: code)!
  }
}
