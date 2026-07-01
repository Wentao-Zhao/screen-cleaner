import AppKit
import ScreenCleanerCore
import SwiftUI

final class ScreenOverlayController: ScreenOverlayPresenting {
  private var windows: [NSWindow] = []
  private var retiredWindows: [NSWindow] = []
  private var releaseRetiredWindowsWorkItem: DispatchWorkItem?

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
    releaseRetiredWindowsWorkItem?.cancel()

    let windowsToRetire = windows
    windows.removeAll()

    for window in windowsToRetire {
      window.orderOut(nil)
      window.contentView = nil
    }

    retiredWindows.append(contentsOf: windowsToRetire)

    let workItem = DispatchWorkItem { [weak self] in
      self?.retiredWindows.removeAll()
      self?.releaseRetiredWindowsWorkItem = nil
    }
    releaseRetiredWindowsWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
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
      .stationary,
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
          .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .onTapGesture {
            DispatchQueue.main.async(execute: onExit)
          }
          .accessibilityAddTraits(.isButton)

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
