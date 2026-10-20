import SwiftUI

struct FocusHomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(FocusController.self) private var focus
    @Environment(ScreenTimeAuthorizer.self) private var screenTime
    @Environment(AuthService.self) private var auth
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        @Bindable var focus = focus

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
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
            .background(OmoBackground())
            .navigationTitle(greeting)
            .errorAlert($focus.errorMessage)
            .sheet(item: Binding(
                get: { focus.uncelebratedRank },
                set: { if $0 == nil, let rank = focus.uncelebratedRank { focus.markCelebrated(rank) } }
            )) { rank in
                RankUpView(rank: rank,
                           onUseTheme: {
                               focus.markCelebrated(rank)
                               settings.settings.theme = rank.theme
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
