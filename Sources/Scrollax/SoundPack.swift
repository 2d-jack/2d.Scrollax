import Foundation

enum SoundPack: String, CaseIterable, Identifiable {
    case rubberSnap
    case glueyGrip
    case mechanicalClick
    case softPop

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rubberSnap: return "Rubber Snap"
        case .glueyGrip: return "Gluey Grip"
        case .mechanicalClick: return "Mechanical Click"
        case .softPop: return "Soft Pop"
        }
    }

    var subtitle: String {
        switch self {
        case .rubberSnap: return "Snappy, twangy tick"
        case .glueyGrip: return "Slow, rubbery drag"
        case .mechanicalClick: return "Crisp keyboard-like click"
        case .softPop: return "Muted, soft thock"
        }
    }

    func render(seed: inout UInt64) -> [Float] {
        switch self {
        case .rubberSnap: return Synth.rubberSnap(seed: &seed)
        case .glueyGrip: return Synth.glueyGrip(seed: &seed)
        case .mechanicalClick: return Synth.mechanicalClick(seed: &seed)
        case .softPop: return Synth.softPop(seed: &seed)
        }
    }

    /// Approximate pixels-of-scroll per audible tick, before the user's sensitivity
    /// multiplier is applied. Denser packs (clicks) want smaller ticks than long,
    /// slow-decaying ones (gluey), otherwise they either smear together or feel sparse.
    var baseTickDistance: Double {
        switch self {
        case .rubberSnap: return 14
        case .glueyGrip: return 22
        case .mechanicalClick: return 9
        case .softPop: return 16
        }
    }
}
