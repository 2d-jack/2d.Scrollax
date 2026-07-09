import Foundation
import Combine

/// Polls Accessibility trust at 1Hz so the settings UI can show/hide its permission
/// nudge as the user grants access in System Settings, without needing SwiftUI's
/// macro-based @State (unavailable without a full Xcode install).
final class AccessibilityWatcher: ObservableObject {
    @Published private(set) var isTrusted = AccessibilityPermission.isTrusted
    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.isTrusted = AccessibilityPermission.isTrusted
        }
    }

    deinit { timer?.invalidate() }
}
