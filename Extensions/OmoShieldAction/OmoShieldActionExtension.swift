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
            // iOS doesn't let a block screen open an app, so OMO sends a notification
            // that opens straight into the break, and keeps the block screen up with
            // directions (`.defer` makes iOS draw it again).
            if let lock = SharedStore.friendLock {
                SharedStore.pendingShieldRequest = LocalNotifier.Route.together.rawValue
                LocalNotifier.post(title: "Ask \(lock.keyholderName) for a break",
                                   body: "Tap here to open OMO and send the request.",
                                   route: .together, delay: 0.1, timeSensitive: true)
            } else {
                SharedStore.pendingShieldRequest = LocalNotifier.Route.takeBreak.rawValue
                LocalNotifier.post(title: "Your break is ready",
                                   body: "Tap here to open OMO. A short breath first, then choose how long.",
                                   route: .takeBreak, delay: 0.1, timeSensitive: true)
            }
            return .defer
        @unknown default:
            return .close
        }
    }
}
