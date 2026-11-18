import ManagedSettings
import Foundation

/// Handles taps on the block screen's buttons. iOS doesn't let a shield open the
/// app directly, so "Take a break" sends a notification that opens OMO at the
/// reflection screen.
final class OmoShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    private func respond(to action: ShieldAction) -> ShieldActionResponse {
        switch action {
        case .primaryButtonPressed:
            // Changed your mind: forget any break you asked for.
            SharedStore.pendingShieldRequest = nil
            return .close
        case .secondaryButtonPressed:
            // iOS doesn't let a block screen open an app. Instead OMO remembers the
            // request, so opening OMO goes straight into the break, and keeps the block
            // screen up saying so (`.defer` makes iOS draw it again).
            SharedStore.pendingShieldRequest = (SharedStore.friendLock != nil
                ? LocalNotifier.Route.together : LocalNotifier.Route.takeBreak).rawValue
            return .defer
        @unknown default:
            return .close
        }
    }
}
