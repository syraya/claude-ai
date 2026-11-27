import Foundation

/// A colour as plain numbers, so the extensions can use themes without SwiftUI.
struct RGB: Equatable {
    let r: Double, g: Double, b: Double
    init(_ r: Double, _ g: Double, _ b: Double) { self.r = r; self.g = g; self.b = b }
    init(_ hex: UInt32) {
        self.init(Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255, Double(hex & 0xFF) / 255)
    }
}

/// Every colour OMO uses, by role rather than by hue, so each theme can fill them in.
struct ThemePalette: Equatable {
    /// Page background.
    let paper: RGB
    /// Cards, sheets and grouped areas.
    let card: RGB
    /// Body text and dark strokes.
    let ink: RGB
    /// Secondary text and small labels. Readable on paper and card.
    let labels: RGB
    /// Buttons, rings, selected states.
    let primary: RGB
    /// Text and icons on a primary-coloured fill.
    let onPrimary: RGB
    /// Decorative identity details (laurels, progress, figures). Not for small text.
    let gold: RGB
    /// A second decorative colour from the OMO's own artwork.
    let clay: RGB
    /// Focus time, "back to it" and success states. Pair it with a label or icon.
    let success: RGB

    /// Soft background glow: the accent, used faintly.
    var blush: RGB { clay }
}

/// How you earn an OMO.
enum OmoUnlock: Equatable {
    case free
    case hours(Int)
    case friends(Int)
    case sessions(Int)
    case streak(Int)
    case circles(Int)
    case longSession(minutes: Int)
    case holiday(OmoHoliday)
}

/// Your OMOs: companions from myths around the world. Each brings its own colour theme.
/// Some are earned with focus hours, some with other milestones, and some only on holidays.
enum OmoCompanion: String, Codable, CaseIterable, Identifiable {
    // The path (focus hours), then milestones, then holidays in calendar order.
    case glaux, selene, daphne, noor, asteria, sphinx, nyx, hippocampus, phoenix, pegasus, apollo, athena, huginnMuninn, anansi, koi, thoth, dragon, odin, salmon, simurgh, quetzalcoatl, janus, qilin, psyche, gaia, loon, chiron, hecate, demeter, yuleStag

    enum Kind: String, CaseIterable {
        case path = "The Path"
        case milestone = "Milestones"
        case holiday = "Holidays"
    }

    var id: String { rawValue }

    var name: String {
        switch self {
        case .glaux: return "Glaux"
        case .selene: return "Selene"
        case .daphne: return "Daphne"
        case .noor: return "Noor"
        case .asteria: return "Asteria"
        case .sphinx: return "Sphinx"
        case .nyx: return "Nyx"
        case .hippocampus: return "Hippocampus"
        case .phoenix: return "Phoenix"
        case .pegasus: return "Pegasus"
        case .apollo: return "Apollo"
        case .athena: return "Athena"
        case .huginnMuninn: return "Huginn & Muninn"
        case .anansi: return "Anansi"
        case .koi: return "Koi"
        case .thoth: return "Thoth"
        case .dragon: return "Dragon"
        case .odin: return "Odin"
        case .salmon: return "Salmon of Knowledge"
        case .simurgh: return "Simurgh"
        case .quetzalcoatl: return "Quetzalcoatl"
        case .janus: return "Janus"
        case .qilin: return "Qilin"
        case .psyche: return "Psyche"
        case .gaia: return "Gaia"
        case .loon: return "The Loon"
        case .chiron: return "Chiron"
        case .hecate: return "Hecate"
        case .demeter: return "Demeter"
        case .yuleStag: return "Yule Stag"
        }
    }

    var epithet: String {
        switch self {
        case .glaux: return "Athena's owl"
        case .selene: return "The moon"
        case .daphne: return "The laurel"
        case .noor: return "The light"
        case .asteria: return "The falling star"
        case .sphinx: return "Keeper of riddles"
        case .nyx: return "Goddess of night"
        case .hippocampus: return "The sea-horse"
        case .phoenix: return "The firebird"
        case .pegasus: return "The winged horse"
        case .apollo: return "God of light and learning"
        case .athena: return "Goddess of wisdom"
        case .huginnMuninn: return "Thought and Memory"
        case .anansi: return "Keeper of all stories"
        case .koi: return "Leaper of the Dragon Gate"
        case .thoth: return "Scribe of the gods"
        case .dragon: return "What the koi becomes"
        case .odin: return "Seeker of wisdom"
        case .salmon: return "From Irish myth"
        case .simurgh: return "The bird of thirty birds"
        case .quetzalcoatl: return "The feathered serpent"
        case .janus: return "God of beginnings"
        case .qilin: return "Bringer of good fortune"
        case .psyche: return "The soul"
        case .gaia: return "The Earth"
        case .loon: return "Call of the north"
        case .chiron: return "Teacher of heroes"
        case .hecate: return "Torchbearer of the crossroads"
        case .demeter: return "Goddess of the harvest"
        case .yuleStag: return "Winter's crown"
        }
    }

    /// Why this figure, in a sentence or two.
    var story: String {
        switch self {
        case .glaux: return "The owl of wisdom, who sees clearly when all else is dark."
        case .selene: return "She lights the night for anyone still studying."
        case .daphne: return "The nymph who became the laurel tree. Scholars are still crowned with her leaves, and \"baccalaureate\" comes from the laurel berry."
        case .noor: return "Noor means light. The hibiscus opens at dawn, turns toward the sun, and lasts a single day, so it spends every hour of it in the light."
        case .asteria: return "The Titaness of the stars and falling stars, a guide in the quiet hours of night. The Greeks tied her to dreams, wishes and finding your way."
        case .sphinx: return "Guards the answer until you've thought it through."
        case .nyx: return "Older than the gods, and at home in the quiet of night."
        case .hippocampus: return "Your brain's memory centre is named after this sea-horse."
        case .phoenix: return "Burns out, rests, and rises again. Breaks are part of it."
        case .pegasus: return "Its hoof opened the spring of the Muses, the source of inspiration."
        case .apollo: return "Brings the light of knowledge, the sun and music."
        case .athena: return "You began with her owl. Now the goddess herself studies with you."
        case .huginnMuninn: return "Odin's two ravens fly out each day and return with everything they've learned."
        case .anansi: return "In Akan folklore, the spider who won all the world's stories and wove them into one web."
        case .koi: return "A carp that kept leaping the waterfall until it cleared the gate. An old symbol of passing exams."
        case .thoth: return "Egyptian god of writing and knowledge, who measured the stars and kept every record."
        case .dragon: return "Two hundred and fifty sessions. The carp has cleared the Dragon Gate."
        case .odin: return "Gave an eye for wisdom and hung nine nights on the world tree to win the runes."
        case .salmon: return "Ate the hazelnuts of wisdom, year after year, until it knew all things."
        case .simurgh: return "In the Persian poem, thirty birds fly together to find the Simurgh, and discover they are it."
        case .quetzalcoatl: return "Aztec patron of learning, wind and the calendar."
        case .janus: return "The Roman god of doorways looks back at the year behind and ahead to the next."
        case .qilin: return "A gentle creature of Chinese legend that appears in times of wisdom and peace."
        case .psyche: return "Her name means soul, and gives us the word psychology. She carries a lamp and butterfly wings."
        case .gaia: return "The ancient Earth herself, mother of everything that grows."
        case .loon: return "Its call carries across northern lakes, and it's on every Canadian dollar coin."
        case .chiron: return "The wise centaur who taught Achilles and Asclepius, later set among the stars."
        case .hecate: return "Greek goddess of the crossroads, who carries two torches through the dark."
        case .demeter: return "Greek goddess of grain and the harvest. What you plant, you reap."
        case .yuleStag: return "An old northern winter spirit with a star caught in its antlers."
        }
    }

    /// A short line your OMO says from the top of the Focus tab.
    var whisper: String {
        switch self {
        case .glaux: return "Wisdom watches over the patient."
        case .selene: return "The night belongs to those who stay."
        case .daphne: return "Keep growing. The laurel waits."
        case .noor: return "One day of bloom. Spend it in the light."
        case .asteria: return "Follow the light, even when it falls."
        case .sphinx: return "Answer, or remain."
        case .nyx: return "In the deepest quiet, the mind is sharpest."
        case .hippocampus: return "What you repeat, I keep."
        case .phoenix: return "Rest is not the end. Rise."
        case .pegasus: return "Inspiration finds those already at work."
        case .apollo: return "Let light fall on what you seek."
        case .athena: return "Ten thousand hours. Now you see as I see."
        case .huginnMuninn: return "One thinks, one remembers. You need both."
        case .anansi: return "Every friend is another thread."
        case .koi: return "Again. Higher."
        case .thoth: return "Write it down. Then it is yours."
        case .dragon: return "You were always going to make it."
        case .odin: return "Wisdom asks something of you every day."
        case .salmon: return "A little, every day."
        case .simurgh: return "Together, we are what we were looking for."
        case .quetzalcoatl: return "Stay. The deep hours are where it happens."
        case .janus: return "Look back once. Then begin."
        case .qilin: return "A new year. A new chance."
        case .psyche: return "Care for the mind that does the work."
        case .gaia: return "Grow slowly. Grow deep."
        case .loon: return "Quiet lakes, clear minds."
        case .chiron: return "Every hero had a teacher."
        case .hecate: return "Choose a path. I'll light it."
        case .demeter: return "The harvest comes to those who sowed."
        case .yuleStag: return "Rest well. The new year is near."
        }
    }

    /// What the colour theme looks like.
    var themeDescription: String {
        switch self {
        case .glaux: return "Parchment, lapis blue and ochre gold."
        case .selene: return "Midnight navy and moonlight. Dark, and free."
        case .daphne: return "Sage, forest and laurel green. Free."
        case .noor: return "Hibiscus red, petal pink and morning gold. Free."
        case .asteria: return "Starlit indigo, violet and celestial gold. Dark, and free."
        case .sphinx: return "Cool marble and slate."
        case .nyx: return "Black and deep violet."
        case .hippocampus: return "Sea-foam and coral."
        case .phoenix: return "Terracotta and flame."
        case .pegasus: return "Gilded ivory and gold leaf."
        case .apollo: return "Ceiling-sky blue and sunlight."
        case .athena: return "Sepia ink and red chalk, like Leonardo's notebooks."
        case .huginnMuninn: return "Storm grey and raven black."
        case .anansi: return "Indigo and woven gold."
        case .koi: return "River blue and koi orange."
        case .thoth: return "Lapis and desert gold."
        case .dragon: return "Jade and imperial red."
        case .odin: return "Northern night and rune gold."
        case .salmon: return "River green and salmon."
        case .simurgh: return "Turquoise and Persian gold."
        case .quetzalcoatl: return "Jade and quetzal green."
        case .janus: return "Midnight and champagne gold."
        case .qilin: return "Lantern red and gold."
        case .psyche: return "Plum and butterfly lilac."
        case .gaia: return "Forest green and sky."
        case .loon: return "Maple red and lake blue."
        case .chiron: return "Chalkboard green and chalk."
        case .hecate: return "Midnight and ember orange."
        case .demeter: return "Wheat gold and russet."
        case .yuleStag: return "Evergreen, berry red and gold."
        }
    }

    var unlock: OmoUnlock {
        switch self {
        case .glaux: return .free
        case .selene: return .free
        case .daphne: return .free
        case .noor: return .free
        case .asteria: return .free
        case .sphinx: return .hours(10)
        case .nyx: return .hours(50)
        case .hippocampus: return .hours(100)
        case .phoenix: return .hours(500)
        case .pegasus: return .hours(1_000)
        case .apollo: return .hours(5_000)
        case .athena: return .hours(10_000)
        case .huginnMuninn: return .friends(3)
        case .anansi: return .friends(10)
        case .koi: return .sessions(25)
        case .thoth: return .sessions(100)
        case .dragon: return .sessions(250)
        case .odin: return .streak(9)
        case .salmon: return .streak(30)
        case .simurgh: return .circles(10)
        case .quetzalcoatl: return .longSession(minutes: 180)
        case .janus: return .holiday(.newYear)
        case .qilin: return .holiday(.lunarNewYear)
        case .psyche: return .holiday(.valentines)
        case .gaia: return .holiday(.earthDay)
        case .loon: return .holiday(.canadaDay)
        case .chiron: return .holiday(.teachersDay)
        case .hecate: return .holiday(.halloween)
        case .demeter: return .holiday(.thanksgiving)
        case .yuleStag: return .holiday(.christmas)
        }
    }

    var kind: Kind {
        switch unlock {
        case .free, .hours: return .path
        case .holiday: return .holiday
        default: return .milestone
        }
    }

    /// Focus hours needed, for OMOs on the path.
    var requiredHours: Int? {
        switch unlock {
        case .free: return 0
        case .hours(let hours): return hours
        default: return nil
        }
    }

    func isUnlocked(_ stats: LifetimeStats) -> Bool {
        if stats.developerAccess { return true }
        switch unlock {
        case .free: return true
        case .hours(let hours): return stats.totalFocusMinutes >= hours * 60
        case .friends(let count): return stats.maxFriends >= count
        case .sessions(let count): return stats.sessionsCompleted >= count
        case .streak(let days): return stats.longestStreak >= days
        case .circles(let count): return stats.friendSessions >= count
        case .longSession(let minutes): return stats.longestSessionMinutes >= minutes
        case .holiday(let holiday): return stats.earnedHolidays.contains(holiday.rawValue)
        }
    }

    /// What it takes, e.g. "Add 3 friends".
    var requirement: String {
        switch unlock {
        case .free: return "With you from the start"
        case .hours(let hours): return "Focus for \(hours.formatted()) hours in total"
        case .friends(let count): return "Add \(count) friends"
        case .sessions(let count): return "Complete \(count) focus sessions"
        case .streak(let days): return "Focus \(days) days in a row"
        case .circles(let count): return "Finish \(count) Study Circles"
        case .longSession(let minutes): return "Focus for \(minutes / 60) hours in one session"
        case .holiday(let holiday):
            return "Focus for \(OmoHoliday.requiredMinutes) minutes on \(holiday.name) (\(holiday.when))"
        }
    }

    /// A short label for small spaces, e.g. "3 friends" or "Jul 1".
    var shortRequirement: String {
        switch unlock {
        case .free: return "Free"
        case .hours(let hours): return "\(hours.formatted()) h"
        case .friends(let count): return "\(count) friends"
        case .sessions(let count): return "\(count) sessions"
        case .streak(let days): return "\(days)-day streak"
        case .circles(let count): return "\(count) circles"
        case .longSession(let minutes): return "\(minutes / 60) h session"
        case .holiday(let holiday): return holiday.name
        }
    }

    /// How close you are, e.g. "1 of 3 friends". Nil once unlocked.
    func progress(_ stats: LifetimeStats) -> String? {
        guard !isUnlocked(stats) else { return nil }
        switch unlock {
        case .free: return nil
        case .hours(let hours):
            let left = hours * 60 - stats.totalFocusMinutes
            return left < 60 ? "\(left) minutes to go" : "\(left / 60) hours to go"
        case .friends(let count): return "\(stats.maxFriends) of \(count) friends"
        case .sessions(let count): return "\(stats.sessionsCompleted) of \(count) sessions"
        case .streak(let days): return "Best streak so far: \(stats.longestStreak) of \(days) days"
        case .circles(let count): return "\(stats.friendSessions) of \(count) Study Circles"
        case .longSession(let minutes): return "Longest so far: \(stats.longestSessionMinutes / 60)h \(stats.longestSessionMinutes % 60)m of \(minutes / 60)h"
        case .holiday(let holiday): return holiday.isActive() ? "It's \(holiday.name) today. Start a session!" : "Comes back on \(holiday.when)"
        }
    }

    /// What you did to earn it, for the celebration.
    var achievement: String {
        switch unlock {
        case .free: return ""
        case .hours(let hours): return "\(hours.formatted()) hours of focus"
        case .friends(let count): return "You've added \(count) friends"
        case .sessions(let count): return "\(count) focus sessions completed"
        case .streak(let days): return "\(days) days in a row"
        case .circles(let count): return "\(count) Study Circles finished"
        case .longSession(let minutes): return "\(minutes / 60) hours of focus in one sitting"
        case .holiday(let holiday): return "You focused on \(holiday.name)"
        }
    }

    /// The figure in Shared/Figures.xcassets.
    var imageName: String { "omo-\(rawValue)" }

    var isDark: Bool {
        switch self {
        case .selene, .asteria, .nyx, .odin, .janus, .chiron, .hecate: return true
        default: return false
        }
    }

    /// Each OMO's colours, from design reference 02. Every text colour reaches at least
    /// 4.5:1 against the paper and card it sits on, and on-primary against primary.
    var palette: ThemePalette {
        switch self {
        case .glaux:
            return ThemePalette(paper: RGB(0xF5F0E4), card: RGB(0xFFFCF5), ink: RGB(0x222B3B), labels: RGB(0x63666C),
                                primary: RGB(0x293F78), onPrimary: RGB(0xFFFDF7), gold: RGB(0xB4975A),
                                clay: RGB(0x8C733D), success: RGB(0x356653))
        case .selene:
            return ThemePalette(paper: RGB(0x101A2B), card: RGB(0x18263A), ink: RGB(0xF2F0E7), labels: RGB(0xB7C0CE),
                                primary: RGB(0xC7D7EC), onPrimary: RGB(0x142035), gold: RGB(0xC8B67E),
                                clay: RGB(0x9EB6D2), success: RGB(0xA8C7B9))
        case .daphne:
            return ThemePalette(paper: RGB(0xEDF1E7), card: RGB(0xF8FAF3), ink: RGB(0x25382F), labels: RGB(0x59665B),
                                primary: RGB(0x375C47), onPrimary: RGB(0xFFFDF5), gold: RGB(0xA39658),
                                clay: RGB(0x81916B), success: RGB(0x3F6C53))
        case .noor:
            return ThemePalette(paper: RGB(0xF7EBEE), card: RGB(0xFFF6F7), ink: RGB(0x4B2632), labels: RGB(0x805764),
                                primary: RGB(0xA43F5C), onPrimary: RGB(0xFFF8F6), gold: RGB(0xC29B58),
                                clay: RGB(0xD1808D), success: RGB(0x476856))
        case .asteria:
            return ThemePalette(paper: RGB(0x141B30), card: RGB(0x1F2742), ink: RGB(0xECE7E0), labels: RGB(0xBDB3CB),
                                primary: RGB(0xCCBBD1), onPrimary: RGB(0x1E1A33), gold: RGB(0xD6B384),
                                clay: RGB(0xA795BA), success: RGB(0xA9C7B8))
        case .sphinx:
            return ThemePalette(paper: RGB(0xEDF0F0), card: RGB(0xF9FAF8), ink: RGB(0x28393D), labels: RGB(0x5D6A6D),
                                primary: RGB(0x465E66), onPrimary: RGB(0xFCFCF7), gold: RGB(0xAC9A6F),
                                clay: RGB(0x81989E), success: RGB(0x48695E))
        case .nyx:
            return ThemePalette(paper: RGB(0x17111F), card: RGB(0x241A32), ink: RGB(0xF0EAF4), labels: RGB(0xC3B5CF),
                                primary: RGB(0xB99AD8), onPrimary: RGB(0x24152F), gold: RGB(0xC3A76B),
                                clay: RGB(0x88719E), success: RGB(0xA4C1B1))
        case .hippocampus:
            return ThemePalette(paper: RGB(0xEAF3F0), card: RGB(0xF7FBF7), ink: RGB(0x203D40), labels: RGB(0x526D6F),
                                primary: RGB(0x286570), onPrimary: RGB(0xFBFFFB), gold: RGB(0xB09861),
                                clay: RGB(0xCB8E7B), success: RGB(0x39715D))
        case .phoenix:
            return ThemePalette(paper: RGB(0xF6ECE4), card: RGB(0xFFF7F0), ink: RGB(0x482B26), labels: RGB(0x7B5F55),
                                primary: RGB(0xA34B35), onPrimary: RGB(0xFFF9F3), gold: RGB(0xB48D4E),
                                clay: RGB(0xD88349), success: RGB(0x596C4A))
        case .pegasus:
            return ThemePalette(paper: RGB(0xF5F0E1), card: RGB(0xFFFCF4), ink: RGB(0x3C3427), labels: RGB(0x73674F),
                                primary: RGB(0x806133), onPrimary: RGB(0xFFFCF5), gold: RGB(0xB89A5E),
                                clay: RGB(0xC6AD75), success: RGB(0x5D6B4A))
        case .apollo:
            return ThemePalette(paper: RGB(0xEAF0F7), card: RGB(0xF8FBFF), ink: RGB(0x233B55), labels: RGB(0x5B6B7E),
                                primary: RGB(0x355E91), onPrimary: RGB(0xFCFDFF), gold: RGB(0xB6964D),
                                clay: RGB(0xD5B969), success: RGB(0x43766F))
        case .athena:
            return ThemePalette(paper: RGB(0xF1E9D9), card: RGB(0xFBF5E9), ink: RGB(0x4D3D2B), labels: RGB(0x79664F),
                                primary: RGB(0x714C32), onPrimary: RGB(0xFFF9ED), gold: RGB(0xB49361),
                                clay: RGB(0xA75E4D), success: RGB(0x5E6B4E))
        case .huginnMuninn:
            return ThemePalette(paper: RGB(0xEDF0F1), card: RGB(0xFAFBFA), ink: RGB(0x262E36), labels: RGB(0x616B74),
                                primary: RGB(0x404E5C), onPrimary: RGB(0xFDFDF8), gold: RGB(0xA59A7B),
                                clay: RGB(0x8093A6), success: RGB(0x48665E))
        case .anansi:
            return ThemePalette(paper: RGB(0xF4EEDF), card: RGB(0xFFF9ED), ink: RGB(0x2D2D49), labels: RGB(0x6B6578),
                                primary: RGB(0x4D456E), onPrimary: RGB(0xFFF9EF), gold: RGB(0xB69A60),
                                clay: RGB(0xB69A60), success: RGB(0x57745F))
        case .koi:
            return ThemePalette(paper: RGB(0xEAF2F7), card: RGB(0xF8FCFF), ink: RGB(0x243F52), labels: RGB(0x567081),
                                primary: RGB(0x34627A), onPrimary: RGB(0xF9FCFF), gold: RGB(0xC09B5D),
                                clay: RGB(0xCA6837), success: RGB(0x416C60))
        case .thoth:
            return ThemePalette(paper: RGB(0xF3ECDC), card: RGB(0xFFF9ED), ink: RGB(0x26384D), labels: RGB(0x626B71),
                                primary: RGB(0x285372), onPrimary: RGB(0xFFF9EC), gold: RGB(0xC4A259),
                                clay: RGB(0xC4A259), success: RGB(0x467263))
        case .dragon:
            return ThemePalette(paper: RGB(0xE8F1EA), card: RGB(0xF7FBF6), ink: RGB(0x253E34), labels: RGB(0x587064),
                                primary: RGB(0x2B644D), onPrimary: RGB(0xF6FCF4), gold: RGB(0xB89A59),
                                clay: RGB(0xAC4B3D), success: RGB(0x346B50))
        case .odin:
            return ThemePalette(paper: RGB(0x111D22), card: RGB(0x1C2B31), ink: RGB(0xEAF1EF), labels: RGB(0xADC1C5),
                                primary: RGB(0xABC4C9), onPrimary: RGB(0x17292F), gold: RGB(0xB99D62),
                                clay: RGB(0xB99D62), success: RGB(0xA5C7AC))
        case .salmon:
            return ThemePalette(paper: RGB(0xECF2EA), card: RGB(0xF8FCF5), ink: RGB(0x2E4035), labels: RGB(0x5E6D5F),
                                primary: RGB(0x456A56), onPrimary: RGB(0xFDFFF7), gold: RGB(0xAC9567),
                                clay: RGB(0xC57F6C), success: RGB(0x3E6C4D))
        case .simurgh:
            return ThemePalette(paper: RGB(0xE8F3F1), card: RGB(0xF5FCFA), ink: RGB(0x21413F), labels: RGB(0x54716C),
                                primary: RGB(0x1F696A), onPrimary: RGB(0xFAFFF7), gold: RGB(0xBA9C57),
                                clay: RGB(0xBA9C57), success: RGB(0x3C7560))
        case .quetzalcoatl:
            return ThemePalette(paper: RGB(0xEAF2EB), card: RGB(0xF8FCF6), ink: RGB(0x1F4238), labels: RGB(0x517165),
                                primary: RGB(0x1F6755), onPrimary: RGB(0xFAFFF6), gold: RGB(0xB49950),
                                clay: RGB(0x7F9A48), success: RGB(0x2E6C4F))
        case .janus:
            return ThemePalette(paper: RGB(0x19191F), card: RGB(0x26262D), ink: RGB(0xF4F0E4), labels: RGB(0xC4BDAE),
                                primary: RGB(0xD7C39B), onPrimary: RGB(0x2C2922), gold: RGB(0xBEA46F),
                                clay: RGB(0xBEA46F), success: RGB(0xB3C4AB))
        case .qilin:
            return ThemePalette(paper: RGB(0xF7EDE3), card: RGB(0xFFF9F2), ink: RGB(0x4C2F28), labels: RGB(0x7F6257),
                                primary: RGB(0xA44332), onPrimary: RGB(0xFFF9F0), gold: RGB(0xC09B54),
                                clay: RGB(0xD1A24D), success: RGB(0x5F704A))
        case .psyche:
            return ThemePalette(paper: RGB(0xF6EDF3), card: RGB(0xFFF8FD), ink: RGB(0x4C3150), labels: RGB(0x7B6380),
                                primary: RGB(0x76517E), onPrimary: RGB(0xFFFAFF), gold: RGB(0xB49B67),
                                clay: RGB(0xB69CC5), success: RGB(0x5D7868))
        case .gaia:
            return ThemePalette(paper: RGB(0xECF1E5), card: RGB(0xF8FBF2), ink: RGB(0x2E4131), labels: RGB(0x5D705D),
                                primary: RGB(0x426849), onPrimary: RGB(0xFDFFF5), gold: RGB(0xB39E60),
                                clay: RGB(0x82A9B2), success: RGB(0x426C4E))
        case .loon:
            return ThemePalette(paper: RGB(0xEDF3F6), card: RGB(0xFBFDFF), ink: RGB(0x283B49), labels: RGB(0x5C7180),
                                primary: RGB(0x3B607D), onPrimary: RGB(0xFCFFFF), gold: RGB(0xADA177),
                                clay: RGB(0xB44E45), success: RGB(0x4E7368))
        case .chiron:
            return ThemePalette(paper: RGB(0x1B2D28), card: RGB(0x283F36), ink: RGB(0xF0F0DF), labels: RGB(0xB7C6B6),
                                primary: RGB(0xCCD7BE), onPrimary: RGB(0x25382C), gold: RGB(0xBBA571),
                                clay: RGB(0xBBA571), success: RGB(0xB1D0AC))
        case .hecate:
            return ThemePalette(paper: RGB(0x201714), card: RGB(0x33221D), ink: RGB(0xF5EADD), labels: RGB(0xC7B3A3),
                                primary: RGB(0xE4A17A), onPrimary: RGB(0x392317), gold: RGB(0xBA965F),
                                clay: RGB(0xD18654), success: RGB(0xC0C6A2))
        case .demeter:
            return ThemePalette(paper: RGB(0xF5EEDB), card: RGB(0xFFF9E9), ink: RGB(0x4C3824), labels: RGB(0x7B684A),
                                primary: RGB(0x8D5D2F), onPrimary: RGB(0xFFFBEE), gold: RGB(0xBE9D52),
                                clay: RGB(0xAD6942), success: RGB(0x697548))
        case .yuleStag:
            return ThemePalette(paper: RGB(0xEFF2E9), card: RGB(0xFAFCF4), ink: RGB(0x2C4035), labels: RGB(0x627064),
                                primary: RGB(0x315B46), onPrimary: RGB(0xFBFFF4), gold: RGB(0xB29B63),
                                clay: RGB(0xA3565E), success: RGB(0x42684F))
        }
    }

    /// The OMO in use. Kept in memory because colours are read many times per screen;
    /// SettingsStore updates it whenever you pick a different OMO.
    static var current: OmoCompanion = SharedStore.settings.companion
}
