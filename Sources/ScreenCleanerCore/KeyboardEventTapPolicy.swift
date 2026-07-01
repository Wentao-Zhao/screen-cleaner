import CoreGraphics

public enum CapturedKeyboardEventType: Equatable {
  case keyDown
  case keyUp
  case flagsChanged
  case systemDefined

  var cgEventRawValue: Int {
    switch self {
    case .keyDown:
      return Int(CGEventType.keyDown.rawValue)
    case .keyUp:
      return Int(CGEventType.keyUp.rawValue)
    case .flagsChanged:
      return Int(CGEventType.flagsChanged.rawValue)
    case .systemDefined:
      // NX_SYSDEFINED / NSEventTypeSystemDefined. CoreGraphics has no Swift case in this SDK.
      return 14
    }
  }
}

public enum KeyboardEventTapPolicy {
  public static let capturedEventTypes: [CapturedKeyboardEventType] = [
    .keyDown,
    .keyUp,
    .flagsChanged,
    .systemDefined,
  ]

  public static var eventMask: CGEventMask {
    capturedEventTypes.reduce(CGEventMask(0)) { mask, eventType in
      mask | eventMask(for: eventType)
    }
  }

  public static func eventMaskContains(_ eventType: CapturedKeyboardEventType) -> Bool {
    eventMask & eventMask(for: eventType) != 0
  }

  private static func eventMask(for eventType: CapturedKeyboardEventType) -> CGEventMask {
    CGEventMask(1) << eventType.cgEventRawValue
  }
}
