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
    case glaux, selene, sphinx, nyx, hippocampus, phoenix, pegasus, apollo, athena, huginnMuninn, anansi, koi, thoth, dragon, odin, salmon, simurgh, quetzalcoatl, janus, qilin, psyche, gaia, loon, chiron, hecate, demeter, yuleStag

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
        case .selene, .nyx, .odin, .janus, .chiron, .hecate: return true
        default: return false
        }
    }

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
        case .huginnMuninn:
            return ThemePalette(paper: RGB(0xEEF0F2), card: RGB(0xFFFFFF), ink: RGB(0x1E232B),
                                primary: RGB(0x2F3A4A), gold: RGB(0x8FA6BC), clay: RGB(0x6B5A48),
                                success: RGB(0x5E8C7E), blush: RGB(0xB8C4CF))
        case .anansi:
            return ThemePalette(paper: RGB(0xF7EFE2), card: RGB(0xFFFDF8), ink: RGB(0x2A2140),
                                primary: RGB(0x2E3A6E), gold: RGB(0xD9A13B), clay: RGB(0xA4462B),
                                success: RGB(0x5C8A4E), blush: RGB(0xE3B98A))
        case .koi:
            return ThemePalette(paper: RGB(0xEEF5F7), card: RGB(0xFFFFFF), ink: RGB(0x1F3440),
                                primary: RGB(0x2C6E8F), gold: RGB(0xE8803A), clay: RGB(0xC4521E),
                                success: RGB(0x4F9A86), blush: RGB(0xF2B999))
        case .thoth:
            return ThemePalette(paper: RGB(0xF4ECDC), card: RGB(0xFFFCF4), ink: RGB(0x1E2A3A),
                                primary: RGB(0x1F4E79), gold: RGB(0xC9A04A), clay: RGB(0xA65A2E),
                                success: RGB(0x2F8F86), blush: RGB(0xE2C79A))
        case .dragon:
            return ThemePalette(paper: RGB(0xEEF4EF), card: RGB(0xFFFFFF), ink: RGB(0x1C2B24),
                                primary: RGB(0x1F6B52), gold: RGB(0xD9A33A), clay: RGB(0xB5302A),
                                success: RGB(0x3E8E62), blush: RGB(0xE7B9A0))
        case .odin:
            return ThemePalette(paper: RGB(0x0F1418), card: RGB(0x1A2128), ink: RGB(0xE6ECF2),
                                primary: RGB(0x5F8DB5), gold: RGB(0xC9A45C), clay: RGB(0xB0644A),
                                success: RGB(0x6FAF98), blush: RGB(0x3A4A5E))
        case .salmon:
            return ThemePalette(paper: RGB(0xEEF3EC), card: RGB(0xFFFFFF), ink: RGB(0x223127),
                                primary: RGB(0x3D6B4F), gold: RGB(0xE3A94A), clay: RGB(0xD9785B),
                                success: RGB(0x5C9C6E), blush: RGB(0xF0B8A0))
        case .simurgh:
            return ThemePalette(paper: RGB(0xF2F7F6), card: RGB(0xFFFFFF), ink: RGB(0x17363A),
                                primary: RGB(0x1E7F86), gold: RGB(0xD4A645), clay: RGB(0x9C3D54),
                                success: RGB(0x3E9A7A), blush: RGB(0xE6BFC8))
        case .quetzalcoatl:
            return ThemePalette(paper: RGB(0xEFF6F0), card: RGB(0xFFFFFF), ink: RGB(0x1A2F25),
                                primary: RGB(0x1E7A5A), gold: RGB(0xD9A53A), clay: RGB(0xC2502E),
                                success: RGB(0x2E9E6E), blush: RGB(0xE8C08A))
        case .janus:
            return ThemePalette(paper: RGB(0x14121C), card: RGB(0x211E2C), ink: RGB(0xF2EAD8),
                                primary: RGB(0xA8843A), gold: RGB(0xE8CF8A), clay: RGB(0xB07A5A),
                                success: RGB(0x7FB59E), blush: RGB(0x4A3F5E))
        case .qilin:
            return ThemePalette(paper: RGB(0xFBEFE6), card: RGB(0xFFFCF8), ink: RGB(0x3A1A14),
                                primary: RGB(0xB8322A), gold: RGB(0xD9A23A), clay: RGB(0x7A2E1E),
                                success: RGB(0x4F8A5A), blush: RGB(0xF2B8A0))
        case .psyche:
            return ThemePalette(paper: RGB(0xFBEFF3), card: RGB(0xFFFFFF), ink: RGB(0x3A2238),
                                primary: RGB(0x8A4B8F), gold: RGB(0xD9A65A), clay: RGB(0xB5566E),
                                success: RGB(0x5C9C8A), blush: RGB(0xE6C2E8))
        case .gaia:
            return ThemePalette(paper: RGB(0xF0F5EC), card: RGB(0xFFFFFF), ink: RGB(0x1F2E1E),
                                primary: RGB(0x2F6B3A), gold: RGB(0xC9A04A), clay: RGB(0x7A5A3A),
                                success: RGB(0x4F9A5A), blush: RGB(0xBFD9A8))
        case .loon:
            return ThemePalette(paper: RGB(0xFFFFFF), card: RGB(0xF8F6F3), ink: RGB(0x1A1A1A),
                                primary: RGB(0xD52B1E), gold: RGB(0xB8862E), clay: RGB(0x1F4E79),
                                success: RGB(0x4F8A6E), blush: RGB(0xF4C4BE))
        case .chiron:
            return ThemePalette(paper: RGB(0x22332B), card: RGB(0x2B3F35), ink: RGB(0xF1EEE4),
                                primary: RGB(0x4E8A6C), gold: RGB(0xE9D58C), clay: RGB(0xE39A7A),
                                success: RGB(0x8FC9A8), blush: RGB(0x3E5A4A))
        case .hecate:
            return ThemePalette(paper: RGB(0x140D0A), card: RGB(0x221713), ink: RGB(0xF2E6D8),
                                primary: RGB(0xC8661C), gold: RGB(0xF2B84B), clay: RGB(0xA04AC9),
                                success: RGB(0x7FB59E), blush: RGB(0x5A2E1A))
        case .demeter:
            return ThemePalette(paper: RGB(0xFAF1E1), card: RGB(0xFFFCF5), ink: RGB(0x3A2614),
                                primary: RGB(0x8A5A22), gold: RGB(0xD9A13B), clay: RGB(0xB5432C),
                                success: RGB(0x6E7F45), blush: RGB(0xE8C79A))
        case .yuleStag:
            return ThemePalette(paper: RGB(0xF4F7F5), card: RGB(0xFFFFFF), ink: RGB(0x1A2B22),
                                primary: RGB(0x1F5A3E), gold: RGB(0xD4A23A), clay: RGB(0xB5302A),
                                success: RGB(0x3E8E62), blush: RGB(0xE8B4B0))
        }
    }

    /// The OMO in use. Kept in memory because colours are read many times per screen;
    /// SettingsStore updates it whenever you pick a different OMO.
    static var current: OmoCompanion = SharedStore.settings.companion
}
