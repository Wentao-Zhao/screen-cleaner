import Darwin
import ScreenCleanerCore

@MainActor
@main
struct TestRunner {
  static func main() {
    let recorder = TestRecorder()

    testPermissionRequest(recorder)
    testKeyboardBlockerFailure(recorder)
    testOverlayFailureRollback(recorder)
    testSuccessfulStartAndStop(recorder)
    testOverlayExitAction(recorder)
    testScreenRoleAssignments(recorder)
    testScreenRoleFallback(recorder)
    testEmptyScreenAssignments(recorder)

    if recorder.failures.isEmpty {
      print("PASS: \(recorder.checkCount) checks")
      exit(0)
    }

    for failure in recorder.failures {
      print("FAIL: \(failure)")
    }
    print("\(recorder.failures.count) failures across \(recorder.checkCount) checks")
    exit(1)
  }

  private static func testPermissionRequest(_ recorder: TestRecorder) {
    let permission = PermissionStub(isTrusted: false)
    let blocker = KeyboardBlockerStub(startResult: true)
    let overlay = OverlayPresenterStub(showResult: true)
    let coordinator = makeCoordinator(permission, blocker, overlay)

    coordinator.start()

    recorder.expect(coordinator.state == .needsPermission, "missing permission changes state")
    recorder.expect(permission.requestCount == 1, "missing permission requests access")
    recorder.expect(blocker.startCount == 0, "missing permission does not start blocker")
    recorder.expect(overlay.showCount == 0, "missing permission does not show overlay")
  }

  private static func testKeyboardBlockerFailure(_ recorder: TestRecorder) {
    let permission = PermissionStub(isTrusted: true)
    let blocker = KeyboardBlockerStub(startResult: false)
    let overlay = OverlayPresenterStub(showResult: true)
    let coordinator = makeCoordinator(permission, blocker, overlay)

    coordinator.start()

    recorder.expect(
      coordinator.state == .failed("无法锁定键盘输入"),
      "blocker failure reports an error"
    )
    recorder.expect(blocker.startCount == 1, "trusted start attempts blocker once")
    recorder.expect(overlay.showCount == 0, "blocker failure does not show overlay")
  }

  private static func testOverlayFailureRollback(_ recorder: TestRecorder) {
    let permission = PermissionStub(isTrusted: true)
    let blocker = KeyboardBlockerStub(startResult: true)
    let overlay = OverlayPresenterStub(showResult: false)
    let coordinator = makeCoordinator(permission, blocker, overlay)

    coordinator.start()

    recorder.expect(
      coordinator.state == .failed("无法覆盖当前显示器"),
      "overlay failure reports an error"
    )
    recorder.expect(blocker.stopCount == 1, "overlay failure rolls back blocker")
    recorder.expect(overlay.showCount == 1, "overlay is attempted once")
  }

  private static func testSuccessfulStartAndStop(_ recorder: TestRecorder) {
    let permission = PermissionStub(isTrusted: true)
    let blocker = KeyboardBlockerStub(startResult: true)
    let overlay = OverlayPresenterStub(showResult: true)
    let coordinator = makeCoordinator(permission, blocker, overlay)

    coordinator.start()

    recorder.expect(coordinator.state == .active, "successful start becomes active")
    recorder.expect(blocker.startCount == 1, "successful start enables blocker")
    recorder.expect(overlay.showCount == 1, "successful start shows overlay")

    coordinator.stop()

    recorder.expect(coordinator.state == .idle, "stop returns to idle")
    recorder.expect(overlay.hideCount == 1, "stop hides overlay")
    recorder.expect(blocker.stopCount == 1, "stop disables blocker")
  }

  private static func testOverlayExitAction(_ recorder: TestRecorder) {
    let permission = PermissionStub(isTrusted: true)
    let blocker = KeyboardBlockerStub(startResult: true)
    let overlay = OverlayPresenterStub(showResult: true)
    let coordinator = makeCoordinator(permission, blocker, overlay)
    coordinator.start()

    overlay.exitAction?()

    recorder.expect(coordinator.state == .idle, "exit button stops the session")
    recorder.expect(overlay.hideCount == 1, "exit button hides overlays")
    recorder.expect(blocker.stopCount == 1, "exit button disables blocker")
  }

  private static func testScreenRoleAssignments(_ recorder: TestRecorder) {
    let screens = [
      ScreenDescriptor(id: "left", isMain: false),
      ScreenDescriptor(id: "main", isMain: true),
      ScreenDescriptor(id: "right", isMain: false),
    ]

    let result = ScreenSelectionPolicy.assignRoles(to: screens)

    recorder.expect(
      result.map(\.role) == [.secondary, .primary, .secondary],
      "main screen receives the primary role"
    )
    recorder.expect(
      result.filter { $0.role == .primary }.count == 1,
      "only one screen receives the primary role"
    )
  }

  private static func testScreenRoleFallback(_ recorder: TestRecorder) {
    let screens = [
      ScreenDescriptor(id: "first", isMain: false),
      ScreenDescriptor(id: "second", isMain: false),
    ]

    let result = ScreenSelectionPolicy.assignRoles(to: screens)

    recorder.expect(
      result.map(\.role) == [.primary, .secondary],
      "first screen is primary when no main screen exists"
    )
  }

  private static func testEmptyScreenAssignments(_ recorder: TestRecorder) {
    recorder.expect(
      ScreenSelectionPolicy.assignRoles(to: []).isEmpty,
      "empty screen input produces no assignments"
    )
  }

  private static func makeCoordinator(
    _ permission: PermissionStub,
    _ blocker: KeyboardBlockerStub,
    _ overlay: OverlayPresenterStub
  ) -> CleaningSessionCoordinator {
    CleaningSessionCoordinator(
      permissionProvider: permission,
      keyboardBlocker: blocker,
      overlayPresenter: overlay
    )
  }
}

private final class TestRecorder {
  private(set) var failures: [String] = []
  private(set) var checkCount = 0

  func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    checkCount += 1
    if !condition() {
      failures.append(message)
    }
  }
}

private final class PermissionStub: AccessibilityPermissionProviding {
  var isTrusted: Bool
  private(set) var requestCount = 0

  init(isTrusted: Bool) {
    self.isTrusted = isTrusted
  }

  func requestAccess() {
    requestCount += 1
  }

  func openSystemSettings() {}
}

private final class KeyboardBlockerStub: KeyboardBlocking {
  let startResult: Bool
  private(set) var startCount = 0
  private(set) var stopCount = 0

  init(startResult: Bool) {
    self.startResult = startResult
  }

  func start() -> Bool {
    startCount += 1
    return startResult
  }

  func stop() {
    stopCount += 1
  }
}

private final class OverlayPresenterStub: ScreenOverlayPresenting {
  let showResult: Bool
  private(set) var showCount = 0
  private(set) var hideCount = 0
  private(set) var exitAction: (() -> Void)?

  init(showResult: Bool) {
    self.showResult = showResult
  }

  func show(onExit: @escaping () -> Void) -> Bool {
    showCount += 1
    exitAction = onExit
    return showResult
  }

  func hide() {
    hideCount += 1
    exitAction = nil
  }
}
