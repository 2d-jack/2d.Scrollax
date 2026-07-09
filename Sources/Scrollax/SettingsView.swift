import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var watcher: AccessibilityWatcher
    let audioEngine: AudioEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if !watcher.isTrusted {
                accessibilityWarning
            }

            packPicker
            labeledSlider(title: "Volume", value: $settings.volume, range: 0...1)
            labeledSlider(title: "Sensitivity", value: $settings.sensitivity, range: 0.3...3)

            Toggle("Haptic Feedback", isOn: $settings.hapticsEnabled)
                .toggleStyle(.checkbox)
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                .toggleStyle(.checkbox)

            Divider()

            Button("Quit 2d.Scrollax") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 300)
    }

    private var header: some View {
        HStack {
            Text("2d.Scrollax")
                .font(.headline)
            Spacer()
            Toggle("", isOn: $settings.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }

    private var packPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sound").font(.subheadline).foregroundStyle(.secondary)
            HStack {
                Picker("", selection: $settings.pack) {
                    ForEach(SoundPack.allCases) { pack in
                        Text(pack.displayName).tag(pack)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                Button {
                    audioEngine.playPreview()
                } label: {
                    Image(systemName: "play.circle.fill")
                }
                .buttonStyle(.plain)
                .help("Preview this sound")
            }
            Text(settings.pack.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func labeledSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Slider(value: value, in: range)
        }
    }

    private var accessibilityWarning: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Needs Accessibility access to hear scrolling while other apps are in front.")
                .font(.caption)
            Button("Grant Access…") {
                AccessibilityPermission.requestIfNeeded()
                AccessibilityPermission.openSystemSettings()
            }
            .controlSize(.small)
        }
        .padding(8)
        .background(Color.yellow.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
