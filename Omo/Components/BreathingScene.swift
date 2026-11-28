import SwiftUI
import CoreGraphics

/// The breathing screen's art and words for each OMO: a faint landscape with the
/// companion standing in it, and a credited line from a philosopher (or, for a few holiday
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
    /// The frame the OMO's figure is drawn in over the landscape, as fractions of its
    /// size. The figure is vector artwork, so it stays sharp at any size.
    let figure: CGRect?
    let figureImage: String
    /// The landscape's width over its height.
    let aspectRatio: CGFloat

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
        .asteria: 0x282A44,
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
        .hestia: 0xF1DAC5,
        .turtleIsland: 0xFAE0C4,
        .mnemosyne: 0xEEE9E1,
    ]

    /// For each OMO: where its figure stands in the landscape (`focus`), and the frame
    /// its figure artwork is drawn in (`figure`), both as fractions of the landscape.
    private static let placements: [OmoCompanion: (focus: CGRect, figure: CGRect)] = [
        .glaux: (CGRect(x: 0.3093, y: 0.1583, width: 0.3953, height: 0.7167),
                  CGRect(x: 0.2913, y: 0.1277, width: 0.4328, height: 0.7754)),
        .selene: (CGRect(x: 0.3687, y: 0.0535, width: 0.2544, height: 0.8276),
                  CGRect(x: 0.2389, y: 0.0028, width: 0.5140, height: 0.9485)),
        .daphne: (CGRect(x: 0.3012, y: 0.0870, width: 0.4023, height: 0.8379),
                  CGRect(x: 0.2360, y: 0.0535, width: 0.5322, height: 0.9045)),
        .noor: (CGRect(x: 0.3291, y: 0.0741, width: 0.2884, height: 0.8189),
                  CGRect(x: 0.2254, y: 0.0414, width: 0.4985, height: 0.8821)),
        .sphinx: (CGRect(x: 0.3465, y: 0.1186, width: 0.3605, height: 0.7558),
                  CGRect(x: 0.3225, y: 0.0885, width: 0.4071, height: 0.8142)),
        .nyx: (CGRect(x: 0.2814, y: 0.0696, width: 0.3070, height: 0.8460),
                  CGRect(x: 0.1816, y: 0.0359, width: 0.5028, height: 0.9123)),
        .hippocampus: (CGRect(x: 0.3000, y: 0.0731, width: 0.4070, height: 0.8539),
                  CGRect(x: 0.2679, y: 0.0390, width: 0.4691, height: 0.9211)),
        .phoenix: (CGRect(x: 0.2733, y: 0.0976, width: 0.4663, height: 0.8308),
                  CGRect(x: 0.2541, y: 0.0365, width: 0.5038, height: 0.9399)),
        .pegasus: (CGRect(x: 0.2767, y: 0.0839, width: 0.4628, height: 0.8631),
                  CGRect(x: 0.2585, y: 0.0427, width: 0.4987, height: 0.9468)),
        .apollo: (CGRect(x: 0.3477, y: 0.0741, width: 0.3233, height: 0.8417),
                  CGRect(x: 0.2425, y: 0.0344, width: 0.5299, height: 0.9133)),
        .athena: (CGRect(x: 0.3442, y: 0.0907, width: 0.2709, height: 0.8371),
                  CGRect(x: 0.2261, y: 0.0579, width: 0.5069, height: 0.8988)),
        .huginnMuninn: (CGRect(x: 0.1977, y: 0.1247, width: 0.5779, height: 0.7805),
                  CGRect(x: 0.1735, y: -0.1549, width: 0.6268, height: 1.3443)),
        .anansi: (CGRect(x: 0.2733, y: 0.0966, width: 0.5291, height: 0.8045),
                  CGRect(x: 0.2519, y: -0.0636, width: 0.5840, height: 1.1286)),
        .koi: (CGRect(x: 0.1977, y: 0.1190, width: 0.5384, height: 0.7576),
                  CGRect(x: 0.1707, y: -0.0498, width: 0.5871, height: 1.0929)),
        .thoth: (CGRect(x: 0.3419, y: 0.0797, width: 0.3326, height: 0.8599),
                  CGRect(x: 0.2577, y: 0.0459, width: 0.5008, height: 0.9283)),
        .dragon: (CGRect(x: 0.2302, y: 0.1118, width: 0.5081, height: 0.8165),
                  CGRect(x: 0.2076, y: 0.0188, width: 0.5511, height: 0.9999)),
        .odin: (CGRect(x: 0.3674, y: 0.0535, width: 0.3500, height: 0.8396),
                  CGRect(x: 0.3056, y: 0.0199, width: 0.4739, height: 0.9078)),
        .salmon: (CGRect(x: 0.2279, y: 0.1678, width: 0.4895, height: 0.6503),
                  CGRect(x: 0.2081, y: -0.0371, width: 0.5284, height: 1.0592)),
        .simurgh: (CGRect(x: 0.2372, y: 0.0942, width: 0.5372, height: 0.8051),
                  CGRect(x: 0.2158, y: -0.0366, width: 0.5798, height: 1.0678)),
        .quetzalcoatl: (CGRect(x: 0.2767, y: 0.1255, width: 0.5570, height: 0.7934),
                  CGRect(x: 0.2507, y: 0.0184, width: 0.6054, height: 1.0051)),
        .janus: (CGRect(x: 0.3663, y: 0.1171, width: 0.2698, height: 0.7838),
                  CGRect(x: 0.2823, y: 0.0858, width: 0.4372, height: 0.8469)),
        .qilin: (CGRect(x: 0.3128, y: 0.0998, width: 0.4419, height: 0.7815),
                  CGRect(x: 0.2951, y: 0.0004, width: 0.4769, height: 0.9742)),
        .psyche: (CGRect(x: 0.2453, y: 0.0846, width: 0.5105, height: 0.8269),
                  CGRect(x: 0.2250, y: 0.0418, width: 0.5510, height: 0.9112)),
        .gaia: (CGRect(x: 0.2767, y: 0.0915, width: 0.4244, height: 0.8110),
                  CGRect(x: 0.2405, y: 0.0592, width: 0.4993, height: 0.8728)),
        .loon: (CGRect(x: 0.2442, y: 0.2471, width: 0.5314, height: 0.7140),
                  CGRect(x: 0.2118, y: 0.0202, width: 0.5944, height: 1.1698)),
        .chiron: (CGRect(x: 0.2733, y: 0.0957, width: 0.4558, height: 0.8087),
                  CGRect(x: 0.2544, y: 0.0373, width: 0.4952, height: 0.9258)),
        .hecate: (CGRect(x: 0.3453, y: 0.0758, width: 0.3128, height: 0.8363),
                  CGRect(x: 0.2385, y: 0.0415, width: 0.5261, height: 0.9032)),
        .demeter: (CGRect(x: 0.3314, y: 0.0669, width: 0.3291, height: 0.8473),
                  CGRect(x: 0.2416, y: 0.0332, width: 0.5074, height: 0.9130)),
        .yuleStag: (CGRect(x: 0.3209, y: 0.1121, width: 0.3744, height: 0.8034),
                  CGRect(x: 0.2705, y: 0.0801, width: 0.4755, height: 0.8645)),
        .mnemosyne: (CGRect(x: 0.3093, y: 0.2460, width: 0.3802, height: 0.6940),
                  CGRect(x: 0.2792, y: 0.2102, width: 0.4426, height: 0.7614)),
        .hestia: (CGRect(x: 0.3000, y: 0.3060, width: 0.4000, height: 0.6340),
                  CGRect(x: 0.2779, y: 0.2420, width: 0.4427, height: 0.7615)),
        .turtleIsland: (CGRect(x: 0.2256, y: 0.1100, width: 0.5488, height: 0.8600),
                  CGRect(x: 0.2096, y: -0.0835, width: 0.5808, height: 1.2487)),
        .asteria: (CGRect(x: 0.2977, y: 0.3469, width: 0.4035, height: 0.5923),
                  CGRect(x: 0.2735, y: 0.2514, width: 0.4483, height: 0.7821)),
    ]

    init(for companion: OmoCompanion) {
        let pairing = Self.pairings[companion] ?? (0xF5F0E4, "q01")
        imageName = "breath-\(companion.rawValue)"
        background = RGB(pairing.background)
        sky = RGB(Self.skies[companion] ?? pairing.background)
        quote = Self.quotes[pairing.quote] ?? Self.quotes["q01"]!
        focus = Self.placements[companion]?.focus
        figure = Self.placements[companion]?.figure
        figureImage = companion.imageName
        let size = UIImage(named: imageName)?.size ?? CGSize(width: 16, height: 9)
        aspectRatio = size.height > 0 ? size.width / size.height : 16 / 9
    }
}

/// An OMO's landscape with its figure on top. The landscape is a soft painting; the
/// figure is drawn from its vector artwork, so it's crisp at any size. `fade` softens
/// the landscape's edges into the page without touching the figure.
struct SceneCanvas: View {
    let scene: BreathingScene
    var fade: LinearGradient? = nil

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .topLeading) {
                Image(scene.imageName)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .mask { fade ?? LinearGradient(colors: [.black], startPoint: .top, endPoint: .bottom) }
                if let frame = scene.figure {
                    Image(scene.figureImage)
                        .resizable()
                        .frame(width: frame.width * size.width, height: frame.height * size.height)
                        .offset(x: frame.minX * size.width, y: frame.minY * size.height)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
    }
}

