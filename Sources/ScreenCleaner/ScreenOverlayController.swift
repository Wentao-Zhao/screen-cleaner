import AppKit
import ScreenCleanerCore
import SwiftUI

final class ScreenOverlayController: ScreenOverlayPresenting {
    private var windows: [NSWindow] = []

    func show(onExit: @escaping () -> Void) -> Bool {
        hide()

        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            return false
        }

        let mainScreen = NSScreen.main ?? screens[0]
        let descriptors = screens.map { screen in
            ScreenDescriptor(
                id: screenIdentifier(screen),
                isMain: screen === mainScreen
            )
        }
        let assignments = ScreenSelectionPolicy.assignRoles(to: descriptors)

        windows = zip(screens, assignments).map { screen, assignment in
            makeWindow(
                for: screen,
                isPrimary: assignment.role == .primary,
                onExit: onExit
            )
        }

        NSApp.activate(ignoringOtherApps: true)
        for (window, assignment) in zip(windows, assignments) {
            if assignment.role == .primary {
                window.makeKeyAndOrderFront(nil)
            } else {
                window.orderFrontRegardless()
            }
        }

        return windows.count == screens.count
    }

    func hide() {
        windows.forEach {
            $0.orderOut(nil)
            $0.close()
        }
        windows.removeAll()
    }

    private func makeWindow(
        for screen: NSScreen,
        isPrimary: Bool,
        onExit: @escaping () -> Void
    ) -> NSWindow {
        let window = CleaningOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.level = .screenSaver
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = false
        window.ignoresMouseEvents = !isPrimary
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]
        window.contentView = NSHostingView(
            rootView: CleaningOverlayView(
                showsExitControl: isPrimary,
                onExit: onExit
            )
        )

        return window
    }

    private func screenIdentifier(_ screen: NSScreen) -> String {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        if let number = screen.deviceDescription[key] as? NSNumber {
            return number.stringValue
        }
        return screen.localizedName
    }
}

private final class CleaningOverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}

private struct CleaningOverlayView: View {
    let showsExitControl: Bool
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if showsExitControl {
                Button(action: onExit) {
                    Text("退出清洁模式")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(nsColor: .darkGray).opacity(0.72))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.28), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                VStack {
                    Spacer()
                    Text("键盘输入已锁定")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.36))
                        .padding(.bottom, 22)
                }
            }
        }
    }
}

