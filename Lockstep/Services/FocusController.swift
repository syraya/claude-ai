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
    var errorMessage: String?

    init() {
        refresh()
    }

    func refresh() {
        session = SharedStore.focusSession
        friendLock = SharedStore.friendLock
        today = SharedStore.stats()
    }

    /// Catches up on any timers that fired while the app was closed.
    func reconcile() {
        FocusEngine.reconcile()
        refresh()
    }

    func start(blockList: BlockList, minutes: Int, allowsBreaks: Bool, allowsEndingEarly: Bool, maxBreaks: Int) {
        let now = Date()
        let session = FocusSession(
            blockListName: blockList.name,
            selection: blockList.selection,
            startedAt: now,
            endsAt: now.addingTimeInterval(TimeInterval(minutes * 60)),
            allowsBreaks: allowsBreaks,
            allowsEndingEarly: allowsEndingEarly,
            maxBreaks: allowsBreaks ? maxBreaks : 0
        )
        do {
            try FocusEngine.start(session)
        } catch {
            // Blocking is already on; only the background "end" timer failed.
            // The app still ends the session on time whenever it's opened.
            errorMessage = "Your session started, but iOS wouldn't schedule the end timer. Open Lockstep when time's up to unlock."
        }
        refresh()
    }

    func startBreak(minutes: Int) {
        do {
            try FocusEngine.startBreak(minutes: minutes)
        } catch {
            errorMessage = "Your break started, but the reminder to come back couldn't be scheduled. Open Lockstep to end it."
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

    /// Called every second while a session is on screen.
    func tick() {
        guard let session else { return }
        let now = Date()
        if now >= session.endsAt || (session.breakEndsAt.map { now >= $0 } ?? false) {
            reconcile()
        }
    }
}
