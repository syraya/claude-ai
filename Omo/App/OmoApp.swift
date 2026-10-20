import SwiftUI

@main
struct OmoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var focus = FocusController()
    @State private var blockLists = BlockListStore()
    @State private var settings = SettingsStore()
    @State private var screenTime = ScreenTimeAuthorizer()
    @State private var auth = AuthService()
    @State private var friends = FriendsService()
    @State private var together = GroupSessionService()

    init() {
        // None of the services above touch Firebase until start() is called, so it's
        // fine that they're created before this runs.
        FirebaseBootstrap.configureIfPossible()
        ThemeAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(AppRouter.shared)
                .environment(focus)
                .environment(blockLists)
                .environment(settings)
                .environment(screenTime)
                .environment(auth)
                .environment(friends)
                .environment(together)
        }
    }
}
