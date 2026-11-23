import AppKit
import ScreenCleanerCore
import ServiceManagement

@MainActor
@main
enum ScreenCleanerMain {
  private static let appDelegate = AppDelegate()

  static func main() {
    let application = NSApplication.shared
    application.delegate = appDelegate
    application.setActivationPolicy(.accessory)
    application.run()
  }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
  private let coordinator: CleaningSessionCoordinator
  private var statusItemController: StatusItemController?
  private var controlsController: CleanerControlsController?
  private var lifecycleSmokeWindow: NSWindow?

  override init() {
    coordinator = CleaningSessionCoordinator(
      permissionProvider: AccessibilityPermissionManager(),
      keyboardBlocker: KeyboardEventBlocker(),
      overlayPresenter: ScreenOverlayController()
    )
    super.init()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    if ProcessInfo.processInfo.environment["SCREEN_CLEANER_LIFECYCLE_SMOKE_TEST"] == "1" {
      runLifecycleSmokeTest()
      return
    }

    let controls = CleanerControlsController { [weak self] in self?.coordinator.start() }
    let status = StatusItemController(coordinator: coordinator) { [weak controls] in
      controls?.showPreferences()
    }
    controls.onIconVisibilityChanged = { [weak status] visible in status?.setVisible(visible) }
    controlsController = controls
    statusItemController = status
    controls.start()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if coordinator.state != .active, coordinator.state != .starting {
      controlsController?.showPreferences()
    }
    return false
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    ApplicationLifecyclePolicy.shouldTerminateAfterLastWindowClosed
  }

  func applicationWillTerminate(_ notification: Notification) {
    controlsController?.stop()
    coordinator.stop()
  }

  private func runLifecycleSmokeTest() {
    let window = NSWindow(
      contentRect: NSRect(x: -10_000, y: -10_000, width: 1, height: 1),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.alphaValue = 0
    lifecycleSmokeWindow = window
    window.orderFront(nil)
    window.orderOut(nil)
    window.contentView = nil

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.lifecycleSmokeWindow = nil

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        print("PASS: application survived overlay teardown")
        NSApp.terminate(nil)
      }
    }
  }
}

@MainActor
private final class StatusItemController: NSObject {
  private let coordinator: CleaningSessionCoordinator
  private let statusItem: NSStatusItem
  private let launchAtLoginController = LaunchAtLoginController()
  private let onShowPreferences: () -> Void

  init(coordinator: CleaningSessionCoordinator, onShowPreferences: @escaping () -> Void) {
    self.coordinator = coordinator
    self.onShowPreferences = onShowPreferences
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    super.init()
    configureStatusItem()
  }

  func setVisible(_ visible: Bool) {
    statusItem.isVisible = visible
  }

  private func configureStatusItem() {
    guard let button = statusItem.button else {
      return
    }

    button.image = MenuBarIcon.image
    button.imagePosition = .imageOnly
    button.toolTip = "右键打开屏幕清洁菜单"
    button.target = self
    button.action = #selector(statusItemClicked(_:))
    button.sendAction(on: [.rightMouseUp])
  }

  @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
    let event: StatusItemMouseEvent =
      NSApp.currentEvent?.type == .rightMouseUp ? .rightMouseUp : .leftMouseUp

    switch StatusItemInteractionPolicy.action(for: event) {
    case .ignore:
      return
    case .showApplicationMenu:
      showApplicationMenu(relativeTo: sender)
    }
  }

  private func showApplicationMenu(relativeTo button: NSStatusBarButton) {
    coordinator.refreshPermissionState()
    let menu = makeApplicationMenu()
    menu.popUp(
      positioning: nil,
      at: NSPoint(x: 0, y: button.bounds.minY - 4),
      in: button
    )
  }

  private func makeApplicationMenu() -> NSMenu {
    let menu = NSMenu()

    for definition in StatusMenuPolicy.items(
      launchAtLoginEnabled: launchAtLoginController.isEnabled
    ) {
      switch definition {
      case .startCleaning:
        let item = NSMenuItem(
          title: "开始屏幕清洁",
          action: #selector(startCleaning),
          keyEquivalent: ""
        )
        item.target = self
        item.isEnabled = coordinator.state != .starting && coordinator.state != .active
        menu.addItem(item)

      case .launchAtLogin(let isEnabled):
        let item = NSMenuItem()
        item.view = LaunchAtLoginMenuItemView(
          isEnabled: isEnabled,
          target: self,
          action: #selector(launchAtLoginChanged(_:))
        )
        menu.addItem(item)

      case .preferences:
        let item = NSMenuItem(title: "偏好设置…", action: #selector(showPreferences), keyEquivalent: ",")
        item.target = self
        menu.addItem(item)

      case .quitApplication:
        menu.addItem(.separator())
        let item = NSMenuItem(
          title: "退出 App",
          action: #selector(quitApplication),
          keyEquivalent: "q"
        )
        item.target = self
        menu.addItem(item)
      }
    }

    return menu
  }

  @objc private func startCleaning() {
    coordinator.start()
  }

  @objc private func showPreferences() { onShowPreferences() }

  @objc private func launchAtLoginChanged(_ sender: NSSwitch) {
    do {
      try launchAtLoginController.setEnabled(sender.state == .on)
      sender.state = launchAtLoginController.isEnabled ? .on : .off
    } catch {
      sender.state = launchAtLoginController.isEnabled ? .on : .off
      presentLaunchAtLoginError(error)
    }
  }

  @objc private func quitApplication() {
    coordinator.stop()
    NSApp.terminate(nil)
  }

  private func presentLaunchAtLoginError(_ error: Error) {
    let alert = NSAlert()
    alert.messageText = "无法修改开机自启"
    alert.informativeText = error.localizedDescription
    alert.alertStyle = .warning
    alert.runModal()
  }
}

@MainActor
private final class LaunchAtLoginController {
  private let service = SMAppService.mainApp

  var isEnabled: Bool {
    switch service.status {
    case .enabled, .requiresApproval:
      return true
    case .notRegistered, .notFound:
      return false
    @unknown default:
      return LaunchAtLoginPolicy.defaultEnabled
    }
  }

  func setEnabled(_ enabled: Bool) throws {
    if enabled {
      try service.register()
    } else {
      try service.unregister()
    }
  }
}

private final class LaunchAtLoginMenuItemView: NSView {
  init(isEnabled: Bool, target: AnyObject, action: Selector) {
    super.init(frame: NSRect(x: 0, y: 0, width: 230, height: 32))

    let label = NSTextField(labelWithString: "开机自启")
    label.translatesAutoresizingMaskIntoConstraints = false

    let toggle = NSSwitch()
    toggle.translatesAutoresizingMaskIntoConstraints = false
    toggle.controlSize = .small
    toggle.state = isEnabled ? .on : .off
    toggle.target = target
    toggle.action = action

    addSubview(label)
    addSubview(toggle)

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
      label.centerYAnchor.constraint(equalTo: centerYAnchor),
      toggle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      toggle.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }
}
