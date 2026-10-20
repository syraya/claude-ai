import UIKit
import BackgroundTasks
import UserNotifications
import FirebaseMessaging

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    static var syncTaskID: String { (Bundle.main.bundleIdentifier ?? "omo") + ".sync" }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        if FirebaseBootstrap.isConfigured {
            Messaging.messaging().delegate = self
            application.registerForRemoteNotifications()
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.syncTaskID, using: nil) { task in
            Self.handleBackgroundSync(task)
        }
        return true
    }

    // MARK: Push

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        PushService.shared.tokenChanged(fcmToken)
    }

    /// Silent pushes from the Cloud Functions ("you've been unlocked", "session
    /// started") wake the app here so it can update the shields right away.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        Task {
            await GroupSessionService.syncFromServer()
            await StatsSyncService.upload()
            completionHandler(.newData)
        }
    }

    // MARK: Notifications

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Task { await GroupSessionService.syncFromServer() }
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        if let raw = info["route"] as? String, let route = LocalNotifier.Route(rawValue: raw) {
            Task { @MainActor in AppRouter.shared.open(route) }
        }
        completionHandler()
    }

    // MARK: Background refresh

    static func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: syncTaskID)
        request.earliestBeginDate = Date().addingTimeInterval(30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleBackgroundSync(_ task: BGTask) {
        scheduleBackgroundSync()
        let work = Task {
            FocusEngine.reconcile()
            await GroupSessionService.syncFromServer()
            await StatsSyncService.upload()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { work.cancel() }
    }
}
