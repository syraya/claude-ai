import Foundation
import FamilyControls
import Observation

/// The app's window onto FocusEngine. Views read `session` and `friendLock` and
/// call these methods; the engine does the actual blocking.
@Observable @MainActor
final class FocusController {
    private(set) var session: FocusSession?
    private(set) var friendLock: FriendLockState?
    private(set) var today = DailyStats(day: DailyStats.key(for: Date()))
    private(set) var lifetime = LifetimeStats()
    var errorMessage: String?

    init() {
        refresh()
    }

    func refresh() {
        session = SharedStore.focusSession
        friendLock = SharedStore.friendLock
        today = SharedStore.stats()
        lifetime = SharedStore.lifetime
    }

    /// Catches up on any timers that fired while the app was closed.
    func reconcile() {
        FocusEngine.reconcile()
        refresh()
    }

    func start(blockList: BlockList, minutes: Int, allowsBreaks: Bool, allowsEndingEarly: Bool,
               maxBreaks: Int, intention: String) {
        let now = Date()
        let session = FocusSession(
            blockListName: blockList.name,
            selection: blockList.selection,
            startedAt: now,
            endsAt: now.addingTimeInterval(TimeInterval(minutes * 60)),
            allowsBreaks: allowsBreaks,
            allowsEndingEarly: allowsEndingEarly,
            maxBreaks: allowsBreaks ? maxBreaks : 0,
            intention: intention.isEmpty ? nil : String(intention.prefix(80))
        )
        do {
            try FocusEngine.start(session)
        } catch {
            // Blocking is already on; only the background "end" timer failed.
            // The app still ends the session on time whenever it's opened.
            errorMessage = "Your session started, but iOS wouldn't schedule the end timer. Open OMO when time's up to unlock."
        }
        refresh()
    }

    func startBreak(minutes: Int) {
        do {
            try FocusEngine.startBreak(minutes: minutes)
        } catch {
            errorMessage = "Your break started, but the reminder to come back couldn't be scheduled. Open OMO to end it."
        }
        refresh()
    }

    func endBreak() {
        FocusEngine.endBreak()
        refresh()
    }

    func endEarly() {
        FocusEngine.finish(completed: false)
        refresh()
    }

    /// An OMO that has joined you since the app last celebrated one, if any.
    var uncelebratedCompanion: OmoCompanion? {
        // The developer code unlocks everything at once; don't celebrate each one.
        guard !lifetime.developerAccess else { return nil }
        return OmoCompanion.allCases.first {
            $0.unlock != .free && $0.isUnlocked(lifetime) && !lifetime.hasCelebrated($0)
        }
    }

    func setDeveloperAccess(_ isOn: Bool) {
        SharedStore.updateLifetime { $0.developerAccess = isOn }
        refresh()
    }

    func markCelebrated(_ companion: OmoCompanion) {
        SharedStore.updateLifetime {
            if !$0.celebratedCompanions.contains(companion.rawValue) { $0.celebratedCompanions.append(companion.rawValue) }
            if let hours = companion.requiredHours { $0.celebratedHours = max($0.celebratedHours, hours) }
        }
        refresh()
    }

    /// Holidays happening today whose OMO you haven't earned yet.
    var holidayToEarn: (holiday: OmoHoliday, companion: OmoCompanion)? {
        for holiday in OmoHoliday.active() where !lifetime.earnedHolidays.contains(holiday.rawValue) {
            if let companion = OmoCompanion.allCases.first(where: { $0.unlock == .holiday(holiday) }) {
                return (holiday, companion)
            }
        }
        return nil
    }

    /// Called every second while a session is on screen.
    func tick() {
        guard let session else { return }
        let now = Date()
        if now >= session.endsAt || (session.breakEndsAt.map { now >= $0 } ?? false) {
            reconcile()
        }
    }
}
