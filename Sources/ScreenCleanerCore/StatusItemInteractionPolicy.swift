public enum StatusItemMouseEvent {
  case leftMouseUp
  case rightMouseUp
}

public enum StatusItemAction: Equatable {
  case ignore
  case showApplicationMenu
}

public enum StatusItemInteractionPolicy {
  public static func action(for event: StatusItemMouseEvent) -> StatusItemAction {
    switch event {
    case .leftMouseUp:
      return .ignore
    case .rightMouseUp:
      return .showApplicationMenu
    }
  }
}

public enum StatusMenuItemDefinition: Equatable {
  case startCleaning
  case preferences
  case launchAtLogin(isEnabled: Bool)
  case quitApplication
}

public enum StatusMenuPolicy {
  public static func items(launchAtLoginEnabled: Bool) -> [StatusMenuItemDefinition] {
    [
      .startCleaning,
      .preferences,
      .launchAtLogin(isEnabled: launchAtLoginEnabled),
      .quitApplication,
    ]
  }
}

public enum LaunchAtLoginPolicy {
  public static let defaultEnabled = false
}
