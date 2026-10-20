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
            return .close
        case .secondaryButtonPressed:
            if let lock = SharedStore.friendLock {
                SharedStore.pendingShieldRequest = LocalNotifier.Route.together.rawValue
                LocalNotifier.post(title: "Ask \(lock.keyholderName) for a break",
                                   body: "Tap to open OMO and send the request.",
                                   route: .together)
            } else {
                SharedStore.pendingShieldRequest = LocalNotifier.Route.takeBreak.rawValue
                LocalNotifier.post(title: "Want a break?",
                                   body: "Tap to open OMO. Take a breath first 🌿",
                                   route: .takeBreak)
            }
            return .close
        @unknown default:
            return .close
        }
    }
}
