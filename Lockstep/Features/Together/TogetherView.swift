import SwiftUI

struct TogetherView: View {
    @Environment(AuthService.self) private var auth
    @Environment(GroupSessionService.self) private var together

    var body: some View {
        @Bindable var together = together

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if !auth.isSignedIn {
                        SignInCard(reason: "Start a study session with friends. Everyone's phone locks, and only the friend holding your key can unlock yours.")
                    } else if let session = together.current {
                        if session.isLobby {
                            LobbyView(session: session)
                        } else {
                            ActiveGroupSessionView(session: session)
                        }
                    } else {
                        if let ended = together.justEnded {
                            endedCard(ended)
                        }
                        NewGroupSessionView()
                    }
                }
                .padding()
            }
            .background(Color.lsBackground.ignoresSafeArea())
            .navigationTitle("Together")
            .errorAlert($together.errorMessage)
        }
    }

    private func endedCard(_ session: GroupSession) -> some View {
        HStack(spacing: 14) {
            Text("🎉").font(.largeTitle)
            VStack(alignment: .leading, spacing: 4) {
                Text("Session complete").font(.headline)
                Text("Everyone's unlocked. Nice work, team.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                together.justEnded = nil
            } label: {
                Image(systemName: "xmark").foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

// MARK: - Start or join

struct NewGroupSessionView: View {
    @Environment(GroupSessionService.self) private var together
    @Environment(FriendsService.self) private var friends
    @Environment(BlockListStore.self) private var blockLists
    @Environment(ScreenTimeAuthorizer.self) private var screenTime

    @State private var invited: Set<String> = []
    @State private var joinCode = ""
    @State private var blockListID: UUID? = GroupSessionService.groupBlockListID

    private var chosenList: BlockList? {
        blockLists.list(id: blockListID) ?? blockLists.lists.first { !$0.isEmpty }
    }

    private var ready: Bool {
        screenTime.isApproved && !(chosenList?.isEmpty ?? true) && !together.isWorking
    }

    var body: some View {
        VStack(spacing: 18) {
            howItWorks

            if !together.invitations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Invites").font(.headline)
                    ForEach(together.invitations) { invite in
                        HStack {
                            Avatar(name: invite.hostName, size: 36)
                            VStack(alignment: .leading) {
                                Text("\(invite.hostName)'s session").fontWeight(.medium)
                                Text("\(invite.members.count) joined").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Join") { Task { await together.join(invite) } }
                                .buttonStyle(.borderedProminent)
                                .disabled(!ready)
                        }
                    }
                }
                .card()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("What gets locked on your phone").font(.headline)
                if blockLists.lists.isEmpty {
                    Text("Make a block list first (Block Lists tab).")
                        .foregroundStyle(Color.lsWarm)
                } else {
                    Picker("Block list", selection: Binding(
                        get: { chosenList?.id },
                        set: { blockListID = $0; GroupSessionService.groupBlockListID = $0 }
                    )) {
                        ForEach(blockLists.lists) { list in
                            Text("\(list.emoji) \(list.name)").tag(Optional(list.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.lsAccent)
                }
            }
            .card()

            VStack(alignment: .leading, spacing: 14) {
                Text("Start a session").font(.headline)
                if friends.friends.isEmpty {
                    Text("Add friends in the Friends tab to invite them, or share the code you'll get.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Text("Invite friends (optional)").font(.subheadline).foregroundStyle(.secondary)
                    ForEach(friends.friends) { friendship in
                        let friendUID = friendship.otherUID(me: friends.uid ?? "")
                        Button {
                            if invited.contains(friendUID) { invited.remove(friendUID) } else { invited.insert(friendUID) }
                        } label: {
                            HStack {
                                Avatar(name: friendship.otherName(me: friends.uid ?? ""), size: 32)
                                Text(friendship.otherName(me: friends.uid ?? ""))
                                Spacer()
                                Image(systemName: invited.contains(friendUID) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(invited.contains(friendUID) ? Color.lsAccent : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button {
                    commitBlockList()
                    Task { await together.createSession(inviting: Array(invited)) }
                } label: {
                    Label("Create session", systemImage: "person.2.badge.key.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!ready)
                .opacity(ready ? 1 : 0.5)
            }
            .card()

            VStack(alignment: .leading, spacing: 14) {
                Text("Join with a code").font(.headline)
                HStack {
                    TextField("6-digit code", text: $joinCode)
                        .keyboardType(.numberPad)
                        .font(.title3.monospacedDigit())
                        .padding(12)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    Button("Join") {
                        commitBlockList()
                        Task { await together.join(code: joinCode) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!ready || joinCode.filter(\.isNumber).count != 6)
                }
            }
            .card()
        }
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How it works").font(.headline)
            Label("Everyone joins the same session", systemImage: "1.circle.fill")
            Label("The host starts it and every phone locks", systemImage: "2.circle.fill")
            Label("A friend holds your key, and you hold theirs", systemImage: "3.circle.fill")
            Label("Only your keyholder can unlock you", systemImage: "4.circle.fill")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .card()
    }

    private func commitBlockList() {
        GroupSessionService.groupBlockListID = chosenList?.id
    }
}

// MARK: - Lobby

struct LobbyView: View {
    @Environment(GroupSessionService.self) private var together
    var session: GroupSession

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("Session code").font(.subheadline).foregroundStyle(.secondary)
                Text(session.code)
                    .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                    .kerning(6)
                    .textSelection(.enabled)
                Text("Friends can join with this code")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .card()

            VStack(alignment: .leading, spacing: 12) {
                Text("In the room (\(session.members.count)/\(GroupSession.maxMembers))").font(.headline)
                ForEach(Array(session.members.enumerated()), id: \.element) { index, member in
                    let keyholder = session.members.count > 1
                        ? session.name(of: session.members[(index + 1) % session.members.count])
                        : nil
                    HStack {
                        Avatar(name: session.name(of: member), size: 36)
                        VStack(alignment: .leading) {
                            Text(session.name(of: member) + (member == together.uid ? " (you)" : ""))
                                .fontWeight(.medium)
                            if let keyholder {
                                Text("🔑 \(keyholder) will hold their key")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if member == session.hostUID {
                            Text("Host").font(.caption.weight(.semibold))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.lsAccent.opacity(0.2), in: Capsule())
                        }
                    }
                }
            }
            .card()

            if together.isHost {
                Button {
                    Task { await together.beginSession() }
                } label: {
                    Label("Lock everyone in", systemImage: "lock.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(session.members.count < 2 || together.isWorking)
                .opacity(session.members.count < 2 ? 0.5 : 1)
                if session.members.count < 2 {
                    Text("Waiting for at least one friend to join…")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } else {
                Label("Waiting for \(session.hostName) to start", systemImage: "hourglass")
                    .foregroundStyle(.secondary)
            }

            Button(together.isHost ? "Cancel session" : "Leave", role: .destructive) {
                Task { await together.leaveLobby() }
            }
            .font(.subheadline)
        }
    }
}

// MARK: - Active session

struct ActiveGroupSessionView: View {
    @Environment(GroupSessionService.self) private var together
    var session: GroupSession

    @State private var showEmergency = false
    @State private var unlockTarget: SessionLock?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 18) {
                myPhoneCard(now: context.date)
                if !together.keysIHold.isEmpty {
                    keysCard(now: context.date)
                }
                everyoneCard(now: context.date)
            }
        }
        .fullScreenCover(isPresented: $showEmergency) {
            ReflectionView(seconds: 60,
                           title: "Emergency unlock?\n\(together.myLock?.keyholderName ?? "Your friend") will be told.",
                           confirmLabel: "Unlock my phone",
                           onConfirm: {
                               showEmergency = false
                               Task { await together.emergencyExit() }
                           },
                           onCancel: { showEmergency = false })
        }
        .confirmationDialog("Unlock \(unlockTarget?.lockedName ?? "")'s phone?",
                            isPresented: Binding(get: { unlockTarget != nil }, set: { if !$0 { unlockTarget = nil } }),
                            titleVisibility: .visible) {
            Button("Unlock for good") {
                if let lock = unlockTarget { Task { await together.unlock(lock) } }
                unlockTarget = nil
            }
            ForEach([5, 10, 15], id: \.self) { minutes in
                Button("Give a \(minutes)-minute break instead") {
                    if let lock = unlockTarget { Task { await together.grantBreak(lock, minutes: minutes) } }
                    unlockTarget = nil
                }
            }
        } message: {
            Text("Their apps stay unlocked until the session ends. Only do this when they're really done.")
        }
    }

    @ViewBuilder
    private func myPhoneCard(now: Date) -> some View {
        if let mine = together.myLock {
            VStack(alignment: .leading, spacing: 14) {
                if !mine.locked {
                    Label(mine.emergencyExit == true ? "You used the emergency unlock" : "You're unlocked ✓",
                          systemImage: "lock.open.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.lsMint)
                    Text("Your apps are back. Others in the session may still be locked.")
                        .foregroundStyle(.secondary)
                } else if let until = mine.breakUntil, until > now {
                    Label("On a break", systemImage: "cup.and.saucer.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.lsWarm)
                    Text("Your apps lock again in \(Format.clock(until.timeIntervalSince(now))).")
                        .foregroundStyle(.secondary)
                } else {
                    Label("Your phone is locked", systemImage: "lock.fill")
                        .font(.title3.weight(.semibold))
                    HStack(spacing: 10) {
                        Avatar(name: mine.keyholderName, size: 32)
                        Text("\(mine.keyholderName) has your key 🔑")
                    }
                    if let lockedAt = mine.lockedAt {
                        Text("Locked for \(Format.minutes(Int(now.timeIntervalSince(lockedAt) / 60)))")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    if let minutes = mine.breakRequestMinutes {
                        Label("Asked \(mine.keyholderName) for \(minutes) minutes. Waiting…", systemImage: "hourglass")
                            .font(.subheadline)
                            .foregroundStyle(Color.lsWarm)
                    } else {
                        Menu {
                            ForEach(AppSettings.breakOptions, id: \.self) { minutes in
                                Button("\(minutes) minute\(minutes == 1 ? "" : "s")") {
                                    Task { await together.requestBreak(minutes: minutes) }
                                }
                            }
                        } label: {
                            Label("Ask for a break", systemImage: "cup.and.saucer.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

                    Button("Emergency unlock") { showEmergency = true }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .card()
        } else {
            HStack {
                ProgressView()
                Text("Locking your phone…").foregroundStyle(.secondary)
            }
            .card()
        }
    }

    private func keysCard(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Keys you hold").font(.headline)
            ForEach(together.keysIHold) { lock in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Avatar(name: lock.lockedName, size: 36)
                        VStack(alignment: .leading) {
                            Text(lock.lockedName).fontWeight(.medium)
                            Text(status(of: lock, now: now)).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if lock.locked {
                            Button("Unlock") { unlockTarget = lock }
                                .buttonStyle(.bordered)
                        }
                    }
                    if lock.hasPendingBreakRequest, let minutes = lock.breakRequestMinutes {
                        HStack {
                            Text("Wants a \(minutes)-min break")
                                .font(.subheadline)
                                .foregroundStyle(Color.lsWarm)
                            Spacer()
                            Button("Deny") { Task { await together.denyBreak(lock) } }
                                .buttonStyle(.bordered)
                            Button("Allow") { Task { await together.grantBreak(lock, minutes: minutes) } }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
        .card()
    }

    private func everyoneCard(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Everyone").font(.headline)
            ForEach(together.locks) { lock in
                HStack {
                    Image(systemName: lock.locked ? "lock.fill" : "lock.open.fill")
                        .foregroundStyle(lock.locked ? Color.lsAccent : Color.lsMint)
                        .frame(width: 24)
                    Text(lock.lockedName + (lock.lockedUID == together.uid ? " (you)" : ""))
                    Spacer()
                    Text(status(of: lock, now: now)).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .card()
    }

    private func status(of lock: SessionLock, now: Date) -> String {
        if !lock.locked { return lock.emergencyExit == true ? "Emergency unlocked" : "Unlocked" }
        if let until = lock.breakUntil, until > now { return "On a break · \(Format.clock(until.timeIntervalSince(now)))" }
        return "Locked · key: \(lock.keyholderName)"
    }
}
