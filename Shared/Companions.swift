import Foundation

/// A colour as plain numbers, so the extensions can use themes without SwiftUI.
struct RGB: Equatable {
    let r: Double, g: Double, b: Double
    init(_ r: Double, _ g: Double, _ b: Double) { self.r = r; self.g = g; self.b = b }
}

/// Every colour OMO uses, by role rather than by hue, so each theme can fill them in.
struct ThemePalette: Equatable {
    /// Page background.
    let paper: RGB
    /// Card and sheet background.
    let card: RGB
    /// Body text and dark strokes.
    let ink: RGB
    /// Buttons, rings, selected states.
    let primary: RGB
    /// Breaks, highlights, capitals.
    let gold: RGB
    /// Small secondary accents.
    let clay: RGB
    /// Focus time, "back to it" and success states.
    let success: RGB
    /// Soft background glow.
    let blush: RGB
}

/// Your OMOs: companions from classical mythology. Each one brings its own colour
/// theme, and all but the first two are unlocked by lifetime focus hours.
enum OmoCompanion: String, Codable, CaseIterable, Identifiable {
    // Listed in unlock order.
    case glaux, selene, sphinx, nyx, hippocampus, phoenix, pegasus, apollo, athena

    var id: String { rawValue }

    var name: String {
        switch self {
        case .glaux: return "Glaux"
        case .selene: return "Selene"
        case .sphinx: return "Sphinx"
        case .nyx: return "Nyx"
        case .hippocampus: return "Hippocampus"
        case .phoenix: return "Phoenix"
        case .pegasus: return "Pegasus"
        case .apollo: return "Apollo"
        case .athena: return "Athena"
        }
    }

    var epithet: String {
        switch self {
        case .glaux: return "Athena's owl"
        case .selene: return "The moon"
        case .sphinx: return "Keeper of riddles"
        case .nyx: return "Goddess of night"
        case .hippocampus: return "The sea-horse"
        case .phoenix: return "The firebird"
        case .pegasus: return "The winged horse"
        case .apollo: return "God of light and learning"
        case .athena: return "Goddess of wisdom"
        }
    }

    /// Why this figure, in a sentence.
    var story: String {
        switch self {
        case .glaux: return "The owl of wisdom, who sees clearly when all else is dark."
        case .selene: return "She lights the night for anyone still studying."
        case .sphinx: return "Guards the answer until you've thought it through."
        case .nyx: return "Older than the gods, and at home in the quiet of night."
        case .hippocampus: return "Your brain's memory centre is named after this sea-horse."
        case .phoenix: return "Burns out, rests, and rises again. Breaks are part of it."
        case .pegasus: return "Its hoof opened the spring of the Muses, the source of inspiration."
        case .apollo: return "Brings the light of knowledge, the sun and music."
        case .athena: return "You began with her owl. Now the goddess herself studies with you."
        }
    }

    /// A short line your OMO says from the top of the Focus tab.
    var whisper: String {
        switch self {
        case .glaux: return "Wisdom watches over the patient."
        case .selene: return "The night belongs to those who stay."
        case .sphinx: return "Answer, or remain."
        case .nyx: return "In the deepest quiet, the mind is sharpest."
        case .hippocampus: return "What you repeat, I keep."
        case .phoenix: return "Rest is not the end. Rise."
        case .pegasus: return "Inspiration finds those already at work."
        case .apollo: return "Let light fall on what you seek."
        case .athena: return "Ten thousand hours. Now you see as I see."
        }
    }

    /// What the colour theme looks like.
    var themeDescription: String {
        switch self {
        case .glaux: return "Parchment, lapis blue and ochre gold."
        case .selene: return "Midnight navy and moonlight. Dark, and free."
        case .sphinx: return "Cool marble and slate."
        case .nyx: return "Black and deep violet."
        case .hippocampus: return "Sea-foam and coral."
        case .phoenix: return "Terracotta and flame."
        case .pegasus: return "Gilded ivory and gold leaf."
        case .apollo: return "Ceiling-sky blue and sunlight."
        case .athena: return "Sepia ink and red chalk, like Leonardo's notebooks."
        }
    }

    /// Lifetime focus hours needed to unlock this OMO. Glaux and Selene are free.
    var requiredHours: Int {
        switch self {
        case .glaux, .selene: return 0
        case .sphinx: return 10
        case .nyx: return 50
        case .hippocampus: return 100
        case .phoenix: return 500
        case .pegasus: return 1_000
        case .apollo: return 5_000
        case .athena: return 10_000
        }
    }

    func isUnlocked(totalMinutes: Int) -> Bool { totalMinutes >= requiredHours * 60 }

    /// The figure in Shared/Figures.xcassets.
    var imageName: String { "omo-\(rawValue)" }

    var isDark: Bool { self == .selene || self == .nyx }

    var palette: ThemePalette {
        switch self {
        case .glaux:
            return ThemePalette(paper: RGB(0.98, 0.955, 0.91), card: RGB(1, 1, 1), ink: RGB(0.16, 0.17, 0.27),
                                primary: RGB(0.18, 0.29, 0.62), gold: RGB(0.84, 0.63, 0.23), clay: RGB(0.75, 0.38, 0.23),
                                success: RGB(0.36, 0.61, 0.54), blush: RGB(0.85, 0.55, 0.48))
        case .selene:
            return ThemePalette(paper: RGB(0.07, 0.09, 0.17), card: RGB(0.11, 0.14, 0.25), ink: RGB(0.95, 0.92, 0.86),
                                primary: RGB(0.38, 0.50, 0.90), gold: RGB(0.86, 0.67, 0.29), clay: RGB(0.85, 0.52, 0.38),
                                success: RGB(0.45, 0.75, 0.65), blush: RGB(0.55, 0.40, 0.62))
        case .sphinx:
            return ThemePalette(paper: RGB(0.955, 0.955, 0.948), card: RGB(1, 1, 1), ink: RGB(0.17, 0.18, 0.20),
                                primary: RGB(0.22, 0.37, 0.43), gold: RGB(0.76, 0.61, 0.35), clay: RGB(0.55, 0.45, 0.40),
                                success: RGB(0.38, 0.57, 0.49), blush: RGB(0.78, 0.73, 0.71))
        case .nyx:
            return ThemePalette(paper: RGB(0.04, 0.035, 0.06), card: RGB(0.10, 0.08, 0.15), ink: RGB(0.94, 0.91, 0.98),
                                primary: RGB(0.55, 0.36, 0.96), gold: RGB(0.77, 0.69, 0.99), clay: RGB(0.93, 0.45, 0.70),
                                success: RGB(0.45, 0.80, 0.70), blush: RGB(0.43, 0.25, 0.75))
        case .hippocampus:
            return ThemePalette(paper: RGB(0.94, 0.965, 0.95), card: RGB(1, 1, 1), ink: RGB(0.17, 0.23, 0.26),
                                primary: RGB(0.78, 0.40, 0.35), gold: RGB(0.86, 0.68, 0.40), clay: RGB(0.28, 0.55, 0.55),
                                success: RGB(0.33, 0.60, 0.54), blush: RGB(0.93, 0.70, 0.68))
        case .phoenix:
            return ThemePalette(paper: RGB(0.975, 0.94, 0.89), card: RGB(1, 0.995, 0.985), ink: RGB(0.22, 0.18, 0.15),
                                primary: RGB(0.68, 0.32, 0.19), gold: RGB(0.72, 0.62, 0.28), clay: RGB(0.24, 0.36, 0.27),
                                success: RGB(0.45, 0.54, 0.27), blush: RGB(0.88, 0.62, 0.50))
        case .pegasus:
            return ThemePalette(paper: RGB(0.98, 0.955, 0.875), card: RGB(1, 0.995, 0.97), ink: RGB(0.20, 0.16, 0.10),
                                primary: RGB(0.55, 0.39, 0.08), gold: RGB(0.85, 0.66, 0.20), clay: RGB(0.55, 0.20, 0.17),
                                success: RGB(0.36, 0.50, 0.32), blush: RGB(0.93, 0.80, 0.52))
        case .apollo:
            return ThemePalette(paper: RGB(0.93, 0.95, 0.98), card: RGB(1, 1, 1), ink: RGB(0.15, 0.20, 0.30),
                                primary: RGB(0.24, 0.42, 0.71), gold: RGB(0.88, 0.65, 0.31), clay: RGB(0.79, 0.50, 0.48),
                                success: RGB(0.38, 0.62, 0.55), blush: RGB(0.95, 0.80, 0.70))
        case .athena:
            return ThemePalette(paper: RGB(0.95, 0.90, 0.80), card: RGB(0.985, 0.955, 0.895), ink: RGB(0.23, 0.16, 0.10),
                                primary: RGB(0.48, 0.29, 0.14), gold: RGB(0.72, 0.53, 0.18), clay: RGB(0.55, 0.23, 0.17),
                                success: RGB(0.43, 0.48, 0.27), blush: RGB(0.80, 0.55, 0.42))
        }
    }

    /// The OMO in use. Kept in memory because colours are read many times per screen;
    /// SettingsStore updates it whenever you pick a different OMO.
    static var current: OmoCompanion = SharedStore.settings.companion
}
