public struct ScreenDescriptor: Equatable {
    public let id: String
    public let isMain: Bool

    public init(id: String, isMain: Bool) {
        self.id = id
        self.isMain = isMain
    }
}

public enum ScreenRole: Equatable {
    case primary
    case secondary
}

public struct ScreenAssignment: Equatable {
    public let screen: ScreenDescriptor
    public let role: ScreenRole
}

public enum ScreenSelectionPolicy {
    public static func assignRoles(to screens: [ScreenDescriptor]) -> [ScreenAssignment] {
        guard let primaryIndex = screens.firstIndex(where: \.isMain) ?? screens.indices.first else {
            return []
        }

        return screens.enumerated().map { index, screen in
            ScreenAssignment(
                screen: screen,
                role: index == primaryIndex ? .primary : .secondary
            )
        }
    }
}
