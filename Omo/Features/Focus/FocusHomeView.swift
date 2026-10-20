import SwiftUI

struct FocusHomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(FocusController.self) private var focus
    @Environment(ScreenTimeAuthorizer.self) private var screenTime
    @Environment(AuthService.self) private var auth
    @Environment(SettingsStore.self) private var settings

    /// How far the OMO header has scrolled away (0 = fully shown, 1 = minimised).
    @State private var collapse: CGFloat = 0

    var body: some View {
        @Bindable var focus = focus

        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                        OmoHeader(selected: settings.settings.companion,
                                  totalMinutes: focus.lifetime.totalFocusMinutes,
                                  collapse: collapse) { companion in
                            settings.settings.companion = companion
                        }
                        .id("top")
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: HeaderOffsetKey.self,
                                                   value: geo.frame(in: .named("focusScroll")).minY)
                        })

                        todayCard

                        NavigationLink {
                            LifetimeView()
                        } label: {
                            LifetimeCard(lifetime: focus.lifetime)
                        }
                        .buttonStyle(.plain)

                        if !screenTime.isApproved {
                            permissionCard
                        }

                        if let lock = focus.friendLock {
                            friendLockCard(lock)
                        }

                        if focus.session != nil {
                            ActiveSessionView()
                        } else {
                            StartSessionView()
                        }
                    }
                    .padding()
                }
                .coordinateSpace(name: "focusScroll")
                .onPreferenceChange(HeaderOffsetKey.self) { minY in
                    // The figure has fully shrunk away after about 180 points of scrolling.
                    collapse = min(1, max(0, (16 - minY) / 180))
                }
                .overlay(alignment: .topTrailing) {
                    // Your OMO, minimised, keeps you company while you scroll.
                    Button {
                        withAnimation { proxy.scrollTo("top", anchor: .top) }
                    } label: {
                        MiniOmo(companion: settings.settings.companion)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 16)
                    .padding(.top, 6)
                    .scaleEffect(0.4 + 0.6 * collapse, anchor: .topTrailing)
                    .opacity(collapse)
                    .allowsHitTesting(collapse > 0.6)
                    .accessibilityHidden(collapse < 0.6)
                }
            }
            .background(OmoBackground())
            .navigationTitle(greeting)
            .errorAlert($focus.errorMessage)
            .sheet(item: Binding(
                get: { focus.uncelebratedRank },
                set: { if $0 == nil, let rank = focus.uncelebratedRank { focus.markCelebrated(rank) } }
            )) { rank in
                RankUpView(rank: rank,
                           onUse: { companion in
                               focus.markCelebrated(rank)
                               settings.settings.companion = companion
                           },
                           onClose: { focus.markCelebrated(rank) })
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = auth.profile?.displayName.split(separator: " ").first.map(String.init)
        let base = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return name.map { "\(base), \($0)" } ?? base
    }

    private var todayCard: some View {
        HStack(spacing: 10) {
            StatPill(value: Format.minutes(focus.today.focusMinutes), label: "Focused today", color: .omoSuccess)
            StatPill(value: "\(focus.today.sessionsCompleted)", label: "Sessions", color: .omoPrimary)
            StatPill(value: "\(focus.today.breaksTaken)", label: "Breaks", color: .omoGold)
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Screen Time access needed", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Color.omoGold)
            Text("OMO can't block anything until you allow it.")
                .foregroundStyle(.secondary)
            Button("Allow access") { Task { await screenTime.request() } }
                .buttonStyle(SecondaryButtonStyle())
        }
        .card()
    }

    private func friendLockCard(_ lock: FriendLockState) -> some View {
        Button {
            router.tab = .together
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.2.badge.key.fill")
                    .font(.title)
                    .foregroundStyle(Color.omoSuccess)
                VStack(alignment: .leading, spacing: 4) {
                    Text(lock.isOnBreak ? "On a break from your study session" : "\(lock.keyholderName) has your key")
                        .font(.headline)
                    Text("Tap to see your study session")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .card()
        }
        .buttonStyle(.plain)
    }
}
