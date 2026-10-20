import Foundation
import Observation

enum AppTab: Hashable {
    case focus, lists, together, friends, settings
}

/// Which tab is showing, and whether to jump straight into the break flow.
/// Notifications and the shield's buttons steer the app through this.
@Observable @MainActor
final class AppRouter {
    static let shared = AppRouter()

    var tab: AppTab = .focus
    var wantsBreak = false

    func open(_ route: LocalNotifier.Route) {
        switch route {
        case .focus:
            tab = .focus
        case .takeBreak:
            tab = .focus
            wantsBreak = true
        case .together:
            tab = .together
        case .friends:
            tab = .friends
        }
    }

    /// Picks up a tap on the shield's "Take a break" button.
    func consumePendingShieldRequest() {
        guard let raw = SharedStore.pendingShieldRequest else { return }
        SharedStore.pendingShieldRequest = nil
        if let route = LocalNotifier.Route(rawValue: raw) { open(route) }
    }
}
