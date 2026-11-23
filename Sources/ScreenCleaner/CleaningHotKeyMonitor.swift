import AppKit
import Carbon
import ScreenCleanerCore

@MainActor
final class CleaningHotKeyMonitor {
  private var key: EventHotKeyRef?
  private var handler: EventHandlerRef?
  private var shortcut: CleaningShortcut?
  private let callback: HotKeyCallback
  private static let signature: OSType = 0x53434C4E

  init(onTrigger: @escaping () -> Void) {
    callback = HotKeyCallback { Task { @MainActor in onTrigger() } }
  }

  // Register the replacement first so a conflict never discards the working shortcut.
  func register(_ shortcut: CleaningShortcut) -> OSStatus {
    guard shortcut.isValid else { return OSStatus(paramErr) }
    if self.shortcut == shortcut, key != nil { return noErr }
    if handler == nil {
      var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
      let result = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
        guard let event, let context else { return OSStatus(eventNotHandledErr) }
        var id = EventHotKeyID()
        let result = GetEventParameter(event, EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
        guard result == noErr, id.signature == 0x53434C4E, id.id == 1 else {
          return OSStatus(eventNotHandledErr)
        }
        Unmanaged<HotKeyCallback>.fromOpaque(context).takeUnretainedValue().trigger()
        return noErr
      }, 1, &type, Unmanaged.passUnretained(callback).toOpaque(), &handler)
      guard result == noErr else { return result }
    }
    var flags: UInt32 = 0
    if shortcut.modifiers.contains(.control) { flags |= UInt32(controlKey) }
    if shortcut.modifiers.contains(.option) { flags |= UInt32(optionKey) }
    if shortcut.modifiers.contains(.shift) { flags |= UInt32(shiftKey) }
    if shortcut.modifiers.contains(.command) { flags |= UInt32(cmdKey) }
    var replacement: EventHotKeyRef?
    let result = RegisterEventHotKey(shortcut.keyCode, flags,
      EventHotKeyID(signature: Self.signature, id: 1), GetApplicationEventTarget(), 0, &replacement)
    guard result == noErr else { return result }
    if let key { UnregisterEventHotKey(key) }
    key = replacement
    self.shortcut = shortcut
    return noErr
  }

  func stop() {
    if let key { UnregisterEventHotKey(key) }
    if let handler { RemoveEventHandler(handler) }
    key = nil
    handler = nil
    shortcut = nil
  }
}

private final class HotKeyCallback {
  let trigger: () -> Void
  init(trigger: @escaping () -> Void) { self.trigger = trigger }
}
