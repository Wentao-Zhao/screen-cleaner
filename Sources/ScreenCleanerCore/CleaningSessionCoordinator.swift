import Combine

public enum CleaningState: Equatable {
    case idle
    case needsPermission
    case starting
    case active
    case failed(String)
}

public protocol AccessibilityPermissionProviding: AnyObject {
    var isTrusted: Bool { get }
    func requestAccess()
    func openSystemSettings()
}

public protocol KeyboardBlocking: AnyObject {
    func start() -> Bool
    func stop()
}

public protocol ScreenOverlayPresenting: AnyObject {
    func show(onExit: @escaping () -> Void) -> Bool
    func hide()
}

@MainActor
public final class CleaningSessionCoordinator: ObservableObject {
    @Published public private(set) var state: CleaningState = .idle

    private let permissionProvider: AccessibilityPermissionProviding
    private let keyboardBlocker: KeyboardBlocking
    private let overlayPresenter: ScreenOverlayPresenting

    public init(
        permissionProvider: AccessibilityPermissionProviding,
        keyboardBlocker: KeyboardBlocking,
        overlayPresenter: ScreenOverlayPresenting
    ) {
        self.permissionProvider = permissionProvider
        self.keyboardBlocker = keyboardBlocker
        self.overlayPresenter = overlayPresenter
    }

    public func start() {
        guard state != .starting, state != .active else {
            return
        }

        guard permissionProvider.isTrusted else {
            permissionProvider.requestAccess()
            state = .needsPermission
            return
        }

        state = .starting

        guard keyboardBlocker.start() else {
            state = .failed("无法锁定键盘输入")
            return
        }

        guard overlayPresenter.show(onExit: { [weak self] in
            self?.stop()
        }) else {
            keyboardBlocker.stop()
            state = .failed("无法覆盖当前显示器")
            return
        }

        state = .active
    }

    public func stop() {
        overlayPresenter.hide()
        keyboardBlocker.stop()
        state = .idle
    }

    public func openAccessibilitySettings() {
        permissionProvider.openSystemSettings()
    }

    public func refreshPermissionState() {
        if permissionProvider.isTrusted, state == .needsPermission {
            state = .idle
        }
    }
}

