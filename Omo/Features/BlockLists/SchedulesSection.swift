import SwiftUI

/// Your schedules as a list, with their editor and the wait before turning one off.
/// Shown on the Block Lists tab and on its own page from the Focus tab.
struct SchedulesSection: View {
    @Environment(BlockListStore.self) private var blockLists
    @Environment(SettingsStore.self) private var settings

    @Binding var creatingSchedule: BlockSchedule?
    var showsTitle = true
    @State private var editingSchedule: BlockSchedule?
    /// A schedule that's blocking now, waiting on the reflection wait before it turns off.
    @State private var turningOff: BlockSchedule?

    var body: some View {
        VStack(spacing: 14) {
            if showsTitle { sectionTitle("Schedules") }
            if blockLists.schedules.isEmpty {
                Button {
                    creatingSchedule = BlockSchedule()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title)
                            .foregroundStyle(Color.omoPrimary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Block on a schedule").font(.headline)
                            Text("Like 9 to 5 on weekdays, or bedtime every night. It turns on by itself, even with OMO closed.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.omoPrimary)
                    }
                    .card()
                }
                .buttonStyle(.plain)
            }
            if !blockLists.schedules.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(blockLists.schedules.enumerated()), id: \.element.id) { index, schedule in
                        if index > 0 { Divider() }
                        ScheduleRow(schedule: schedule,
                                    list: blockLists.list(id: schedule.blockListID),
                                    onOpen: { editingSchedule = schedule },
                                    onToggle: { isOn in toggle(schedule, isOn) })
                    }
                }
                .groupedCard()
            }
        }
        .sheet(item: $editingSchedule) { schedule in
            ScheduleEditorView(schedule: schedule, isNew: false)
        }
        .fullScreenCover(item: $turningOff) { schedule in
            ReflectionView(seconds: settings.settings.reflectionSeconds,
                           title: "Turn off “\(schedule.name)” early?",
                           confirmLabel: "Turn it off",
                           onConfirm: {
                               blockLists.setEnabled(schedule, false)
                               turningOff = nil
                           },
                           onCancel: { turningOff = nil })
        }
    }

    /// Turning off a schedule that's blocking right now asks for the reflection wait first.
    private func toggle(_ schedule: BlockSchedule, _ isOn: Bool) {
        if !isOn, schedule.isActive() {
            guard !schedule.isStrict else { return }
            turningOff = schedule
        } else {
            blockLists.setEnabled(schedule, isOn)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .kerning(1.5)
            .foregroundStyle(Color.omoLabels)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

/// The schedules on a page of their own, pushed from the Focus tab.
struct SchedulesScreen: View {
    @Environment(BlockListStore.self) private var blockLists
    @State private var creatingSchedule: BlockSchedule?

    var body: some View {
        @Bindable var blockLists = blockLists
        ScrollView {
            SchedulesSection(creatingSchedule: $creatingSchedule, showsTitle: false)
                .padding()
        }
        .background(OmoBackground())
        .navigationTitle("Schedules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New schedule", systemImage: "plus") { creatingSchedule = BlockSchedule() }
                    .disabled(!blockLists.canAddSchedule)
            }
        }
        .sheet(item: $creatingSchedule) { schedule in
            ScheduleEditorView(schedule: schedule, isNew: true)
        }
        .errorAlert($blockLists.scheduleError)
    }
}
