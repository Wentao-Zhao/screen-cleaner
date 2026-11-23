import Foundation

public struct ShortcutModifiers: OptionSet, Codable, Equatable, Sendable {
  public let rawValue: UInt32
  public init(rawValue: UInt32) { self.rawValue = rawValue }
  public static let control = Self(rawValue: 1)
  public static let option = Self(rawValue: 2)
  public static let shift = Self(rawValue: 4)
  public static let command = Self(rawValue: 8)
}

public struct CleaningShortcut: Codable, Equatable, Sendable {
  public let keyCode: UInt32
  public let modifiers: ShortcutModifiers
  public let keyName: String

  public init(keyCode: UInt32, modifiers: ShortcutModifiers, keyName: String) {
    self.keyCode = keyCode
    self.modifiers = modifiers
    self.keyName = keyName
  }

  public static let `default` = Self(keyCode: 8, modifiers: [.control, .option, .command], keyName: "C")

  public var isValid: Bool {
    keyCode < 128 && !(53...63).contains(keyCode)
      && !modifiers.intersection([.command, .control, .option]).isEmpty
      && modifiers.rawValue & ~UInt32(15) == 0 && !keyName.isEmpty
  }

  public var displayName: String {
    [(ShortcutModifiers.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
      .filter { modifiers.contains($0.0) }.map(\.1).joined() + keyName
  }
}

public final class CleanerPreferences {
  private let defaults: UserDefaults
  public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

  public var shortcut: CleaningShortcut {
    get {
      guard let data = defaults.data(forKey: "cleaningShortcut"),
            let value = try? JSONDecoder().decode(CleaningShortcut.self, from: data),
            value.isValid else { return .default }
      return value
    }
    set {
      guard newValue.isValid, let data = try? JSONEncoder().encode(newValue) else { return }
      defaults.set(data, forKey: "cleaningShortcut")
    }
  }

  public var showsMenuBarIcon: Bool {
    get { defaults.object(forKey: "showsMenuBarIcon") as? Bool ?? true }
    set { defaults.set(newValue, forKey: "showsMenuBarIcon") }
  }
}

public enum CleanerEntryPolicy {
  public static func showsIcon(preferred: Bool, shortcutRegistered: Bool) -> Bool {
    preferred || !shortcutRegistered
  }
}
