import Foundation

/// Titles you earn as your lifetime focus grows, borrowed from the Renaissance
/// guilds, where an apprentice worked their way up to master.
struct FocusRank: Identifiable, Equatable {
    let title: String
    let hours: Int
    let motto: String

    var id: String { title }

    /// The theme this title unlocks.
    var theme: OmoTheme { OmoTheme.allCases.first { $0.requiredHours == hours } ?? .fresco }

    static let all = [
        FocusRank(title: "Novice", hours: 0, motto: "Every master was once a beginner."),
        FocusRank(title: "Apprentice", hours: 10, motto: "You've started learning the craft."),
        FocusRank(title: "Scholar", hours: 50, motto: "Focus is turning into a habit."),
        FocusRank(title: "Journeyman", hours: 100, motto: "A hundred hours of real work."),
        FocusRank(title: "Master", hours: 500, motto: "Few people ever focus this much."),
        FocusRank(title: "Maestro", hours: 1_000, motto: "A thousand hours of deep thought."),
        FocusRank(title: "Sage", hours: 5_000, motto: "Wisdom, built one session at a time."),
        FocusRank(title: "Polymath", hours: 10_000, motto: "Ten thousand hours: the mark of true mastery."),
    ]

    static func current(forMinutes minutes: Int) -> FocusRank {
        all.last { minutes >= $0.hours * 60 } ?? all[0]
    }

    static func next(after rank: FocusRank) -> FocusRank? {
        guard let index = all.firstIndex(of: rank), index + 1 < all.count else { return nil }
        return all[index + 1]
    }

    /// 0...1 progress from `rank` toward the next one.
    static func progress(minutes: Int, from rank: FocusRank) -> Double {
        guard let next = next(after: rank) else { return 1 }
        let span = Double((next.hours - rank.hours) * 60)
        return min(1, max(0, Double(minutes - rank.hours * 60) / span))
    }
}


extension FocusRank {
    /// Titles reached by going from `oldMinutes` to `newMinutes` of lifetime focus.
    static func reached(from oldMinutes: Int, to newMinutes: Int) -> [FocusRank] {
        all.filter { $0.hours > 0 && oldMinutes < $0.hours * 60 && newMinutes >= $0.hours * 60 }
    }
}
