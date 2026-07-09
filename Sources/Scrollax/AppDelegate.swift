import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore()
    private let audioEngine = AudioEngine()
    private let hapticEngine = HapticEngine()
    private let scrollMonitor = ScrollMonitor()
    private var statusItemController: StatusItemController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        settings.$pack
            .sink { [weak self] pack in
                self?.audioEngine.pack = pack
                self?.scrollMonitor.tickDistance = pack.baseTickDistance
            }
            .store(in: &cancellables)

        settings.$volume
            .sink { [weak self] volume in self?.audioEngine.volume = Float(volume) }
            .store(in: &cancellables)

        settings.$isEnabled
            .sink { [weak self] enabled in self?.scrollMonitor.isEnabled = enabled }
            .store(in: &cancellables)

        settings.$sensitivity
            .sink { [weak self] sensitivity in self?.scrollMonitor.sensitivity = sensitivity }
            .store(in: &cancellables)

        settings.$hapticsEnabled
            .sink { [weak self] enabled in self?.hapticEngine.isEnabled = enabled }
            .store(in: &cancellables)

        scrollMonitor.onTick = { [weak self] intensity in
            self?.audioEngine.playTick(intensity: intensity)
            self?.hapticEngine.fire(intensity: intensity)
        }
        scrollMonitor.start()

        statusItemController = StatusItemController(settings: settings, audioEngine: audioEngine)

        if !AccessibilityPermission.isTrusted {
            AccessibilityPermission.requestIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        scrollMonitor.stop()
    }
}
