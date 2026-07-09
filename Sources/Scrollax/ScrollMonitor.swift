import AppKit

/// Watches trackpad scroll events system-wide and turns raw scroll distance into
/// quantized "ticks" — every N points of scroll fires one tick, carrying an intensity
/// derived from how fast the user is scrolling right now.
final class ScrollMonitor {
    var isEnabled = true
    var sensitivity: Double = 1.0
    var tickDistance: Double = 14
    var onTick: ((Float) -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var accumulated: Double = 0
    private var lastEventTime: CFAbsoluteTime = 0
    private var smoothedVelocity: Double = 0

    func start() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor { NSEvent.removeMonitor(m) }
        globalMonitor = nil
        localMonitor = nil
        accumulated = 0
    }

    private func handle(_ event: NSEvent) {
        guard isEnabled, event.hasPreciseScrollingDeltas else { return }
        let delta = Double(event.scrollingDeltaY)
        guard delta != 0 else { return }

        let now = CFAbsoluteTimeGetCurrent()
        let dt = now - lastEventTime
        lastEventTime = now
        if dt > 0, dt < 0.5 {
            let instantVelocity = abs(delta) / dt
            smoothedVelocity = smoothedVelocity * 0.7 + instantVelocity * 0.3
        } else {
            smoothedVelocity = abs(delta) * 60
        }

        accumulated += abs(delta)
        let distance = max(4, tickDistance / max(sensitivity, 0.1))
        while accumulated >= distance {
            accumulated -= distance
            onTick?(velocityToIntensity(smoothedVelocity))
        }
    }

    private func velocityToIntensity(_ pointsPerSecond: Double) -> Float {
        let normalized = min(1, pointsPerSecond / 3500)
        return Float(pow(normalized, 0.6))
    }
}
