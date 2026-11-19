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
    /// A break from the schedules blocking now.
    private(set) var scheduleBreak: ScheduleBreak?
    /// The session that just ended, shown as a summary card until you start another.
    private(set) var lastFinished: FinishedSession?
    var errorMessage: String?

    struct FinishedSession: Equatable {
        let id: UUID
        let minutes: Int
        let intention: String?
        let blockListName: String
        /// Ran to the end rather than being ended early.
        let completed: Bool
    }

    init() {
        refresh()
    }

    /// Minutes focused today that aren't saved yet: a session or friend lock that's still
    /// running only adds its time to the stats when it ends. Breaks don't count.
    func runningMinutesToday(at now: Date = Date()) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: now)
        var minutes = 0
        if let session {
            minutes += session.focusedMinutes(at: now)
            if session.startedAt < startOfDay {
                // Only the part since midnight belongs to today.
                minutes -= session.focusedMinutes(at: startOfDay)
            }
        }
        if let lock = friendLock, !lock.isOnBreak {
            minutes += Int(now.timeIntervalSince(max(lock.lockedAt, startOfDay)) / 60)
        }
        // Scheduled blocks that count as focus, minus any overlap with the above.
        let otherStart = session.map { now.addingTimeInterval(-TimeInterval($0.focusedMinutes(at: now) * 60)) }
            ?? friendLock?.lockedAt
        minutes += ScheduleEngine.runningMinutesToday(at: now, alsoCounting: otherStart)
        return max(0, minutes)
    }

    /// Lifetime totals with minutes from a running session added on top.
    func lifetimeIncluding(runningMinutes: Int) -> LifetimeStats {
        var stats = lifetime
        stats.totalFocusMinutes += runningMinutes
        return stats
    }

    func refresh() {
        let previous = session
        session = SharedStore.focusSession
        friendLock = SharedStore.friendLock
        today = SharedStore.stats()
        lifetime = SharedStore.lifetime
        scheduleBreak = ScheduleEngine.currentBreak()
        if let previous, session == nil { noteFinished(previous) }
    }

    /// Keeps a summary of a session that just ended, so the timer can settle into it
    /// instead of vanishing.
    private func noteFinished(_ old: FocusSession) {
        let now = Date()
        // One that ended long ago while OMO sat in the background isn't news any more.
        guard now.timeIntervalSince(min(now, old.endsAt)) < 30 * 60 else { return }
        lastFinished = FinishedSession(id: old.id,
                                       minutes: old.focusedMinutes(at: now),
                                       intention: old.intention,
                                       blockListName: old.blockListName,
                                       completed: now >= old.endsAt.addingTimeInterval(-90))
    }

    func dismissFinished() {
        lastFinished = nil
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
        lastFinished = nil
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

    func startScheduleBreak(minutes: Int) {
        do {
            try ScheduleEngine.startBreak(minutes: minutes)
        } catch {
            errorMessage = "Your break started, but iOS wouldn't schedule its end. Open OMO when it's over to block again."
        }
        refresh()
    }

    func endScheduleBreak() {
        ScheduleEngine.endBreak()
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

    /// Called every second while a session or schedule is on screen.
    func tick() {
        let now = Date()
        if let session, now >= session.endsAt || (session.breakEndsAt.map { now >= $0 } ?? false) {
            reconcile()
        } else if let scheduleBreak, now >= scheduleBreak.endsAt {
            reconcile()
        }
    }
}
