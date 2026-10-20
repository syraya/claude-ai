import Foundation
import FamilyControls

/// All the rules for solo focus sessions and friend locks. The app and the monitor
/// extension both call into this, so a session behaves the same whether OMO
/// is open or not.
enum FocusEngine {
    /// Timers can fire a little early or late; this much slack counts as "on time".
    private static let tolerance: TimeInterval = 90

    // MARK: Solo sessions

    static func start(_ session: FocusSession) throws {
        if let old = SharedStore.focusSession {
            ActivityScheduler.cancelTimer(named: TimerName.focusEnd(old.id))
            ActivityScheduler.cancelTimer(named: TimerName.focusBreak(old.id))
        }
        SharedStore.focusSession = session
        ShieldManager.shield(session.selection, in: .focus)
        try ActivityScheduler.scheduleTimer(named: TimerName.focusEnd(session.id), firingAt: session.endsAt)
    }

    /// Starts a break. Call this only after the reflection countdown has finished.
    static func startBreak(minutes: Int) throws {
        guard var session = SharedStore.focusSession, session.canTakeBreak else { return }
        let now = Date()
        let end = min(now.addingTimeInterval(TimeInterval(minutes * 60)), session.endsAt)
        session.breaksTaken += 1
        session.breakStartedAt = now
        session.breakEndsAt = end
        SharedStore.focusSession = session
        SharedStore.updateStats { $0.breaksTaken += 1 }
        ShieldManager.clear(.focus)
        if end < session.endsAt {
            try ActivityScheduler.scheduleTimer(named: TimerName.focusBreak(session.id), firingAt: end)
        }
    }

    /// Ends the current break and turns the blocks back on.
    static func endBreak(notify: Bool = false) {
        guard var session = SharedStore.focusSession, session.isOnBreak else { return }
        let now = Date()
        if let started = session.breakStartedAt {
            session.totalBreakSeconds += max(0, min(now, session.endsAt).timeIntervalSince(started))
        }
        session.breakStartedAt = nil
        session.breakEndsAt = nil
        SharedStore.focusSession = session
        ActivityScheduler.cancelTimer(named: TimerName.focusBreak(session.id))
        guard now < session.endsAt else {
            finish(completed: true, notify: notify)
            return
        }
        ShieldManager.shield(session.selection, in: .focus)
        if notify {
            LocalNotifier.post(title: "Break's over",
                               body: "\(session.blockListName) is blocked again. Back to it 💪",
                               route: .focus)
        }
    }

    /// Ends the session, either because time ran out or because you ended it early.
    static func finish(completed: Bool, notify: Bool = false) {
        guard var session = SharedStore.focusSession else { return }
        let now = Date()
        if let started = session.breakStartedAt {
            session.totalBreakSeconds += max(0, min(now, session.endsAt).timeIntervalSince(started))
            session.breakStartedAt = nil
        }
        let minutes = session.focusedMinutes(at: now)
        SharedStore.updateStats {
            $0.focusMinutes += minutes
            if completed { $0.sessionsCompleted += 1 }
        }
        SharedStore.focusSession = nil
        ShieldManager.clear(.focus)
        ActivityScheduler.cancelTimer(named: TimerName.focusEnd(session.id))
        ActivityScheduler.cancelTimer(named: TimerName.focusBreak(session.id))
        if notify {
            LocalNotifier.post(title: "Session complete 🎉",
                               body: "You focused for \(minutes) minutes. Your apps are unlocked.",
                               route: .focus)
        }
    }

    // MARK: Friend locks

    static func applyFriendLock(_ state: FriendLockState) {
        let settings = SharedStore.settings
        let previous = SharedStore.friendLock
        SharedStore.friendLock = state
        if state.isOnBreak {
            ShieldManager.clear(.friendLock)
            if let end = state.breakEndsAt, previous?.breakEndsAt != end {
                try? ActivityScheduler.scheduleTimer(named: TimerName.friendBreak(state.sessionID), firingAt: end)
            }
        } else {
            ShieldManager.shield(state.selection, in: .friendLock,
                                 preventAppDeletion: settings.preventAppDeletionWhenLocked)
        }
    }

    /// Called when your keyholder unlocks you (or you use the emergency exit).
    static func releaseFriendLock() {
        guard let state = SharedStore.friendLock else {
            ShieldManager.clear(.friendLock)
            return
        }
        let minutes = max(0, Int(Date().timeIntervalSince(state.lockedAt) / 60))
        SharedStore.updateStats {
            $0.focusMinutes += minutes
            $0.friendSessions += 1
        }
        SharedStore.friendLock = nil
        ShieldManager.clear(.friendLock)
        ActivityScheduler.cancelTimer(named: TimerName.friendBreak(state.sessionID))
    }

    // MARK: Timers

    /// Called by the monitor extension when a timer fires, and by the app when it
    /// comes to the foreground, in case a timer was missed.
    static func handleTimer(named name: String) {
        let now = Date()
        if name.hasPrefix(TimerName.focusEndPrefix) {
            guard let session = SharedStore.focusSession,
                  name == TimerName.focusEnd(session.id),
                  now >= session.endsAt.addingTimeInterval(-tolerance) else { return }
            finish(completed: true, notify: true)
        } else if name.hasPrefix(TimerName.focusBreakPrefix) {
            guard let session = SharedStore.focusSession,
                  name == TimerName.focusBreak(session.id),
                  let breakEnd = session.breakEndsAt,
                  now >= breakEnd.addingTimeInterval(-tolerance) else { return }
            endBreak(notify: true)
        } else if name.hasPrefix(TimerName.friendBreakPrefix) {
            guard var state = SharedStore.friendLock,
                  name == TimerName.friendBreak(state.sessionID),
                  let breakEnd = state.breakEndsAt,
                  now >= breakEnd.addingTimeInterval(-tolerance) else { return }
            state.breakEndsAt = nil
            applyFriendLock(state)
            LocalNotifier.post(title: "Break's over",
                               body: "\(state.keyholderName) still has your key. Back to studying 📚",
                               route: .together)
        }
    }

    /// Brings everything up to date. Call whenever the app becomes active.
    static func reconcile() {
        let now = Date()
        if let session = SharedStore.focusSession {
            if now >= session.endsAt {
                finish(completed: true)
            } else if let breakEnd = session.breakEndsAt, now >= breakEnd {
                endBreak()
            } else if !session.isOnBreak {
                // Make sure the shield is really on (e.g. after a phone restart).
                ShieldManager.shield(session.selection, in: .focus)
            }
        } else {
            ShieldManager.clear(.focus)
        }

        if var state = SharedStore.friendLock {
            if let breakEnd = state.breakEndsAt, now >= breakEnd { state.breakEndsAt = nil }
            applyFriendLock(state)
        }
    }

    // MARK: Usage tracking

    static func recordUsageThreshold(eventName: String) {
        guard eventName.hasPrefix(TimerName.usageEventPrefix),
              let minutes = Int(eventName.dropFirst(TimerName.usageEventPrefix.count)) else { return }
        SharedStore.updateStats { $0.distractingMinutes = max($0.distractingMinutes, minutes) }
    }
}
