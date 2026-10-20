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

    init() {
        lists = SharedStore.blockLists
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
    }

    func delete(_ list: BlockList) {
        lists.removeAll { $0.id == list.id }
        SharedStore.blockLists = lists
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
        try? ActivityScheduler.startUsageTracking(for: trackedSelection)
    }
}
