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

    static func post(title: String, body: String, route: Route, delay: TimeInterval = 0.5) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["route": route.rawValue]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.5, delay), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
