import SwiftUI

/// The breathing screen's art and words for each OMO: a faint landscape with the
/// companion in it, and a credited line from a philosopher.
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
        "q11": Quote(text: "The cosmos is within us. We are made of star-stuff.", author: "Carl Sagan", source: "Cosmos, episode 1, \u{201C}The Shores of the Cosmic Ocean\u{201D} (1980)"),
    ]

    private static let pairings: [OmoCompanion: (background: UInt32, quote: String)] = [
        .glaux: (0xF4ECE1, "q01"),
        .selene: (0x121E32, "q03"),
        .daphne: (0xEFF2E7, "q05"),
        .noor: (0xFCEBEE, "q07"),
        .asteria: (0x141B30, "q11"),
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
        .gaia: (0xEBF1E5, "q05"),
        .loon: (0xE9F2F9, "q04"),
        .chiron: (0x172C2A, "q09"),
        .hecate: (0x211412, "q07"),
        .demeter: (0xF8ECDB, "q05"),
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
        .asteria: 0x2D2949,
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
    ]

    init(for companion: OmoCompanion) {
        let pairing = Self.pairings[companion] ?? (0xF5F0E4, "q01")
        imageName = "breath-\(companion.rawValue)"
        background = RGB(pairing.background)
        sky = RGB(Self.skies[companion] ?? pairing.background)
        quote = Self.quotes[pairing.quote] ?? Self.quotes["q01"]!
    }
}
