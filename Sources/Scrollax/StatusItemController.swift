import AppKit
import SwiftUI
import Combine

final class StatusItemController: NSObject, NSPopoverDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private let watcher = AccessibilityWatcher()
    private var cancellable: AnyCancellable?

    init(settings: SettingsStore, audioEngine: AudioEngine) {
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "2d.Scrollax")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover.behavior = .transient
        popover.delegate = self
        popover.contentSize = NSSize(width: 300, height: 380)
        popover.contentViewController = NSHostingController(
            rootView: SettingsView(settings: settings, watcher: watcher, audioEngine: audioEngine)
        )

        cancellable = settings.$isEnabled.sink { [weak self] enabled in
            self?.updateIcon(enabled: enabled)
        }
    }

    private func updateIcon(enabled: Bool) {
        let symbolName = enabled ? "waveform" : "waveform.slash"
        statusItem.button?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "2d.Scrollax")
        statusItem.button?.image?.isTemplate = true
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
