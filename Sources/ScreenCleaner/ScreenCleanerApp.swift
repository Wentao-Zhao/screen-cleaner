import AppKit
import ScreenCleanerCore
import SwiftUI

@main
enum ScreenCleanerMain {
  static func main() {
    let application = NSApplication.shared
    let delegate = AppDelegate()

    application.delegate = delegate
    application.setActivationPolicy(.accessory)
    application.run()
  }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
  private let coordinator: CleaningSessionCoordinator
  private var statusItemController: StatusItemController?

  override init() {
    coordinator = CleaningSessionCoordinator(
      permissionProvider: AccessibilityPermissionManager(),
      keyboardBlocker: KeyboardEventBlocker(),
      overlayPresenter: ScreenOverlayController()
    )
    super.init()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    statusItemController = StatusItemController(coordinator: coordinator)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    ApplicationLifecyclePolicy.shouldTerminateAfterLastWindowClosed
  }

  func applicationWillTerminate(_ notification: Notification) {
    coordinator.stop()
  }
}

@MainActor
private final class StatusItemController: NSObject {
  private let coordinator: CleaningSessionCoordinator
  private let statusItem: NSStatusItem
  private let popover: NSPopover

  init(coordinator: CleaningSessionCoordinator) {
    self.coordinator = coordinator
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    popover = NSPopover()
    super.init()

    configureStatusItem()
    configurePopover()
  }

  private func configureStatusItem() {
    guard let button = statusItem.button else {
      return
    }

    button.image = MenuBarIcon.image
    button.imagePosition = .imageOnly
    button.toolTip = "屏幕清洁"
    button.target = self
    button.action = #selector(statusItemClicked(_:))
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
  }

  private func configurePopover() {
    popover.behavior = .transient
    popover.animates = true
    popover.contentSize = NSSize(width: 300, height: 150)
    popover.contentViewController = NSHostingController(
      rootView: MenuBarContent(coordinator: coordinator)
    )
  }

  @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
    let event: StatusItemMouseEvent =
      NSApp.currentEvent?.type == .rightMouseUp ? .rightMouseUp : .leftMouseUp

    switch StatusItemInteractionPolicy.action(for: event) {
    case .togglePopover:
      togglePopover(relativeTo: sender)
    case .showApplicationMenu:
      showApplicationMenu()
    }
  }

  private func togglePopover(relativeTo button: NSStatusBarButton) {
    if popover.isShown {
      popover.performClose(nil)
      return
    }

    coordinator.refreshPermissionState()
    popover.show(
      relativeTo: button.bounds,
      of: button,
      preferredEdge: .minY
    )
    NSApp.activate(ignoringOtherApps: true)
  }

  private func showApplicationMenu() {
    popover.performClose(nil)

    let menu = NSMenu()
    let quitItem = NSMenuItem(
      title: "退出 App",
      action: #selector(quitApplication),
      keyEquivalent: "q"
    )
    quitItem.target = self
    menu.addItem(quitItem)

    statusItem.menu = menu
    statusItem.button?.performClick(nil)
    statusItem.menu = nil
  }

  @objc private func quitApplication() {
    coordinator.stop()
    NSApp.terminate(nil)
  }
}

private struct MenuBarContent: View {
  @ObservedObject var coordinator: CleaningSessionCoordinator

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text("屏幕清洁")
          .font(.headline)

        Text("锁定键盘输入，并将所有显示器变为黑色。")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      statusContent

      Button(startButtonTitle) {
        coordinator.start()
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .disabled(coordinator.state == .starting || coordinator.state == .active)
    }
    .padding(16)
    .frame(width: 300)
    .task(id: coordinator.state) {
      guard coordinator.state == .needsPermission else {
        return
      }

      while !Task.isCancelled, coordinator.state == .needsPermission {
        try? await Task.sleep(for: .milliseconds(500))
        coordinator.refreshPermissionState()
      }
    }
  }

  @ViewBuilder
  private var statusContent: some View {
    switch coordinator.state {
    case .idle:
      EmptyView()

    case .needsPermission:
      VStack(alignment: .leading, spacing: 8) {
        Text("需要辅助功能权限才能阻止键盘输入。")
          .font(.caption)
          .foregroundStyle(.orange)

        Text("如果已经开启仍未生效，请先删除设置中的旧条目，再重新授权当前版本。")
          .font(.caption2)
          .foregroundStyle(.secondary)

        Button("打开辅助功能设置") {
          coordinator.openAccessibilitySettings()
        }
      }

    case .starting:
      HStack(spacing: 8) {
        ProgressView()
          .controlSize(.small)
        Text("正在进入清洁模式…")
          .font(.caption)
      }

    case .active:
      Text("清洁模式已开启")
        .font(.caption)
        .foregroundStyle(.green)

    case .failed(let message):
      Text(message)
        .font(.caption)
        .foregroundStyle(.red)
    }
  }

  private var startButtonTitle: String {
    switch coordinator.state {
    case .needsPermission:
      return "重新检查并开始"
    default:
      return "开始屏幕清洁"
    }
  }
}
