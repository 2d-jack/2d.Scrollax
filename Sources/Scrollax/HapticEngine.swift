import AppKit

/// Fires a physical trackpad tap (Taptic Engine) alongside scroll ticks. Throttled
/// because the Taptic Engine can't usefully distinguish pulses much faster than this,
/// and firing on every single tick during a fast scroll would just feel like a buzz.
final class HapticEngine {
    var isEnabled = false

    private let performer = NSHapticFeedbackManager.defaultPerformer
    private var lastFireTime: CFAbsoluteTime = 0
    private let minInterval: CFAbsoluteTime = 0.035

    func fire(intensity: Float) {
        guard isEnabled else { return }
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastFireTime >= minInterval else { return }
        lastFireTime = now
        let pattern: NSHapticFeedbackManager.FeedbackPattern = intensity > 0.55 ? .levelChange : .generic
        performer.perform(pattern, performanceTime: .now)
    }
}
