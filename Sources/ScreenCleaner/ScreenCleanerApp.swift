import AppKit
import ScreenCleanerCore
import SwiftUI

@main
struct ScreenCleanerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var coordinator: CleaningSessionCoordinator

    init() {
        let permissionManager = AccessibilityPermissionManager()
        let keyboardBlocker = KeyboardEventBlocker()
        let overlayController = ScreenOverlayController()

        _coordinator = StateObject(
            wrappedValue: CleaningSessionCoordinator(
                permissionProvider: permissionManager,
                keyboardBlocker: keyboardBlocker,
                overlayPresenter: overlayController
            )
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(coordinator: coordinator)
        } label: {
            Image(nsImage: MenuBarIcon.image)
        }
        .menuBarExtraStyle(.window)
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
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

            Divider()

            HStack {
                Button("退出应用") {
                    coordinator.stop()
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button(startButtonTitle) {
                    coordinator.start()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(coordinator.state == .starting || coordinator.state == .active)
            }
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            coordinator.refreshPermissionState()
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

        case let .failed(message):
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
