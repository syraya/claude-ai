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

/// The themes you can pick in Settings, each from the world of Renaissance art.
enum OmoTheme: String, Codable, CaseIterable, Identifiable {
    case fresco, marble, venus, tuscany, nightStudy

    var id: String { rawValue }

    var name: String {
        switch self {
        case .fresco: return "Fresco"
        case .marble: return "Marble"
        case .venus: return "Venus"
        case .tuscany: return "Tuscany"
        case .nightStudy: return "Night Study"
        }
    }

    var blurb: String {
        switch self {
        case .fresco: return "Parchment, lapis blue and ochre gold, like a painted wall in an old academy."
        case .marble: return "Cool white stone and slate, like a sculptor's studio."
        case .venus: return "Sea-foam and shell pink, from Botticelli's Birth of Venus."
        case .tuscany: return "Terracotta roofs, olive groves and cypress hills."
        case .nightStudy: return "Deep ultramarine and candlelight gold, for late nights."
        }
    }

    var isDark: Bool { self == .nightStudy }

    var palette: ThemePalette {
        switch self {
        case .fresco:
            return ThemePalette(paper: RGB(0.98, 0.955, 0.91), card: RGB(1, 1, 1), ink: RGB(0.16, 0.17, 0.27),
                                primary: RGB(0.18, 0.29, 0.62), gold: RGB(0.84, 0.63, 0.23), clay: RGB(0.75, 0.38, 0.23),
                                success: RGB(0.36, 0.61, 0.54), blush: RGB(0.85, 0.55, 0.48))
        case .marble:
            return ThemePalette(paper: RGB(0.955, 0.955, 0.948), card: RGB(1, 1, 1), ink: RGB(0.17, 0.18, 0.20),
                                primary: RGB(0.22, 0.37, 0.43), gold: RGB(0.76, 0.61, 0.35), clay: RGB(0.55, 0.45, 0.40),
                                success: RGB(0.38, 0.57, 0.49), blush: RGB(0.78, 0.73, 0.71))
        case .venus:
            return ThemePalette(paper: RGB(0.94, 0.965, 0.95), card: RGB(1, 1, 1), ink: RGB(0.17, 0.23, 0.26),
                                primary: RGB(0.78, 0.40, 0.35), gold: RGB(0.86, 0.68, 0.40), clay: RGB(0.28, 0.55, 0.55),
                                success: RGB(0.33, 0.60, 0.54), blush: RGB(0.93, 0.70, 0.68))
        case .tuscany:
            return ThemePalette(paper: RGB(0.975, 0.94, 0.89), card: RGB(1, 0.995, 0.985), ink: RGB(0.22, 0.18, 0.15),
                                primary: RGB(0.68, 0.32, 0.19), gold: RGB(0.72, 0.62, 0.28), clay: RGB(0.24, 0.36, 0.27),
                                success: RGB(0.45, 0.54, 0.27), blush: RGB(0.88, 0.62, 0.50))
        case .nightStudy:
            return ThemePalette(paper: RGB(0.07, 0.09, 0.17), card: RGB(0.11, 0.14, 0.25), ink: RGB(0.95, 0.92, 0.86),
                                primary: RGB(0.38, 0.50, 0.90), gold: RGB(0.86, 0.67, 0.29), clay: RGB(0.85, 0.52, 0.38),
                                success: RGB(0.45, 0.75, 0.65), blush: RGB(0.55, 0.40, 0.62))
        }
    }

    /// The theme in use. Kept in memory because colours are read many times per screen;
    /// SettingsStore updates it whenever you pick a new theme.
    static var current: OmoTheme = SharedStore.settings.theme
}
