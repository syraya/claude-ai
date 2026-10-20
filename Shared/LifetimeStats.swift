import Foundation

/// Everything you've focused since installing OMO. Unlike the daily stats, which only
/// keep about a month, these totals never reset.
struct LifetimeStats: Codable, Equatable {
    var startedAt = Date()
    var totalFocusMinutes = 0
    var sessionsCompleted = 0
    var friendSessions = 0
    var longestSessionMinutes = 0
    var currentStreak = 0
    var longestStreak = 0
    /// The last day (yyyy-MM-dd) with any focus time, for counting streaks.
    var lastFocusDay: String?
    /// Minutes per month ("2026-10"), for the "over time" chart.
    var monthlyMinutes: [String: Int] = [:]
    /// The highest title (in hours) the app has already celebrated with you.
    var celebratedHours = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        startedAt = try c.decodeIfPresent(Date.self, forKey: .startedAt) ?? Date()
        totalFocusMinutes = try c.decodeIfPresent(Int.self, forKey: .totalFocusMinutes) ?? 0
        sessionsCompleted = try c.decodeIfPresent(Int.self, forKey: .sessionsCompleted) ?? 0
        friendSessions = try c.decodeIfPresent(Int.self, forKey: .friendSessions) ?? 0
        longestSessionMinutes = try c.decodeIfPresent(Int.self, forKey: .longestSessionMinutes) ?? 0
        currentStreak = try c.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try c.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        lastFocusDay = try c.decodeIfPresent(String.self, forKey: .lastFocusDay)
        monthlyMinutes = try c.decodeIfPresent([String: Int].self, forKey: .monthlyMinutes) ?? [:]
        celebratedHours = try c.decodeIfPresent(Int.self, forKey: .celebratedHours) ?? 0
    }

    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    mutating func record(minutes: Int, on date: Date = Date(), completedSession: Bool, friendSession: Bool) {
        guard minutes > 0 || completedSession else { return }
        totalFocusMinutes += max(0, minutes)
        if completedSession { sessionsCompleted += 1 }
        if friendSession { friendSessions += 1 }
        longestSessionMinutes = max(longestSessionMinutes, minutes)
        monthlyMinutes[Self.monthFormatter.string(from: date), default: 0] += max(0, minutes)

        guard minutes > 0 else { return }
        let today = DailyStats.key(for: date)
        guard lastFocusDay != today else { return }
        if let last = lastFocusDay.flatMap({ DailyStats.dayFormatter.date(from: $0) }),
           let todayDate = DailyStats.dayFormatter.date(from: today),
           Calendar.current.dateComponents([.day], from: last, to: todayDate).day == 1 {
            currentStreak += 1
        } else {
            currentStreak = 1
        }
        lastFocusDay = today
        longestStreak = max(longestStreak, currentStreak)
    }

    /// The streak as of today: it only counts if you focused today or yesterday.
    func streak(asOf date: Date = Date()) -> Int {
        guard let last = lastFocusDay.flatMap({ DailyStats.dayFormatter.date(from: $0) }),
              let today = DailyStats.dayFormatter.date(from: DailyStats.key(for: date)),
              let gap = Calendar.current.dateComponents([.day], from: last, to: today).day,
              gap <= 1 else { return 0 }
        return currentStreak
    }

    var daysSinceStart: Int {
        max(1, (Calendar.current.dateComponents([.day], from: startedAt, to: Date()).day ?? 0) + 1)
    }
}
