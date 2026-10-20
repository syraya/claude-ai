import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(FocusController.self) private var focus
    @Environment(SettingsStore.self) private var settings
    @Environment(ScreenTimeAuthorizer.self) private var screenTime
    @Environment(AuthService.self) private var auth
    @Environment(FriendsService.self) private var friends
    @Environment(GroupSessionService.self) private var together
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var router = router

        Group {
            if settings.settings.hasCompletedOnboarding {
                TabView(selection: $router.tab) {
                    FocusHomeView()
                        .tabItem { Label("Focus", systemImage: "moon.stars.fill") }
                        .tag(AppTab.focus)
                    BlockListsView()
                        .tabItem { Label("Block Lists", systemImage: "square.stack.3d.up.fill") }
                        .tag(AppTab.lists)
                    TogetherView()
                        .tabItem { Label("Together", systemImage: "person.2.fill") }
                        .tag(AppTab.together)
                    FriendsView()
                        .tabItem { Label("Friends", systemImage: "heart.fill") }
                        .tag(AppTab.friends)
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                        .tag(AppTab.settings)
                }
                .tint(.lsAccent)
            } else {
                OnboardingView()
            }
        }
        .task { startServices() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: becameActive()
            case .background: AppDelegate.scheduleBackgroundSync()
            default: break
            }
        }
    }

    private func startServices() {
        // Local copies so the closures don't reach back into this view's environment.
        let friends = friends
        let together = together
        let focus = focus
        auth.onUserChanged = { uid, name in
            friends.start(uid: uid, name: name)
            together.start(uid: uid, name: name)
            Task { await StatsSyncService.upload() }
        }
        together.onLocalStateChanged = { focus.refresh() }
        auth.start()
        settings.restartUsageTracking()
        becameActive()
    }

    private func becameActive() {
        screenTime.refresh()
        focus.reconcile()
        router.consumePendingShieldRequest()
        let focus = focus
        let friends = friends
        Task {
            await GroupSessionService.syncFromServer()
            focus.refresh()
            await StatsSyncService.upload()
            await friends.refreshTodayStats()
        }
    }
}
