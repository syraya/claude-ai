import SwiftUI
import UserNotifications

struct StartSessionView: View {
    @Environment(FocusController.self) private var focus
    @Environment(BlockListStore.self) private var blockLists
    @Environment(SettingsStore.self) private var settings
    @Environment(ScreenTimeAuthorizer.self) private var screenTime

    @State private var selectedListID: UUID?
    @State private var minutes = 45
    @State private var allowsBreaks = true
    @State private var strictMode = false
    @State private var intention = ""
    @State private var editingList: BlockList?
    @State private var didLoadDefaults = false
    @FocusState private var typingIntention: Bool
    /// Between tapping Start focus and the session appearing: the setup fades away.
    @State private var starting = false
    /// The first start explains why OMO sends notifications before iOS asks.
    @State private var askingNotifications = false

    private let presets = [15, 25, 45, 60, 90, 120]

    private var selectedList: BlockList? {
        blockLists.list(id: selectedListID) ?? blockLists.lists.first
    }

    private var canStart: Bool {
        screenTime.isApproved && !(selectedList?.isEmpty ?? true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            setup
                .opacity(starting ? 0.15 : 1)
                .blur(radius: starting ? 2 : 0)
                .scaleEffect(starting ? 0.98 : 1, anchor: .top)
                .allowsHitTesting(!starting)

            Button(action: tapStart) {
                HStack(spacing: 10) {
                    if starting {
                        ProgressView().tint(Color.omoOnPrimary)
                        Text("Starting focus…")
                    } else {
                        Text("Start focus")
                        Image(systemName: "arrow.right").font(.subheadline.weight(.semibold))
                    }
                }
                .contentTransition(.opacity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canStart)
            .opacity(canStart ? (starting ? 0.85 : 1) : 0.5)
        }
        .card()
        .alert("Know when time's up", isPresented: $askingNotifications) {
            Button("Continue") {
                Task {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                    begin()
                }
            }
        } message: {
            Text("OMO sends a notification when your session or a break ends, so you know when to come back. iOS will ask next.")
        }
        .sheet(item: $editingList) { list in
            BlockListEditorView(list: list, isNew: true) { saved in
                selectedListID = saved.id
            }
        }
        .onAppear {
            guard !didLoadDefaults else { return }
            didLoadDefaults = true
            minutes = settings.settings.defaultSessionMinutes
        }
        .task {
            // Simulator demo: press Start focus by itself, to record the animation.
            guard ScreenshotDemo.screen == "start-anim" else { return }
            try? await Task.sleep(for: .seconds(2))
            intention = "Finish chapter 4 of biology"
            begin()
        }
    }

    /// Notifications are asked for here, the first time they'd matter, rather than
    /// the moment the app opens.
    private func tapStart() {
        guard selectedList != nil, !starting else { return }
        Task {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            if status == .notDetermined && !ScreenshotDemo.isActive {
                askingNotifications = true
            } else {
                begin()
            }
        }
    }

    private func begin() {
        guard let list = selectedList, !starting else { return }
        // Put the keyboard away first. Starting while it's up swaps this card
        // out from under it, and it lingers on screen before iOS notices.
        let typing = typingIntention
        typingIntention = false
        withAnimation(.easeInOut(duration: 0.45)) { starting = true }
        Task {
            try? await Task.sleep(for: .milliseconds(typing ? 650 : 550))
            start(list)
        }
    }

    /// Everything you set before starting.
    private var setup: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What will you focus on?")
                .font(.omoSerif(.title3))

            VStack(alignment: .leading, spacing: 6) {
                TextField("e.g. Finish chapter 4", text: $intention)
                    .focused($typingIntention)
                    .submitLabel(.done)
                    .onSubmit { typingIntention = false }
                    .font(.system(.body, design: .serif))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.omoPaper, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.omoInk.opacity(0.12), lineWidth: 0.75))
                Text("It shows on your timer and on blocked apps.")
                    .font(.caption)
                    .foregroundStyle(Color.omoLabels)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Duration").font(.subheadline).foregroundStyle(Color.omoLabels)
                    Spacer()
                    Stepper(Format.minutes(minutes), value: $minutes, in: 5...720, step: 5)
                        .fixedSize()
                        .font(.subheadline.monospacedDigit())
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            Button(Format.minutes(preset)) { minutes = preset }
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(minutes == preset ? Color.omoPrimary : Color.omoPaper, in: Capsule())
                                .overlay(Capsule().stroke(Color.omoInk.opacity(minutes == preset ? 0 : 0.12), lineWidth: 0.75))
                                .foregroundStyle(minutes == preset ? Color.omoOnPrimary : Color.omoInk)
                                .buttonStyle(.plain)
                        }
                    }
                }
            }

            Divider()

            blockListRow

            if let list = selectedList, list.isEmpty, !ScreenshotDemo.isActive {
                Text("“\(list.name)” has no apps yet. Add some in Block Lists.")
                    .font(.footnote)
                    .foregroundStyle(Color.omoLabels)
            }

            VStack(spacing: 4) {
                Toggle(isOn: $allowsBreaks) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Allow breaks")
                        Text(settings.settings.hasUnlimitedBreaks
                             ? "As many as you need, each after a \(settings.settings.reflectionSeconds)s pause"
                             : "Up to \(settings.settings.maxBreaksPerSession), each after a \(settings.settings.reflectionSeconds)s pause")
                            .font(.caption).foregroundStyle(Color.omoLabels)
                    }
                }
                Toggle(isOn: $strictMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Strict mode")
                        Text("No ending the session early")
                            .font(.caption).foregroundStyle(Color.omoLabels)
                    }
                }
            }
            .tint(.omoPrimary)
        }
    }

    private func start(_ list: BlockList) {
        focus.start(blockList: list,
                    minutes: minutes,
                    allowsBreaks: allowsBreaks,
                    allowsEndingEarly: !strictMode,
                    maxBreaks: settings.settings.maxBreaksPerSession,
                    intention: intention.trimmingCharacters(in: .whitespacesAndNewlines))
        intention = ""
        settings.settings.defaultSessionMinutes = minutes
        starting = false
    }

    /// One row for what gets blocked: tap to switch lists or make a new one.
    private var blockListRow: some View {
        Menu {
            ForEach(blockLists.lists) { list in
                Button {
                    selectedListID = list.id
                } label: {
                    if list.id == selectedList?.id {
                        Label("\(list.emoji) \(list.name)", systemImage: "checkmark")
                    } else {
                        Text("\(list.emoji) \(list.name)")
                    }
                }
            }
            Divider()
            Button("New block list", systemImage: "plus") { editingList = BlockList(name: "") }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up")
                    .foregroundStyle(Color.omoPrimary)
                Text("Block list")
                    .foregroundStyle(Color.omoInk)
                Spacer(minLength: 8)
                Text(selectedList.map { "\($0.name) · \(ScreenshotDemo.summary(for: $0) ?? $0.summary)" } ?? "Choose")
                    .font(.subheadline)
                    .foregroundStyle(Color.omoLabels)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(Color.omoLabels)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Block list: \(selectedList?.name ?? "none")")
    }
}
