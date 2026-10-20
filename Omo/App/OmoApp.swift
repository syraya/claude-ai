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
        Self.styleNavigationBars()
    }

    /// Serif navigation titles in indigo ink, to match the rest of OMO.
    private static func styleNavigationBars() {
        let ink = UIColor(Color.omoInk)
        func serif(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: serif(34, .bold), .foregroundColor: ink]
        appearance.titleTextAttributes = [.font: serif(17, .semibold), .foregroundColor: ink]
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
                .preferredColorScheme(.light)
        }
    }
}
