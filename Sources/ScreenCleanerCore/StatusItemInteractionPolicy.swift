public enum StatusItemMouseEvent {
  case leftMouseUp
  case rightMouseUp
}

public enum StatusItemAction: Equatable {
  case togglePopover
  case showApplicationMenu
}

public enum StatusItemInteractionPolicy {
  public static func action(for event: StatusItemMouseEvent) -> StatusItemAction {
    switch event {
    case .leftMouseUp:
      return .togglePopover
    case .rightMouseUp:
      return .showApplicationMenu
    }
  }
}
