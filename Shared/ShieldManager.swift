import Foundation
import FamilyControls
import ManagedSettings

extension ManagedSettingsStore.Name {
    /// Shields from your own solo focus sessions.
    static let focus = Self("omo.focus")
    /// Shields from a study session where a friend holds your key.
    static let friendLock = Self("omo.friendLock")
}

/// Turns blocking on and off. Solo sessions and friend locks use separate stores,
/// so ending one never lifts the other.
enum ShieldManager {
    /// The app sets this at launch so Screen Time writes, which wait on iOS, never hold
    /// up the interface (ending a session used to stutter on them). They run in order
    /// on this one serial queue. Extensions leave it nil and write straight away,
    /// because iOS may suspend them the moment they return.
    nonisolated(unsafe) static var queue: DispatchQueue?

    private static func perform(_ work: @escaping () -> Void) {
        if let queue { queue.async(execute: work) } else { work() }
    }

    static func shield(_ selection: FamilyActivitySelection,
                       in name: ManagedSettingsStore.Name,
                       preventAppDeletion: Bool = false) {
        perform { apply(selection, in: name, preventAppDeletion: preventAppDeletion) }
    }

    private static func apply(_ selection: FamilyActivitySelection,
                              in name: ManagedSettingsStore.Name,
                              preventAppDeletion: Bool) {
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
        perform { ManagedSettingsStore(named: name).clearAllSettings() }
    }
}
