import Foundation
import FamilyControls
import Observation

/// Screen Time permission. OMO can't block anything until this is approved.
@Observable @MainActor
final class ScreenTimeAuthorizer {
    private(set) var status: AuthorizationStatus = AuthorizationCenter.shared.authorizationStatus
    var errorMessage: String?

    var isApproved: Bool { status == .approved }

    func request() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            errorMessage = "Screen Time access wasn't granted. You can try again, or turn it on in Settings › Screen Time."
        }
        refresh()
    }

    func refresh() {
        status = AuthorizationCenter.shared.authorizationStatus
    }
}

@Observable @MainActor
final class BlockListStore {
    private(set) var lists: [BlockList]
    private(set) var schedules: [BlockSchedule]
    /// Set when iOS refuses a schedule.
    var scheduleError: String?

    init() {
        lists = SharedStore.blockLists
        schedules = SharedStore.schedules
    }

    func list(id: UUID?) -> BlockList? {
        guard let id else { return nil }
        return lists.first { $0.id == id }
    }

    func save(_ list: BlockList) {
        if let index = lists.firstIndex(where: { $0.id == list.id }) {
            lists[index] = list
        } else {
            lists.append(list)
        }
        SharedStore.blockLists = lists
        // A schedule blocking this list right now picks up the change.
        ScheduleEngine.reconcile()
    }

    func delete(_ list: BlockList) {
        lists.removeAll { $0.id == list.id }
        SharedStore.blockLists = lists
        ScheduleEngine.reconcile()
    }

    // MARK: Schedules

    var canAddSchedule: Bool { schedules.count < ScheduleEngine.maxSchedules }

    func save(_ schedule: BlockSchedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
        } else {
            schedules.append(schedule)
        }
        syncSchedules()
    }

    func delete(_ schedule: BlockSchedule) {
        schedules.removeAll { $0.id == schedule.id }
        ScheduleEngine.remove(schedule)
        syncSchedules()
    }

    func setEnabled(_ schedule: BlockSchedule, _ isEnabled: Bool) {
        var changed = schedule
        changed.isEnabled = isEnabled
        save(changed)
    }

    private func syncSchedules() {
        SharedStore.schedules = schedules
        ScheduleEngine.sync { [weak self] error in
            guard error != nil else { return }
            self?.scheduleError = "iOS wouldn't set up one of your schedules, so it may not turn on by itself. Opening OMO during the block still turns it on."
        }
    }
}

@Observable @MainActor
final class SettingsStore {
    var settings: AppSettings {
        didSet {
            SharedStore.settings = settings
            if settings.companion != oldValue.companion {
                OmoCompanion.current = settings.companion
                ThemeAppearance.apply()
            }
        }
    }

    /// An OMO you've just picked that's still arriving. RootView plays the transition
    /// and swaps the theme while the screen is covered.
    var arrivingCompanion: OmoCompanion?

    /// Switch OMOs with a transition instead of snapping to the new theme.
    func switchCompanion(to companion: OmoCompanion) {
        guard companion != settings.companion, arrivingCompanion == nil else { return }
        arrivingCompanion = companion
    }

    /// The apps whose daily time friends can see.
    var trackedSelection: FamilyActivitySelection {
        didSet {
            SharedStore.trackedSelection = trackedSelection
            restartUsageTracking()
        }
    }

    init() {
        settings = SharedStore.settings
        trackedSelection = SharedStore.trackedSelection ?? FamilyActivitySelection()
    }

    var tracksAnything: Bool {
        !(trackedSelection.applicationTokens.isEmpty
          && trackedSelection.categoryTokens.isEmpty
          && trackedSelection.webDomainTokens.isEmpty)
    }

    func restartUsageTracking() {
        let selection = trackedSelection
        ActivityScheduler.queue.async { try? ActivityScheduler.startUsageTracking(for: selection) }
    }
}
