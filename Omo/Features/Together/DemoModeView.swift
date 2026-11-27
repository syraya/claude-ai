import SwiftUI

/// Friends and Study Circle with example people, so anyone can try them without an
/// account, App Review included. Everything happens on the phone: nothing is sent,
/// and no apps are locked. Reporting and blocking work just as they do for real.
struct DemoModeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .circle

    enum Tab: String, CaseIterable { case friends = "Friends", circle = "Study Circle" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Label {
                        Text("A demo with example people. Nothing here is sent anywhere or locks your apps; for that, start a focus session on the Focus tab, or sign in to study with real friends.")
                    } icon: {
                        Image(systemName: "sparkles")
                    }
                    .font(.footnote)
                    .foregroundStyle(Color.omoLabels)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()

                    Picker("Show", selection: $tab) {
                        ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch tab {
                    case .friends: DemoFriends()
                    case .circle: DemoCircle()
                    }
                }
                .padding()
            }
            .background(OmoBackground())
            .navigationTitle("Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

/// Example people and the blocks you've made in the demo.
@Observable @MainActor
final class DemoPeople {
    struct Person: Identifiable, Equatable {
        let id: String
        let name: String
        let focusMinutes: Int
        let distractingMinutes: Int
    }

    var people: [Person] = [
        Person(id: "maya", name: "Maya", focusMinutes: 145, distractingMinutes: 30),
        Person(id: "leo", name: "Leo", focusMinutes: 95, distractingMinutes: 75),
        Person(id: "sam", name: "Sam", focusMinutes: 60, distractingMinutes: 120),
    ]
    var requestFrom: Person? = Person(id: "jordan", name: "Jordan", focusMinutes: 20, distractingMinutes: 45)
    var blocked: [Person] = []
    var reports = 0

    func block(_ id: String) {
        if let person = people.first(where: { $0.id == id }) ?? (requestFrom?.id == id ? requestFrom : nil) {
            blocked.append(person)
        }
        people.removeAll { $0.id == id }
        if requestFrom?.id == id { requestFrom = nil }
    }

    func unblock(_ person: Person) {
        blocked.removeAll { $0.id == person.id }
        if person.id == "jordan" { requestFrom = person } else { people.append(person) }
    }

    func isBlocked(_ id: String) -> Bool { blocked.contains { $0.id == id } }

    func actions(for id: String) -> ModerationActions {
        ModerationActions(
            report: { [weak self] _, _, alsoBlock in
                try? await Task.sleep(for: .milliseconds(400))
                self?.reports += 1
                if alsoBlock { withAnimation { self?.block(id) } }
                return true
            },
            block: { [weak self] in withAnimation { self?.block(id) } }
        )
    }

    static let shared = DemoPeople()
}

// MARK: - Friends

private struct DemoFriends: View {
    private var demo: DemoPeople { .shared }

    var body: some View {
        VStack(spacing: 18) {
            if let request = demo.requestFrom {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Friend requests").font(.omoSerif(.headline))
                    HStack {
                        Avatar(name: request.name, size: 36)
                        Text(request.name).fontWeight(.medium)
                        Spacer()
                        Button("Decline") { withAnimation { demo.requestFrom = nil } }
                            .buttonStyle(.bordered)
                        Button("Accept") {
                            withAnimation {
                                demo.people.append(request)
                                demo.requestFrom = nil
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        ModerationMenu(name: request.name, actions: demo.actions(for: request.id))
                    }
                }
                .card()
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Today").font(.omoSerif(.headline))
                ForEach(Array(demo.people.sorted { $0.focusMinutes > $1.focusMinutes }.enumerated()),
                        id: \.element.id) { index, person in
                    HStack(spacing: 12) {
                        Text(index == 0 ? "🥇" : index == 1 ? "🥈" : index == 2 ? "🥉" : "\(index + 1)")
                            .frame(width: 28)
                        Avatar(name: person.name, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name).fontWeight(.medium)
                            Text("\(Format.minutes(person.distractingMinutes)) on distractions")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Format.minutes(person.focusMinutes))
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Color.omoSuccess)
                            Text("focused").font(.caption2).foregroundStyle(.secondary)
                        }
                        ModerationMenu(name: person.name, actions: demo.actions(for: person.id))
                    }
                }
                if demo.people.isEmpty {
                    Text("Everyone's blocked. Unblock them below.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .card()

            DemoBlockedList()
        }
    }
}

/// Who you've blocked in the demo, like Settings › Blocked people.
private struct DemoBlockedList: View {
    private var demo: DemoPeople { .shared }

    var body: some View {
        if !demo.blocked.isEmpty || demo.reports > 0 {
            VStack(alignment: .leading, spacing: 12) {
                Text("Blocked").font(.omoSerif(.headline))
                ForEach(demo.blocked) { person in
                    HStack {
                        Avatar(name: person.name, size: 32)
                        Text(person.name)
                        Spacer()
                        Button("Unblock") { withAnimation { demo.unblock(person) } }
                            .buttonStyle(.bordered)
                    }
                }
                if demo.blocked.isEmpty {
                    Text("No one.").font(.subheadline).foregroundStyle(.secondary)
                }
                if demo.reports > 0 {
                    Text("Reports sent in this demo: \(demo.reports). Real reports go to the OMO team, who review them within 24 hours.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .card()
        }
    }
}

// MARK: - Study Circle

private struct DemoCircle: View {
    private var demo: DemoPeople { .shared }

    /// Your phone: Maya holds your key.
    @State private var myLocked = true
    @State private var myEmergency = false
    @State private var myBreakUntil: Date?
    @State private var myRequest: Int?
    /// Leo's phone: you hold his key, and he wants a break.
    @State private var leoLocked = true
    @State private var leoBreakUntil: Date?
    @State private var leoRequest: Int? = 10
    @State private var started = Date().addingTimeInterval(-25 * 60)
    @State private var showEmergency = false
    @State private var confirmUnlockLeo = false

    private var maya: String { "Maya" }
    private var leo: String { "Leo" }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 18) {
                myPhoneCard(now: context.date)
                keysCard(now: context.date)
                everyoneCard(now: context.date)
                DemoBlockedList()
                Button("Restart the demo session") { withAnimation { reset() } }
                    .font(.subheadline)
                    .foregroundStyle(Color.omoLabels)
            }
        }
        .fullScreenCover(isPresented: $showEmergency) {
            ReflectionView(seconds: 60,
                           title: "Emergency unlock?\n\(maya) will be told.",
                           confirmLabel: "Unlock my phone",
                           onConfirm: {
                               showEmergency = false
                               withAnimation { myLocked = false; myEmergency = true }
                           },
                           onCancel: { showEmergency = false })
        }
        .confirmationDialog("Unlock \(leo)'s phone?", isPresented: $confirmUnlockLeo, titleVisibility: .visible) {
            Button("Unlock for good") { withAnimation { leoLocked = false; leoRequest = nil } }
            ForEach([5, 10, 15], id: \.self) { minutes in
                Button("Give a \(minutes)-minute break instead") { grantLeo(minutes) }
            }
        } message: {
            Text("Their apps stay unlocked until the session ends. Only do this when they're really done.")
        }
    }

    private func myPhoneCard(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if !myLocked {
                Label(myEmergency ? "You used the emergency unlock" : "You're unlocked ✓", systemImage: "lock.open.fill")
                    .font(.omoSerif(.title3))
                    .foregroundStyle(Color.omoSuccess)
                Text(myEmergency ? "\(maya) can see you used it. That's how the circle keeps everyone honest."
                                 : "Your apps are back. Others in the session may still be locked.")
                    .foregroundStyle(.secondary)
            } else if let until = myBreakUntil, until > now {
                Label("On a break", systemImage: "cup.and.saucer.fill")
                    .font(.omoSerif(.title3))
                    .foregroundStyle(Color.omoGold)
                Text("\(maya) said yes. Your apps lock again in \(Format.clock(until.timeIntervalSince(now))).")
                    .foregroundStyle(.secondary)
            } else {
                Label("Your phone is locked", systemImage: "lock.fill")
                    .font(.omoSerif(.title3))
                HStack(spacing: 10) {
                    Avatar(name: maya, size: 32)
                    Text("\(maya) has your key 🔑")
                }
                Text("Locked for \(Format.minutes(Int(now.timeIntervalSince(started) / 60)))")
                    .font(.subheadline).foregroundStyle(.secondary)
                if let minutes = myRequest {
                    Label("Asked \(maya) for \(minutes) minutes. Waiting…", systemImage: "hourglass")
                        .font(.subheadline)
                        .foregroundStyle(Color.omoGold)
                } else {
                    Menu {
                        ForEach(AppSettings.breakOptions, id: \.self) { minutes in
                            Button("\(minutes) minute\(minutes == 1 ? "" : "s")") { askMaya(minutes) }
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
    }

    @ViewBuilder
    private func keysCard(now: Date) -> some View {
        if !demo.isBlocked("leo") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Keys you hold").font(.omoSerif(.headline))
                HStack {
                    Avatar(name: leo, size: 36)
                    VStack(alignment: .leading) {
                        Text(leo).fontWeight(.medium)
                        Text(leoStatus(now: now)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if leoLocked {
                        Button("Unlock") { confirmUnlockLeo = true }
                            .buttonStyle(.bordered)
                    }
                    ModerationMenu(name: leo, actions: demo.actions(for: "leo"))
                }
                if leoLocked, let minutes = leoRequest {
                    HStack {
                        Text("Wants a \(minutes)-min break")
                            .font(.subheadline)
                            .foregroundStyle(Color.omoGold)
                        Spacer()
                        Button("Deny") { withAnimation { leoRequest = nil } }
                            .buttonStyle(.bordered)
                        Button("Allow") { grantLeo(minutes) }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .card()
        }
    }

    private func everyoneCard(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Everyone").font(.omoSerif(.headline))
            row(icon: myLocked ? "lock.fill" : "lock.open.fill", locked: myLocked, name: "You",
                status: myLocked ? (myBreakUntil.map { $0 > now } == true ? "On a break" : "Locked · key: \(maya)")
                                 : (myEmergency ? "Emergency unlocked ⚑" : "Unlocked"),
                id: nil)
            if !demo.isBlocked("maya") {
                row(icon: "lock.fill", locked: true, name: maya, status: "Locked · key: Sam", id: "maya")
            }
            if !demo.isBlocked("leo") {
                row(icon: leoLocked ? "lock.fill" : "lock.open.fill", locked: leoLocked, name: leo,
                    status: leoStatus(now: now), id: "leo")
            }
            if !demo.isBlocked("sam") {
                row(icon: "lock.fill", locked: true, name: "Sam", status: "Locked · key: You", id: "sam")
            }
            Text("Each person's key is held by someone else. Only the keyholder can unlock them; the emergency unlock is always there but flagged to their keyholder.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .card()
    }

    private func row(icon: String, locked: Bool, name: String, status: String, id: String?) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(locked ? Color.omoPrimary : Color.omoSuccess)
                .frame(width: 24)
            Text(name)
            Spacer()
            Text(status).font(.caption).foregroundStyle(.secondary)
            if let id {
                ModerationMenu(name: name, actions: demo.actions(for: id))
            }
        }
    }

    private func leoStatus(now: Date) -> String {
        if !leoLocked { return "Unlocked" }
        if let until = leoBreakUntil, until > now { return "On a break · \(Format.clock(until.timeIntervalSince(now)))" }
        return "Locked · key: You"
    }

    /// Maya answers a few seconds later, the way a friend would.
    private func askMaya(_ minutes: Int) {
        withAnimation { myRequest = minutes }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation {
                myRequest = nil
                myBreakUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
            }
        }
    }

    private func grantLeo(_ minutes: Int) {
        withAnimation {
            leoRequest = nil
            leoBreakUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        }
    }

    private func reset() {
        myLocked = true
        myEmergency = false
        myBreakUntil = nil
        myRequest = nil
        leoLocked = true
        leoBreakUntil = nil
        leoRequest = 10
        started = Date().addingTimeInterval(-25 * 60)
    }
}
