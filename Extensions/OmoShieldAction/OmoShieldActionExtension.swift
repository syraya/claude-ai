import ManagedSettings
import Foundation

/// Handles taps on the block screen's buttons. iOS doesn't let a shield open the
/// app directly, so "Take a break" sends a notification that opens OMO at the
/// breath screen. Opening OMO yourself does the same.
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
            // request and sends a notification: tapping it (or just opening OMO) goes
            // straight into the break. The block screen stays up saying so (`.defer`
            // makes iOS draw it again).
            let together = SharedStore.friendLock != nil
            let route: LocalNotifier.Route = together ? .together : .takeBreak
            SharedStore.pendingShieldRequest = route.rawValue
            if together {
                LocalNotifier.post(title: "Ask your circle for a break",
                                   body: "Tap to open OMO and send the request.",
                                   route: route, delay: 0.1, identifier: LocalNotifier.shieldBreakID)
            } else {
                LocalNotifier.post(title: "Your break is ready",
                                   body: "Tap to open OMO. A short breath first, then choose how long.",
                                   route: route, delay: 0.1, identifier: LocalNotifier.shieldBreakID)
            }
            return .defer
        @unknown default:
            return .close
        }
    }
}
