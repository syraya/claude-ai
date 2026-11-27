import SwiftUI
import CoreGraphics

/// The breathing screen's art and words for each OMO: a faint landscape with the
/// companion in it, and a credited line from a philosopher (or, for a few holiday
/// OMOs, a reflection of OMO's own).
struct BreathingScene {
    struct Quote {
        let text: String
        let author: String
        /// Work, section and translator, for the accessibility label and credits.
        let source: String
    }

    let imageName: String
    /// The scene's own paper colour, so the art melts into the screen.
    let background: RGB
    /// The colour along the top edge of the art, for extending its sky upward.
    let sky: RGB
    let quote: Quote
    /// Where the OMO's figure sits in the art, as fractions of its width and height,
    /// so the gallery's arch can frame the figure whole.
    let focus: CGRect?

    static let quotes: [String: Quote] = [
        "q01": Quote(text: "Confine thyself to the present.", author: "Marcus Aurelius", source: "Meditations, Book VII, section 29, tr. George Long"),
        "q02": Quote(text: "The universe is transformation: life is opinion.", author: "Marcus Aurelius", source: "Meditations, Book IV, section 3, tr. George Long"),
        "q03": Quote(text: "Let it be still, and it will gradually become clear.", author: "Laozi", source: "Tao Te Ching, Chapter 15, paragraph 3, tr. James Legge"),
        "q04": Quote(text: "Heaven is under our feet as well as over our heads.", author: "Henry David Thoreau", source: "Walden, Chapter 16, 'The Pond in Winter', paragraph 2 (Digital Thoreau segment 2c)"),
        "q05": Quote(text: "We can never have enough of nature.", author: "Henry David Thoreau", source: "Walden, Chapter 17, 'Spring', paragraph 24"),
        "q06": Quote(text: "We have a great deal more kindness than is ever spoken.", author: "Ralph Waldo Emerson", source: "Essays: First Series, Essay VI, 'Friendship', opening prose sentence"),
        "q07": Quote(text: "Wait, and thy heart shall speak.", author: "Ralph Waldo Emerson", source: "Essays: First Series, Essay VI, 'Friendship', paragraph beginning 'What is so great as friendship'"),
        "q08": Quote(text: "Learning without thought is labor lost; thought without learning is perilous.", author: "Confucius", source: "Analects, Book II, section 15, tr. James Legge"),
        "q09": Quote(text: "The process is mutual; for men learn while they teach.", author: "Seneca", source: "Moral Letters to Lucilius, Letter VII, 'On Crowds', section 8, tr. Richard M. Gummere"),
        "q10": Quote(text: "Direct thy attention to what is said.", author: "Marcus Aurelius", source: "Meditations, Book VII, section 30, tr. George Long"),
        "r01": Quote(text: "Be present with the people who matter.", author: "An OMO reflection", source: "Original OMO reflection"),
        "r02": Quote(text: "Listen, learn, and carry the stories forward.", author: "An OMO reflection", source: "Original OMO reflection"),
        "r03": Quote(text: "Take a moment. Remember their stories.", author: "An OMO reflection", source: "Original OMO reflection"),
        "q11": Quote(text: "The cosmos is within us. We are made of star-stuff.", author: "Carl Sagan", source: "Cosmos, episode 1, \u{201C}The Shores of the Cosmic Ocean\u{201D} (1980)"),
    ]

    private static let pairings: [OmoCompanion: (background: UInt32, quote: String)] = [
        .glaux: (0xF4ECE1, "q01"),
        .selene: (0x121E32, "q03"),
        .daphne: (0xEFF2E7, "q05"),
        .noor: (0xFCEBEE, "q07"),
        .asteria: (0x1C2139, "q11"),
        .sphinx: (0xEAEFF2, "q08"),
        .nyx: (0x170E1F, "q03"),
        .hippocampus: (0xE9F5F2, "q04"),
        .phoenix: (0xFEF1E9, "q02"),
        .pegasus: (0xFAF3E3, "q04"),
        .apollo: (0xE4EEF7, "q01"),
        .athena: (0xF9EDDD, "q08"),
        .huginnMuninn: (0xEAEEF1, "q06"),
        .anansi: (0xFAF0E4, "q10"),
        .koi: (0xE3F2F9, "q03"),
        .thoth: (0xFCF0E3, "q09"),
        .dragon: (0xEAF4EC, "q02"),
        .odin: (0x112027, "q10"),
        .salmon: (0xF0F5EE, "q08"),
        .simurgh: (0xE1F4F2, "q06"),
        .quetzalcoatl: (0xEDF6EE, "q05"),
        .janus: (0x1A1921, "q01"),
        .qilin: (0xFBEDE4, "q06"),
        .psyche: (0xF8EAF4, "q07"),
        .hestia: (0xF7EDE2, "r01"),
        .gaia: (0xEBF1E5, "q05"),
        .loon: (0xE9F2F9, "q04"),
        .turtleIsland: (0xFBF1E2, "r02"),
        .chiron: (0x172C2A, "q09"),
        .hecate: (0x211412, "q07"),
        .demeter: (0xF8ECDB, "q05"),
        .mnemosyne: (0xF3EFE8, "r03"),
        .yuleStag: (0xF1F3EB, "q03"),
    ]

    private static let skies: [OmoCompanion: UInt32] = [
        .anansi: 0xFAF0E4,
        .apollo: 0xE3EDF7,
        .athena: 0xFAEFDF,
        .chiron: 0x182F29,
        .daphne: 0xEFF2E7,
        .demeter: 0xF9EDDD,
        .dragon: 0xEFF6EE,
        .gaia: 0xEEF2E5,
        .glaux: 0xF5EDE2,
        .hecate: 0x231514,
        .hippocampus: 0xEAF6F2,
        .huginnMuninn: 0xEBEFF2,
        .janus: 0x191821,
        .koi: 0xE6F3FA,
        .loon: 0xEAF2F9,
        .noor: 0xFDECEF,
        .asteria: 0x2A2B46,
        .nyx: 0x180F22,
        .odin: 0x112128,
        .pegasus: 0xFAF2E3,
        .phoenix: 0xFEF1E9,
        .psyche: 0xF9EBF5,
        .qilin: 0xFCEEE5,
        .quetzalcoatl: 0xECF6EE,
        .salmon: 0xEFF4ED,
        .selene: 0x122037,
        .simurgh: 0xE4F7F5,
        .sphinx: 0xEBF1F2,
        .thoth: 0xFCF1E5,
        .yuleStag: 0xF2F4EB,
        .hestia: 0xF0D8C2,
        .turtleIsland: 0xFADFC1,
        .mnemosyne: 0xEDE8E0,
    ]

    private static let focuses: [OmoCompanion: CGRect] = [
        .glaux: CGRect(x: 0.309, y: 0.158, width: 0.395, height: 0.717),
        .selene: CGRect(x: 0.369, y: 0.073, width: 0.255, height: 0.807),
        .daphne: CGRect(x: 0.301, y: 0.087, width: 0.402, height: 0.838),
        .noor: CGRect(x: 0.329, y: 0.074, width: 0.288, height: 0.819),
        .sphinx: CGRect(x: 0.347, y: 0.119, width: 0.360, height: 0.756),
        .nyx: CGRect(x: 0.281, y: 0.070, width: 0.307, height: 0.846),
        .hippocampus: CGRect(x: 0.300, y: 0.073, width: 0.407, height: 0.854),
        .phoenix: CGRect(x: 0.273, y: 0.098, width: 0.466, height: 0.831),
        .pegasus: CGRect(x: 0.277, y: 0.084, width: 0.463, height: 0.863),
        .apollo: CGRect(x: 0.348, y: 0.074, width: 0.323, height: 0.842),
        .athena: CGRect(x: 0.344, y: 0.091, width: 0.271, height: 0.837),
        .huginnMuninn: CGRect(x: 0.198, y: 0.125, width: 0.578, height: 0.781),
        .anansi: CGRect(x: 0.273, y: 0.097, width: 0.529, height: 0.804),
        .koi: CGRect(x: 0.198, y: 0.119, width: 0.538, height: 0.758),
        .thoth: CGRect(x: 0.342, y: 0.080, width: 0.333, height: 0.860),
        .dragon: CGRect(x: 0.230, y: 0.112, width: 0.508, height: 0.816),
        .odin: CGRect(x: 0.367, y: 0.053, width: 0.350, height: 0.840),
        .salmon: CGRect(x: 0.228, y: 0.168, width: 0.490, height: 0.650),
        .simurgh: CGRect(x: 0.237, y: 0.094, width: 0.537, height: 0.805),
        .quetzalcoatl: CGRect(x: 0.277, y: 0.125, width: 0.557, height: 0.793),
        .janus: CGRect(x: 0.366, y: 0.117, width: 0.270, height: 0.784),
        .qilin: CGRect(x: 0.313, y: 0.100, width: 0.442, height: 0.781),
        .psyche: CGRect(x: 0.245, y: 0.085, width: 0.510, height: 0.827),
        .gaia: CGRect(x: 0.277, y: 0.091, width: 0.424, height: 0.811),
        .loon: CGRect(x: 0.244, y: 0.247, width: 0.531, height: 0.714),
        .chiron: CGRect(x: 0.273, y: 0.096, width: 0.456, height: 0.809),
        .hecate: CGRect(x: 0.345, y: 0.076, width: 0.313, height: 0.836),
        .demeter: CGRect(x: 0.331, y: 0.067, width: 0.329, height: 0.847),
        .yuleStag: CGRect(x: 0.321, y: 0.112, width: 0.374, height: 0.803),
        .mnemosyne: CGRect(x: 0.309, y: 0.246, width: 0.38, height: 0.694),
        .hestia: CGRect(x: 0.3, y: 0.306, width: 0.4, height: 0.634),
        .turtleIsland: CGRect(x: 0.228, y: 0.3, width: 0.543, height: 0.67),
        .asteria: CGRect(x: 0.299, y: 0.349, width: 0.402, height: 0.59),
    ]

    init(for companion: OmoCompanion) {
        let pairing = Self.pairings[companion] ?? (0xF5F0E4, "q01")
        imageName = "breath-\(companion.rawValue)"
        background = RGB(pairing.background)
        sky = RGB(Self.skies[companion] ?? pairing.background)
        quote = Self.quotes[pairing.quote] ?? Self.quotes["q01"]!
        focus = Self.focuses[companion]
    }
}
