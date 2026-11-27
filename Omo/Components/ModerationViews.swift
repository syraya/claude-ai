import SwiftUI

/// What happens when someone is reported or blocked. The real screens send these to
/// ModerationService; the demo handles them on the phone.
struct ModerationActions {
    var report: @MainActor (_ reason: ReportReason, _ details: String, _ alsoBlock: Bool) async -> Bool
    var block: @MainActor () async -> Void

    /// Reports and blocks through the server, for real people.
    @MainActor
    static func live(uid: String, name: String, context: ReportContext) -> ModerationActions {
        ModerationActions(
            report: { reason, details, alsoBlock in
                let sent = await ModerationService.shared.report(uid, name: name, reason: reason,
                                                                 details: details, context: context)
                if sent, alsoBlock { await ModerationService.shared.block(uid, name: name) }
                return sent
            },
            block: { await ModerationService.shared.block(uid, name: name) }
        )
    }
}

/// A "…" button with Report and Block for one person.
struct ModerationMenu: View {
    var name: String
    var actions: ModerationActions

    @State private var showReport = false
    @State private var confirmBlock = false

    var body: some View {
        Menu {
            Button("Report \(name)…", systemImage: "flag") { showReport = true }
            Button("Block \(name)", systemImage: "hand.raised", role: .destructive) { confirmBlock = true }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundStyle(Color.omoLabels)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Report or block \(name)")
        .modifier(ModerationSheets(name: name, actions: actions,
                                   showReport: $showReport, confirmBlock: $confirmBlock))
    }
}

/// The report form and block confirmation, for places that offer their own buttons.
struct ModerationSheets: ViewModifier {
    var name: String
    var actions: ModerationActions
    @Binding var showReport: Bool
    @Binding var confirmBlock: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showReport) {
                ReportSheet(name: name, actions: actions)
            }
            .confirmationDialog("Block \(name)?", isPresented: $confirmBlock, titleVisibility: .visible) {
                Button("Block", role: .destructive) { Task { await actions.block() } }
            } message: {
                Text("\(name) will be removed from your friends, and their friend requests and Study Circle invites won't reach you. They aren't told. You can unblock them in Settings.")
            }
    }
}

/// Why you're reporting someone, with room for details.
struct ReportSheet: View {
    var name: String
    var actions: ModerationActions

    @State private var reason: ReportReason = .harassment
    @State private var details = ""
    @State private var alsoBlock = true
    @State private var sending = false
    @State private var sent = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if sent {
                    Section {
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.omoSuccess)
                            Text("Thanks for reporting \(name)")
                                .font(.omoSerif(.title3, weight: .semibold))
                            Text("We review every report within 24 hours and remove people who break the rules.\(alsoBlock ? " \(name) is also blocked." : "")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                } else {
                    Section("What's wrong?") {
                        Picker("Reason", selection: $reason) {
                            ForEach(ReportReason.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                    Section("Details (optional)") {
                        TextField("What happened?", text: $details, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    Section {
                        Toggle("Also block \(name)", isOn: $alsoBlock)
                    } footer: {
                        Text("Reports go to the OMO team, not to \(name).")
                    }
                }
            }
            .navigationTitle(sent ? "Report sent" : "Report \(name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if sent {
                    ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                } else {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send") {
                            sending = true
                            Task {
                                let ok = await actions.report(reason, details, alsoBlock)
                                sending = false
                                if ok { withAnimation { sent = true } }
                            }
                        }
                        .disabled(sending)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

/// Settings › Blocked people.
struct BlockedPeopleView: View {
    private var moderation: ModerationService { .shared }

    var body: some View {
        List {
            if moderation.blocked.isEmpty {
                Text("You haven't blocked anyone.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(moderation.blocked.sorted { $0.value < $1.value }, id: \.key) { uid, name in
                    HStack {
                        Avatar(name: name, size: 32)
                        Text(name)
                        Spacer()
                        Button("Unblock") { Task { await moderation.unblock(uid) } }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
        .navigationTitle("Blocked people")
        .navigationBarTitleDisplayMode(.inline)
    }
}
