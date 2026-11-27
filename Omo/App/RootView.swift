import SwiftUI
import UserNotifications

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(FocusController.self) private var focus
    @Environment(SettingsStore.self) private var settings
    @Environment(ScreenTimeAuthorizer.self) private var screenTime
    @Environment(AuthService.self) private var auth
    @Environment(FriendsService.self) private var friends
    @Environment(GroupSessionService.self) private var together
    @Environment(\.scenePhase) private var scenePhase
    /// The opening plays once each time OMO launches (not in screenshot demos).
    /// Skipped when you're opening OMO to take a break from the block screen.
    @State private var showIntro = !ScreenshotDemo.isActive && SharedStore.pendingShieldRequest == nil

    var body: some View {
        @Bindable var router = router

        Group {
            if let demo = demoScreen {
                demo
            } else if settings.settings.hasCompletedOnboarding {
                TabView(selection: $router.tab) {
                    FocusHomeView()
                        .tabArrival()
                        .tabItem { Label("Focus", systemImage: "building.columns.fill") }
                        .tag(AppTab.focus)
                    BlockListsView()
                        .tabArrival()
                        .tabItem { Label("Block Lists", systemImage: "square.stack.3d.up.fill") }
                        .tag(AppTab.lists)
                    TogetherView()
                        .tabArrival()
                        .tabItem { Label("Circle", systemImage: "person.3.fill") }
                        .tag(AppTab.together)
                    FriendsView()
                        .tabArrival()
                        .tabItem { Label("Friends", systemImage: "heart.fill") }
                        .tag(AppTab.friends)
                    SettingsView()
                        .tabArrival()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                        .tag(AppTab.settings)
                }
                .tint(.omoPrimary)
            } else {
                OnboardingView()
            }
        }
        // Colours come from your OMO, so rebuild everything when you pick a different one.
        .id(settings.settings.companion)
        .sheet(isPresented: $router.showOmoGallery) {
            OmoCollectionView(selected: settings.settings.companion, stats: focus.lifetime) { companion in
                settings.switchCompanion(to: companion)
            }
        }
        .preferredColorScheme(settings.settings.companion.isDark ? .dark : .light)
        .overlay {
            // Sits outside the .id above, so it keeps playing while the screens are rebuilt.
            if let arriving = settings.arrivingCompanion {
                CompanionTransitionView(companion: arriving,
                                        onCovered: { settings.settings.companion = arriving },
                                        onFinished: { settings.arrivingCompanion = nil })
            }
        }
        .overlay {
            if showIntro {
                IntroView { showIntro = false }
                    .transition(.identity)
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
            ModerationService.shared.start(uid: uid)
            friends.start(uid: uid, name: name)
            together.start(uid: uid, name: name)
            Task { await StatsSyncService.upload() }
        }
        together.onLocalStateChanged = { focus.refresh() }
        friends.onFriendCountChanged = { focus.refresh() }
        auth.start()
        settings.restartUsageTracking()
        becameActive()
        ScreenshotDemo.route(router)
    }

    /// Screens that aren't tabs, opened directly for simulator screenshots.
    private var demoScreen: AnyView? {
        switch ScreenshotDemo.screen {
        case "session":
            return AnyView(NavigationStack {
                ScrollView { ActiveSessionView().padding() }
                    .background(OmoBackground())
                    .navigationTitle("Focus")
            })
        case "ended":
            return AnyView(NavigationStack {
                ScrollView {
                    if let finished = focus.lastFinished { SessionSummaryCard(finished: finished).padding() }
                }
                .background(OmoBackground())
                .navigationTitle("Focus")
            })
        case "scheduled":
            return AnyView(NavigationStack {
                ScrollView { ScheduleFocusView().padding() }
                    .background(OmoBackground())
                    .navigationTitle("Focus")
            })
        case "lifetime":
            return AnyView(NavigationStack { LifetimeView() })
        case "omos-sheet":
            return AnyView(OmoBackground().sheet(isPresented: .constant(true)) {
                OmoCollectionView(selected: settings.settings.companion, stats: focus.lifetime) { _ in }
            })
        case "demo-mode":
            return AnyView(DemoModeView())
        case "live":
            return AnyView(LiveActivityPreview(companion: settings.settings.companion))
        case "omos-preview":
            return AnyView(OmoCollectionView(selected: settings.settings.companion, stats: focus.lifetime,
                                             previewing: .selene) { _ in })
        case "omo-index":
            return AnyView(NavigationStack {
                OmoIndexView(selected: settings.settings.companion, stats: focus.lifetime,
                             palette: settings.settings.companion.palette, onClose: {}, onOpen: { _ in })
            })
        case "omos":
            return AnyView(OmoCollectionView(selected: settings.settings.companion, stats: focus.lifetime) { _ in })
        default:
            return nil
        }
    }

    private func becameActive() {
        screenTime.refresh()
        ScheduleEngine.registerMissingInBackground()
        // Break notifications from the block screen need this. Onboarding asks, but
        // it can be skipped; this asks once, and never again after an answer.
        UNUserNotificationCenter.current().getNotificationSettings { current in
            guard current.authorizationStatus == .notDetermined, !ScreenshotDemo.isActive else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
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
