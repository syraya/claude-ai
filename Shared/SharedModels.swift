import Foundation
import FamilyControls

/// A named set of apps, categories and websites to block, e.g. "Social" or "Games".
struct BlockList: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var emoji: String = "🚫"
    var selection: FamilyActivitySelection = FamilyActivitySelection()

    var appCount: Int { selection.applicationTokens.count }
    var categoryCount: Int { selection.categoryTokens.count }
    var websiteCount: Int { selection.webDomainTokens.count }
    var isEmpty: Bool { appCount + categoryCount + websiteCount == 0 }

    var summary: String {
        var parts: [String] = []
        if appCount > 0 { parts.append("\(appCount) app\(appCount == 1 ? "" : "s")") }
        if categoryCount > 0 { parts.append("\(categoryCount) categor\(categoryCount == 1 ? "y" : "ies")") }
        if websiteCount > 0 { parts.append("\(websiteCount) site\(websiteCount == 1 ? "" : "s")") }
        return parts.isEmpty ? "Nothing selected yet" : parts.joined(separator: " · ")
    }

    static func == (lhs: BlockList, rhs: BlockList) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.emoji == rhs.emoji
            && lhs.selection.applicationTokens == rhs.selection.applicationTokens
            && lhs.selection.categoryTokens == rhs.selection.categoryTokens
            && lhs.selection.webDomainTokens == rhs.selection.webDomainTokens
    }
}

/// A solo focus session running on this phone.
struct FocusSession: Codable, Identifiable {
    var id: UUID = UUID()
    var blockListName: String
    var selection: FamilyActivitySelection
    var startedAt: Date
    var endsAt: Date
    var allowsBreaks: Bool
    var allowsEndingEarly: Bool
    /// `FocusSession.unlimitedBreaks` for no limit.
    var maxBreaks: Int
    var breaksTaken: Int = 0
    var breakStartedAt: Date?
    var breakEndsAt: Date?
    var totalBreakSeconds: TimeInterval = 0
    /// What you're working toward, shown on the timer and the block screen.
    var intention: String?

    static let unlimitedBreaks = Int.max

    var isOnBreak: Bool { breakEndsAt != nil }
    var hasUnlimitedBreaks: Bool { maxBreaks == Self.unlimitedBreaks }
    var breaksLeft: Int { max(0, maxBreaks - breaksTaken) }
    var canTakeBreak: Bool { allowsBreaks && breaksLeft > 0 && !isOnBreak }

    func remaining(at date: Date = Date()) -> TimeInterval { max(0, endsAt.timeIntervalSince(date)) }

    func progress(at date: Date = Date()) -> Double {
        let total = endsAt.timeIntervalSince(startedAt)
        guard total > 0 else { return 1 }
        return min(1, max(0, date.timeIntervalSince(startedAt) / total))
    }

    /// Minutes actually spent focused so far (time on breaks doesn't count).
    func focusedMinutes(at date: Date = Date()) -> Int {
        let end = min(date, endsAt)
        var breakSeconds = totalBreakSeconds
        if let breakStartedAt { breakSeconds += max(0, end.timeIntervalSince(breakStartedAt)) }
        return max(0, Int((end.timeIntervalSince(startedAt) - breakSeconds) / 60))
    }
}

/// This phone's view of a study session with friends, where a friend holds the key.
struct FriendLockState: Codable {
    var sessionID: String
    var keyholderUID: String
    var keyholderName: String
    var selection: FamilyActivitySelection
    var lockedAt: Date
    var breakEndsAt: Date?

    var isOnBreak: Bool {
        guard let breakEndsAt else { return false }
        return breakEndsAt > Date()
    }
}

struct AppSettings: Codable, Equatable {
    /// How long you have to wait on the reflection screen before a break starts.
    var reflectionSeconds: Int = 10
    var defaultBreakMinutes: Int = 5
    /// `FocusSession.unlimitedBreaks` for no limit.
    var maxBreaksPerSession: Int = 3
    var defaultSessionMinutes: Int = 45
    /// While a friend holds your key, iOS won't let you delete apps (including OMO).
    var preventAppDeletionWhenLocked: Bool = true
    var shareScreenTimeWithFriends: Bool = true
    var hasCompletedOnboarding: Bool = false
    /// Your OMO, which also sets the colour theme.
    var companion: OmoCompanion = .glaux

    init() {}

    /// Missing keys fall back to defaults, so adding a setting in an update never
    /// wipes the ones people already saved.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        reflectionSeconds = try c.decodeIfPresent(Int.self, forKey: .reflectionSeconds) ?? d.reflectionSeconds
        defaultBreakMinutes = try c.decodeIfPresent(Int.self, forKey: .defaultBreakMinutes) ?? d.defaultBreakMinutes
        maxBreaksPerSession = try c.decodeIfPresent(Int.self, forKey: .maxBreaksPerSession) ?? d.maxBreaksPerSession
        defaultSessionMinutes = try c.decodeIfPresent(Int.self, forKey: .defaultSessionMinutes) ?? d.defaultSessionMinutes
        preventAppDeletionWhenLocked = try c.decodeIfPresent(Bool.self, forKey: .preventAppDeletionWhenLocked)
            ?? d.preventAppDeletionWhenLocked
        shareScreenTimeWithFriends = try c.decodeIfPresent(Bool.self, forKey: .shareScreenTimeWithFriends)
            ?? d.shareScreenTimeWithFriends
        hasCompletedOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? d.hasCompletedOnboarding
        companion = (try? c.decodeIfPresent(OmoCompanion.self, forKey: .companion)) ?? d.companion
    }

    static let reflectionOptions = [5, 10, 15, 30, 60]
    static let breakOptions = [1, 3, 5, 10, 15]
    /// The stepper goes 1…10, then Unlimited.
    static let maxBreakSteps = 10

    var hasUnlimitedBreaks: Bool { maxBreaksPerSession == FocusSession.unlimitedBreaks }
}

/// One day of numbers, kept on the phone and (if you're signed in) shared with friends.
struct DailyStats: Codable, Equatable, Identifiable {
    var day: String
    var focusMinutes: Int = 0
    var sessionsCompleted: Int = 0
    var breaksTaken: Int = 0
    var friendSessions: Int = 0
    /// Approximate minutes spent in your tracked apps, in 15-minute steps.
    var distractingMinutes: Int = 0

    var id: String { day }

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func key(for date: Date) -> String { dayFormatter.string(from: date) }
    var date: Date? { DailyStats.dayFormatter.date(from: day) }
}
