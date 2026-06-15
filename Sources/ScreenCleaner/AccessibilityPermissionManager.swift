import AppKit
import ApplicationServices
import ScreenCleanerCore

final class AccessibilityPermissionManager: AccessibilityPermissionProviding {
  var isTrusted: Bool {
    AXIsProcessTrusted()
  }

  func requestAccess() {
    let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options = [promptKey: true] as CFDictionary
    AXIsProcessTrustedWithOptions(options)
  }

  func openSystemSettings() {
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
      )
    else {
      return
    }

    NSWorkspace.shared.open(url)
  }
}
