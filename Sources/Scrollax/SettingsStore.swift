import Foundation
import Combine
import ServiceManagement

final class SettingsStore: ObservableObject {
    @Published var isEnabled: Bool { didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) } }
    @Published var pack: SoundPack { didSet { defaults.set(pack.rawValue, forKey: Keys.pack) } }
    @Published var volume: Double { didSet { defaults.set(volume, forKey: Keys.volume) } }
    @Published var sensitivity: Double { didSet { defaults.set(sensitivity, forKey: Keys.sensitivity) } }
    @Published var launchAtLogin: Bool { didSet { updateLoginItem() } }
    @Published var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) } }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let isEnabled = "isEnabled"
        static let pack = "pack"
        static let volume = "volume"
        static let sensitivity = "sensitivity"
        static let hapticsEnabled = "hapticsEnabled"
    }

    init() {
        defaults.register(defaults: [
            Keys.isEnabled: true,
            Keys.pack: SoundPack.softPop.rawValue,
            Keys.volume: 0.8,
            Keys.sensitivity: 1.0,
            Keys.hapticsEnabled: false,
        ])
        isEnabled = defaults.bool(forKey: Keys.isEnabled)
        pack = SoundPack(rawValue: defaults.string(forKey: Keys.pack) ?? "") ?? .softPop
        volume = defaults.double(forKey: Keys.volume)
        sensitivity = defaults.double(forKey: Keys.sensitivity)
        hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func updateLoginItem() {
        do {
            switch (launchAtLogin, SMAppService.mainApp.status) {
            case (true, .enabled):
                break
            case (true, _):
                try SMAppService.mainApp.register()
            case (false, .notRegistered):
                break
            case (false, _):
                try SMAppService.mainApp.unregister()
            }
        } catch {
            FileHandle.standardError.write("Scrollax: login item toggle failed: \(error)\n".data(using: .utf8)!)
        }
    }
}
