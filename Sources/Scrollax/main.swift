import AppKit

if CommandLine.arguments.contains("--test-sounds") {
    // Headless smoke test: play each pack a few times so the audio pipeline can be
    // verified by ear without needing a trackpad or the menu bar UI.
    let engine = AudioEngine()
    var delay: TimeInterval = 0.3
    for pack in SoundPack.allCases {
        engine.pack = pack
        for i in 0..<4 {
            let intensity = Float(i) / 3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                print("playing \(pack.displayName) intensity=\(intensity)")
                engine.playTick(intensity: intensity)
            }
            delay += 0.35
        }
        delay += 0.4
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) {
        exit(0)
    }
    RunLoop.main.run(until: Date().addingTimeInterval(delay + 1.0))
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
