import ApplicationServices
import CoreGraphics
import ScreenCleanerCore

final class KeyboardEventBlocker: KeyboardBlocking {
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?

  func start() -> Bool {
    if eventTap != nil {
      return true
    }

    let eventMask =
      (CGEventMask(1) << CGEventType.keyDown.rawValue)
      | (CGEventMask(1) << CGEventType.keyUp.rawValue)
      | (CGEventMask(1) << CGEventType.flagsChanged.rawValue)

    let userInfo = Unmanaged.passUnretained(self).toOpaque()
    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: keyboardEventCallback,
        userInfo: userInfo
      )
    else {
      return false
    }

    guard
      let runLoopSource = CFMachPortCreateRunLoopSource(
        kCFAllocatorDefault,
        eventTap,
        0
      )
    else {
      CFMachPortInvalidate(eventTap)
      return false
    }

    self.eventTap = eventTap
    self.runLoopSource = runLoopSource

    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
    return true
  }

  func stop() {
    if let runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    }

    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      CFMachPortInvalidate(eventTap)
    }

    runLoopSource = nil
    eventTap = nil
  }

  fileprivate func reenableAfterSystemDisable() {
    guard let eventTap else {
      return
    }

    CGEvent.tapEnable(tap: eventTap, enable: true)
  }

  deinit {
    stop()
  }
}

private let keyboardEventCallback: CGEventTapCallBack = {
  _,
  type,
  event,
  userInfo in

  guard let userInfo else {
    return Unmanaged.passUnretained(event)
  }

  let blocker = Unmanaged<KeyboardEventBlocker>
    .fromOpaque(userInfo)
    .takeUnretainedValue()

  if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
    blocker.reenableAfterSystemDisable()
    return Unmanaged.passUnretained(event)
  }

  return nil
}
