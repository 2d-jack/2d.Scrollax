import Foundation

enum SoundPack: String, CaseIterable, Identifiable {
    case glueyGrip
    case mechanicalClick
    case softPop
    case bubblePop
    case velvetTap
    case waterDrop

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .glueyGrip: return "Gluey Grip"
        case .mechanicalClick: return "Mechanical Click"
        case .softPop: return "Soft Pop"
        case .bubblePop: return "Bubble Pop"
        case .velvetTap: return "Velvet Tap"
        case .waterDrop: return "Water Drop"
        }
    }

    var subtitle: String {
        switch self {
        case .glueyGrip: return "Slow, rubbery drag"
        case .mechanicalClick: return "Crisp keyboard-like click"
        case .softPop: return "Muted, soft thock"
        case .bubblePop: return "Light, airy little pop"
        case .velvetTap: return "Deep, cushioned tap"
        case .waterDrop: return "Round, liquid plip"
        }
    }

    func render(seed: inout UInt64) -> [Float] {
        switch self {
        case .glueyGrip: return Synth.glueyGrip(seed: &seed)
        case .mechanicalClick: return Synth.mechanicalClick(seed: &seed)
        case .softPop: return Synth.softPop(seed: &seed)
        case .bubblePop: return Synth.bubblePop(seed: &seed)
        case .velvetTap: return Synth.velvetTap(seed: &seed)
        case .waterDrop: return Synth.waterDrop(seed: &seed)
        }
    }

    /// Approximate pixels-of-scroll per audible tick, before the user's sensitivity
    /// multiplier is applied. Denser packs (clicks) want smaller ticks than long,
    /// slow-decaying ones (gluey), otherwise they either smear together or feel sparse.
    var baseTickDistance: Double {
        switch self {
        case .glueyGrip: return 22
        case .mechanicalClick: return 9
        case .softPop: return 16
        case .bubblePop: return 12
        case .velvetTap: return 18
        case .waterDrop: return 20
        }
    }
}
