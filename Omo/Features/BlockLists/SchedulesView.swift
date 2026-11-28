import SwiftUI
import UserNotifications

/// One schedule on the Block Lists tab: its times, its days, and a switch.
struct ScheduleRow: View {
    var schedule: BlockSchedule
    var list: BlockList?
    var onOpen: () -> Void
    var onToggle: (Bool) -> Void

    var body: some View {
        TimelineView(.everyMinute) { context in
            HStack(alignment: .top, spacing: 14) {
                // The switch sits outside the button so taps on it don't open the editor.
                Button(action: onOpen) {
                    details(now: context.date)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Toggle("On", isOn: Binding(get: { schedule.isEnabled }, set: onToggle))
                    .labelsHidden()
                    .tint(.omoPrimary)
                    .disabled(schedule.isLocked(at: context.date))
            }
            .padding(.vertical, 12)
            .opacity(schedule.isEnabled ? 1 : 0.6)
        }
    }

    private func details(now: Date) -> some View {
        let active = schedule.isActive(at: now) && list.map { !$0.isEmpty } == true
        return HStack(alignment: .top, spacing: 14) {
            Text(list?.emoji ?? "🗓️")
                .font(.title2)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(schedule.name).font(.headline)
                    if schedule.isStrict {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Strict")
                    }
                }
                Text(schedule.timeText)
                    .font(.system(.subheadline, design: .serif).weight(.semibold).monospacedDigit())
                Text("\(schedule.daysText) · \(list?.name ?? "No block list")")
                    .font(.subheadline)
                    .foregroundStyle(Color.omoLabels)
                if active, let end = schedule.endDate(after: now) {
                    Label("Blocking now, until \(end.formatted(date: .omitted, time: .shortened))",
                          systemImage: "moon.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.omoPrimary)
                        .padding(.top, 2)
                } else if list == nil {
                    Label("Its block list was deleted. Choose another.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.omoLabels)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

/// Creating or changing a schedule.
struct ScheduleEditorView: View {
    @Environment(BlockListStore.self) private var blockLists
    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var schedule: BlockSchedule
    private let original: BlockSchedule
    private let isNew: Bool

    @State private var problem: String?
    @State private var confirmDelete = false
    /// What to do once the reflection wait is over, when a change would end a block early.
    @State private var afterReflection: (() -> Void)?

    init(schedule: BlockSchedule, isNew: Bool) {
        _schedule = State(initialValue: schedule)
        original = schedule
        self.isNew = isNew
    }

    /// Strict and blocking: nothing can change until it ends.
    private var isLocked: Bool { !isNew && original.isLocked() }

    var body: some View {
        NavigationStack {
            Form {
                if isLocked, let end = original.endDate() {
                    Section {
                        Label("Strict schedule. You can change it after \(end.formatted(date: .omitted, time: .shortened)).",
                              systemImage: "lock.fill")
                            .foregroundStyle(Color.omoPrimary)
                    }
                }

                if isNew {
                    Section("Quick start") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                preset("Work", 9, 0, 17, 0, BlockSchedule.weekdaysOnly)
                                preset("School", 8, 30, 15, 30, BlockSchedule.weekdaysOnly)
                                preset("Bedtime", 22, 0, 7, 0, BlockSchedule.everyDay)
                                preset("Weekend reset", 10, 0, 14, 0, BlockSchedule.weekendsOnly)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Name") {
                    TextField("e.g. Work, School, Bedtime", text: $schedule.name)
                }

                Section {
                    if blockLists.lists.isEmpty {
                        Text("Make a block list first, then come back to schedule it.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Block list", selection: $schedule.blockListID) {
                            if schedule.blockListID == nil || blockLists.list(id: schedule.blockListID) == nil {
                                Text("Choose…").tag(UUID?.none)
                            }
                            ForEach(blockLists.lists) { list in
                                Text("\(list.emoji) \(list.name)").tag(UUID?.some(list.id))
                            }
                        }
                    }
                } header: {
                    Text("What to block")
                }

                Section {
                    DatePicker("Starts", selection: time(\.startHour, \.startMinute), displayedComponents: .hourAndMinute)
                    DatePicker("Ends", selection: time(\.endHour, \.endMinute), displayedComponents: .hourAndMinute)
                } header: {
                    Text("When")
                } footer: {
                    Text(schedule.crossesMidnight
                         ? "Ends the next morning. The days below are the nights it starts."
                         : "Blocks for \(Format.minutes(schedule.durationMinutes)) each day it runs.")
                }

                Section("Days") {
                    HStack(spacing: 8) {
                        dayPreset("Every day", BlockSchedule.everyDay)
                        dayPreset("Weekdays", BlockSchedule.weekdaysOnly)
                        dayPreset("Weekends", BlockSchedule.weekendsOnly)
                    }
                    HStack {
                        ForEach(BlockSchedule.orderedWeekdays, id: \.self) { weekday in
                            dayButton(weekday)
                            if weekday != BlockSchedule.orderedWeekdays.last { Spacer(minLength: 0) }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("Counts as focus time", isOn: Binding(
                        get: { schedule.countsTowardFocus },
                        set: { schedule.countsAsFocus = $0 }
                    ))
                    .tint(.omoPrimary)
                } footer: {
                    Text("Adds the time this schedule blocks to your focus totals and your progress toward OMOs. Off by default for overnight schedules, so sleep doesn't count.")
                }

                Section {
                    Toggle("Strict", isOn: $schedule.isStrict)
                        .tint(.omoPrimary)
                } footer: {
                    Text("A strict schedule can't be turned off, changed or deleted while it's blocking. Otherwise you can, after the \(settings.settings.reflectionSeconds)-second reflection wait.")
                }

                if !isNew {
                    Section {
                        Button("Delete schedule", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .disabled(isLocked)
            .scrollContentBackground(.hidden)
            .background(OmoBackground())
            .topBanner($problem)
            .navigationTitle(isNew ? "New schedule" : original.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(isLocked)
                }
            }
            .confirmationDialog("Delete “\(original.name)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    afterReflectionIfEndingEarly {
                        blockLists.delete(original)
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: Binding(get: { afterReflection != nil },
                                                  set: { if !$0 { afterReflection = nil } })) {
                ReflectionView(seconds: settings.settings.reflectionSeconds,
                               title: "End “\(original.name)” early?",
                               confirmLabel: "Yes, change it",
                               onConfirm: {
                                   let action = afterReflection
                                   afterReflection = nil
                                   action?()
                               },
                               onCancel: { afterReflection = nil })
            }
            .onAppear {
                if schedule.blockListID == nil { schedule.blockListID = blockLists.lists.first?.id }
            }
        }
    }

    // MARK: Saving

    private var missing: String? {
        if schedule.name.trimmingCharacters(in: .whitespaces).isEmpty { return "Give your schedule a name" }
        if blockLists.list(id: schedule.blockListID) == nil { return "Choose a block list" }
        if schedule.weekdays.isEmpty { return "Pick at least one day" }
        if schedule.durationMinutes < BlockSchedule.minimumMinutes {
            return "Make it at least \(BlockSchedule.minimumMinutes) minutes long"
        }
        return nil
    }

    private func save() {
        if let missing {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            problem = missing
            return
        }
        schedule.name = schedule.name.trimmingCharacters(in: .whitespaces)
        let changed = schedule
        let isNew = isNew
        let commit = {
            blockLists.save(changed)
            dismiss()
            // A schedule blocks apps on its own, and the block screen's "take a break"
            // arrives as a notification, so the first schedule is a moment iOS's
            // question makes sense. It's only ever shown once.
            if isNew && !ScreenshotDemo.isActive {
                UNUserNotificationCenter.current().getNotificationSettings { current in
                    guard current.authorizationStatus == .notDetermined else { return }
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                        AppDelegate.registerForPushIfAllowed()
                    }
                }
            }
        }
        // Lifting or swapping a block that's on right now goes through the reflection wait first.
        let liftsBlock = original.isActive()
            && (!changed.isActive() || changed.blockListID != original.blockListID)
        if !isNew && liftsBlock {
            afterReflection = commit
        } else {
            commit()
        }
    }

    private func afterReflectionIfEndingEarly(_ action: @escaping () -> Void) {
        if original.isActive() {
            afterReflection = action
        } else {
            action()
        }
    }

    // MARK: Pieces

    private func time(_ hour: WritableKeyPath<BlockSchedule, Int>,
                      _ minute: WritableKeyPath<BlockSchedule, Int>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: schedule[keyPath: hour], minute: schedule[keyPath: minute],
                                      second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                schedule[keyPath: hour] = parts.hour ?? 0
                schedule[keyPath: minute] = parts.minute ?? 0
            }
        )
    }

    private func preset(_ name: String, _ startHour: Int, _ startMinute: Int,
                        _ endHour: Int, _ endMinute: Int, _ days: Set<Int>) -> some View {
        Button {
            schedule.name = name
            schedule.startHour = startHour
            schedule.startMinute = startMinute
            schedule.endHour = endHour
            schedule.endMinute = endMinute
            schedule.weekdays = days
        } label: {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.omoPrimary.opacity(0.12), in: Capsule())
                .foregroundStyle(Color.omoPrimary)
        }
        .buttonStyle(.plain)
    }

    private func dayPreset(_ title: String, _ days: Set<Int>) -> some View {
        let selected = schedule.weekdays == days
        return Button {
            schedule.weekdays = days
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? Color.omoPrimary : Color.omoInk.opacity(0.06), in: Capsule())
                .foregroundStyle(selected ? Color.omoOnPrimary : Color.omoInk)
        }
        .buttonStyle(.plain)
    }

    private func dayButton(_ weekday: Int) -> some View {
        let selected = schedule.weekdays.contains(weekday)
        return Button {
            if selected { schedule.weekdays.remove(weekday) } else { schedule.weekdays.insert(weekday) }
        } label: {
            Text(Calendar.current.veryShortWeekdaySymbols[weekday - 1])
                .font(.subheadline.weight(.semibold))
                .frame(width: 36, height: 36)
                .background(selected ? Color.omoPrimary : Color.omoInk.opacity(0.06), in: Circle())
                .foregroundStyle(selected ? Color.omoOnPrimary : Color.omoInk)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Calendar.current.weekdaySymbols[weekday - 1])
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// On the Focus tab while a schedule is blocking.
struct ScheduleStatusCard: View {
    @Environment(BlockListStore.self) private var blockLists
    @Environment(AppRouter.self) private var router

    var body: some View {
        TimelineView(.everyMinute) { context in
            let active = blockLists.schedules.filter { schedule in
                schedule.isActive(at: context.date) && blockLists.list(id: schedule.blockListID).map { !$0.isEmpty } == true
            }
            if let first = active.first, let list = blockLists.list(id: first.blockListID) {
                NavigationLink {
                    SchedulesScreen()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title)
                            .foregroundStyle(Color.omoPrimary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(first.name) is on")
                                .font(.headline)
                            Text(statusText(first, list: list, others: active.count - 1, now: context.date))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                    .card()
                }
                .buttonStyle(PressableCardStyle())
            }
        }
    }

    private func statusText(_ schedule: BlockSchedule, list: BlockList, others: Int, now: Date) -> String {
        let until = schedule.endDate(after: now).map { " until \($0.formatted(date: .omitted, time: .shortened))" } ?? ""
        let more = others > 0 ? " · \(others) more schedule\(others == 1 ? "" : "s") on" : ""
        return "\(list.emoji) \(list.name) is blocked\(until)\(more)"
    }
}
