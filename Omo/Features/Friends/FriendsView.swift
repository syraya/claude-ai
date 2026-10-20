import SwiftUI
import Charts

struct FriendsView: View {
    @Environment(AuthService.self) private var auth
    @Environment(FriendsService.self) private var friends
    @Environment(FocusController.self) private var focus

    @State private var code = ""
    @State private var sentMessage: String?

    var body: some View {
        @Bindable var friends = friends

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if !auth.isSignedIn {
                        SignInCard(reason: "Add friends, see each other's focus time and screen time, and keep each other honest.")
                    } else {
                        myCodeCard
                        addFriendCard
                        if !friends.incomingRequests.isEmpty { requestsCard }
                        leaderboard
                        if !friends.outgoingRequests.isEmpty { outgoingCard }
                    }
                }
                .padding()
            }
            .background(OmoBackground())
            .navigationTitle("Friends")
            .refreshable { await friends.refreshTodayStats() }
            .errorAlert($friends.errorMessage)
        }
    }

    private var myCodeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your friend code").font(.subheadline).foregroundStyle(.secondary)
                Text(auth.profile?.friendCode ?? "······")
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospaced())
                    .kerning(3)
                    .textSelection(.enabled)
            }
            Spacer()
            if let code = auth.profile?.friendCode {
                ShareLink(item: "Add me on OMO! My friend code is \(code)") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                }
            }
        }
        .card()
    }

    private var addFriendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a friend").font(.omoSerif(.headline))
            HStack {
                TextField("Their code", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.title3.monospaced())
                    .padding(12)
                    .background(Color.omoInk.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                Button("Add") {
                    Task {
                        if await friends.addFriend(code: code) {
                            sentMessage = "Request sent ✓"
                            code = ""
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(code.count < 6)
            }
            if let sentMessage {
                Text(sentMessage).font(.footnote).foregroundStyle(Color.omoSuccess)
            }
        }
        .card()
    }

    private var requestsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friend requests").font(.omoSerif(.headline))
            ForEach(friends.incomingRequests) { request in
                let name = request.otherName(me: auth.uid ?? "")
                HStack {
                    Avatar(name: name, size: 36)
                    Text(name).fontWeight(.medium)
                    Spacer()
                    Button("Decline") { Task { await friends.remove(request) } }
                        .buttonStyle(.bordered)
                    Button("Accept") { Task { await friends.accept(request) } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .card()
    }

    private var outgoingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Waiting on").font(.omoSerif(.headline))
            ForEach(friends.outgoingRequests) { request in
                HStack {
                    Text(request.otherName(me: auth.uid ?? ""))
                    Spacer()
                    Button("Cancel") { Task { await friends.remove(request) } }
                        .font(.subheadline)
                }
            }
        }
        .card()
    }

    /// Everyone's day, ranked by focus time, with you included.
    private var leaderboard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today").font(.omoSerif(.headline))

            row(name: "\(auth.displayName) (you)", stats: focus.today, rank: nil)

            if friends.friends.isEmpty {
                Text("No friends yet. Share your code to get started.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            ForEach(Array(friends.friends.enumerated()), id: \.element.id) { index, friendship in
                let uid = auth.uid ?? ""
                let friendUID = friendship.otherUID(me: uid)
                NavigationLink {
                    FriendDetailView(friendUID: friendUID, name: friendship.otherName(me: uid), friendship: friendship)
                } label: {
                    row(name: friendship.otherName(me: uid),
                        stats: friends.todayStats[friendUID] ?? DailyStats(day: ""),
                        rank: index + 1)
                }
                .buttonStyle(.plain)
            }
        }
        .card()
    }

    private func row(name: String, stats: DailyStats, rank: Int?) -> some View {
        HStack(spacing: 12) {
            if let rank {
                Text(rank == 1 ? "🥇" : (rank == 2 ? "🥈" : (rank == 3 ? "🥉" : "\(rank)")))
                    .frame(width: 28)
            } else {
                Image(systemName: "person.fill").frame(width: 28).foregroundStyle(.secondary)
            }
            Avatar(name: name, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).fontWeight(.medium)
                Text(stats.sharesScreenTime ? "\(Format.minutes(stats.distractingMinutes)) on distractions" : "Screen time hidden")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.minutes(stats.focusMinutes))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.omoSuccess)
                Text("focused").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

struct FriendDetailView: View {
    @Environment(FriendsService.self) private var friends
    @Environment(\.dismiss) private var dismiss

    var friendUID: String
    var name: String
    var friendship: Friendship

    @State private var week: [DailyStats] = []
    @State private var confirmRemove = false

    private var totalFocus: Int { week.reduce(0) { $0 + $1.focusMinutes } }
    private var totalSessions: Int { week.reduce(0) { $0 + $1.sessionsCompleted + $1.friendSessions } }
    private var sharesScreenTime: Bool { week.contains { $0.sharesScreenTime && $0.distractingMinutes > 0 } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Avatar(name: name, size: 72)
                    Text(name).font(.omoSerif(.title2, weight: .bold))
                }
                .padding(.top)

                HStack(spacing: 10) {
                    StatPill(value: Format.minutes(totalFocus), label: "Focused this week", color: .omoSuccess)
                    StatPill(value: "\(totalSessions)", label: "Sessions", color: .omoPrimary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Focus time").font(.omoSerif(.headline))
                    Chart(week) { day in
                        BarMark(x: .value("Day", day.date ?? Date(), unit: .day),
                                y: .value("Minutes", day.focusMinutes))
                            .foregroundStyle(Color.omoSuccess.gradient)
                            .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                        }
                    }
                    .frame(height: 160)
                }
                .card()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Time on distracting apps").font(.omoSerif(.headline))
                    if sharesScreenTime {
                        Chart(week) { day in
                            BarMark(x: .value("Day", day.date ?? Date(), unit: .day),
                                    y: .value("Minutes", max(0, day.distractingMinutes)))
                                .foregroundStyle(Color.omoGold.gradient)
                                .cornerRadius(6)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisValueLabel(format: .dateTime.weekday(.narrow))
                            }
                        }
                        .frame(height: 160)
                        Text("Counted in 15-minute steps, which is as precise as Apple allows.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("\(name) isn't sharing screen time yet.")
                            .foregroundStyle(.secondary)
                    }
                }
                .card()

                Button("Remove friend", role: .destructive) { confirmRemove = true }
                    .font(.subheadline)
            }
            .padding()
        }
        .background(OmoBackground())
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .task { week = await friends.recentStats(for: friendUID) }
        .confirmationDialog("Remove \(name)?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                Task {
                    await friends.remove(friendship)
                    dismiss()
                }
            }
        }
    }
}
