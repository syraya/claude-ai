import Foundation
import UserNotifications

enum LocalNotifier {
    /// Notification `userInfo["route"]` values the app uses to open the right screen.
    enum Route: String {
        case focus
        case takeBreak
        case together
        case friends
    }

    /// The one "take a break" notification from the block screen. Reused so tapping the
    /// button twice doesn't stack two of them.
    static let shieldBreakID = "omo.shield-break"

    static func post(title: String, body: String, route: Route, delay: TimeInterval = 0.5,
                     identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["route": route.rawValue]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.5, delay), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Clears the block screen's break notification once OMO has opened for it.
    static func clearShieldBreak() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [shieldBreakID])
        center.removeDeliveredNotifications(withIdentifiers: [shieldBreakID])
    }
}
