import SwiftUI

struct FocusHomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(FocusController.self) private var focus
    @Environment(ScreenTimeAuthorizer.self) private var screenTime
    @Environment(AuthService.self) private var auth

    var body: some View {
        @Bindable var focus = focus

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    todayCard

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
            .background(Color.lsBackground.ignoresSafeArea())
            .navigationTitle(greeting)
            .errorAlert($focus.errorMessage)
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
            StatPill(value: Format.minutes(focus.today.focusMinutes), label: "Focused today", color: .lsMint)
            StatPill(value: "\(focus.today.sessionsCompleted)", label: "Sessions", color: .lsAccent)
            StatPill(value: "\(focus.today.breaksTaken)", label: "Breaks", color: .lsWarm)
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Screen Time access needed", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Color.lsWarm)
            Text("Lockstep can't block anything until you allow it.")
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
                    .foregroundStyle(Color.lsMint)
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
