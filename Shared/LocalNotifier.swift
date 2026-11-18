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

    /// `timeSensitive` notifications show even during a Focus mode; use them only for
    /// something you just asked for, like the break you tapped on the block screen.
    static func post(title: String, body: String, route: Route, delay: TimeInterval = 0.5,
                     timeSensitive: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["route": route.rawValue]
        if timeSensitive {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.5, delay), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
