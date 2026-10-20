import Foundation
import FamilyControls
import ManagedSettings

extension ManagedSettingsStore.Name {
    /// Shields from your own solo focus sessions.
    static let focus = Self("lockstep.focus")
    /// Shields from a study session where a friend holds your key.
    static let friendLock = Self("lockstep.friendLock")
}

/// Turns blocking on and off. Solo sessions and friend locks use separate stores,
/// so ending one never lifts the other.
enum ShieldManager {
    static func shield(_ selection: FamilyActivitySelection,
                       in name: ManagedSettingsStore.Name,
                       preventAppDeletion: Bool = false) {
        let store = ManagedSettingsStore(named: name)
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.application.denyAppRemoval = preventAppDeletion ? true : nil
    }

    static func clear(_ name: ManagedSettingsStore.Name) {
        ManagedSettingsStore(named: name).clearAllSettings()
    }
}
