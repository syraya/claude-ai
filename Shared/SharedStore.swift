import Foundation
import FamilyControls

/// Storage shared between the app and its extensions through the App Group.
/// The extensions run in separate processes, so everything they need lives here.
enum SharedStore {
    static let appGroupID: String =
        Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String ?? "group.com.example.omo"

    private static var defaults: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }

    private enum Key {
        static let blockLists = "blockLists"
        static let focusSession = "focusSession"
        static let friendLock = "friendLock"
        static let settings = "settings"
        static let dailyStats = "dailyStats"
        static let trackedSelection = "trackedSelection"
        static let pendingShieldRequest = "pendingShieldRequest"
    }

    private static func read<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func write<T: Encodable>(_ value: T?, _ key: String) {
        if let value, let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    static var blockLists: [BlockList] {
        get { read([BlockList].self, Key.blockLists) ?? [] }
        set { write(newValue, Key.blockLists) }
    }

    static var focusSession: FocusSession? {
        get { read(FocusSession.self, Key.focusSession) }
        set { write(newValue, Key.focusSession) }
    }

    static var friendLock: FriendLockState? {
        get { read(FriendLockState.self, Key.friendLock) }
        set { write(newValue, Key.friendLock) }
    }

    static var settings: AppSettings {
        get { read(AppSettings.self, Key.settings) ?? AppSettings() }
        set { write(newValue, Key.settings) }
    }

    /// Apps whose daily usage is counted and shared with friends.
    static var trackedSelection: FamilyActivitySelection? {
        get { read(FamilyActivitySelection.self, Key.trackedSelection) }
        set { write(newValue, Key.trackedSelection) }
    }

    /// Set by the shield's "Take a break" button so the app opens straight to it.
    static var pendingShieldRequest: String? {
        get { defaults.string(forKey: Key.pendingShieldRequest) }
        set { defaults.set(newValue, forKey: Key.pendingShieldRequest) }
    }

    // MARK: Daily stats

    static var dailyStats: [String: DailyStats] {
        get { read([String: DailyStats].self, Key.dailyStats) ?? [:] }
        set { write(newValue, Key.dailyStats) }
    }

    static func stats(for date: Date = Date()) -> DailyStats {
        let key = DailyStats.key(for: date)
        return dailyStats[key] ?? DailyStats(day: key)
    }

    static func updateStats(for date: Date = Date(), _ change: (inout DailyStats) -> Void) {
        let key = DailyStats.key(for: date)
        var all = dailyStats
        var today = all[key] ?? DailyStats(day: key)
        change(&today)
        all[key] = today
        // Keep about a month of history.
        if all.count > 35 {
            for old in all.keys.sorted().prefix(all.count - 35) { all.removeValue(forKey: old) }
        }
        dailyStats = all
    }

    static func recentStats(days: Int) -> [DailyStats] {
        let calendar = Calendar.current
        let all = dailyStats
        return (0..<days).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let key = DailyStats.key(for: date)
            return all[key] ?? DailyStats(day: key)
        }
    }
}
