import SwiftUI

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

    private let presets = [15, 25, 45, 60, 90, 120]

    private var selectedList: BlockList? {
        blockLists.list(id: selectedListID) ?? blockLists.lists.first
    }

    private var canStart: Bool {
        screenTime.isApproved && !(selectedList?.isEmpty ?? true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("New focus session")
                .font(.omoSerif(.title3))

            VStack(alignment: .leading, spacing: 10) {
                Text("Block").font(.subheadline).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(blockLists.lists) { list in
                            listChip(list)
                        }
                        Button {
                            editingList = BlockList(name: "")
                        } label: {
                            Label("New list", systemImage: "plus")
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.omoInk.opacity(0.06), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                if let list = selectedList, list.isEmpty {
                    Text("“\(list.name)” has no apps yet. Add some in Block Lists.")
                        .font(.footnote)
                        .foregroundStyle(Color.omoGold)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Intention").font(.subheadline).foregroundStyle(.secondary)
                TextField("e.g. Finish chapter 4 of biology", text: $intention)
                    .font(.system(.body, design: .serif))
                    .padding(12)
                    .background(Color.omoGold.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                Text("Write down what this session is for. It shows on your timer and on blocked apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("For").font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Stepper(Format.minutes(minutes), value: $minutes, in: 5...720, step: 5)
                        .fixedSize()
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            Button(Format.minutes(preset)) { minutes = preset }
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(minutes == preset ? Color.omoPrimary : Color.omoInk.opacity(0.06), in: Capsule())
                                .foregroundStyle(minutes == preset ? .white : .primary)
                                .buttonStyle(.plain)
                        }
                    }
                }
            }

            VStack(spacing: 4) {
                Toggle(isOn: $allowsBreaks) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Allow breaks")
                        Text("Up to \(settings.settings.maxBreaksPerSession), each after a \(settings.settings.reflectionSeconds)s pause")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Toggle(isOn: $strictMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Strict mode")
                        Text("No ending the session early")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .tint(.omoPrimary)

            Button {
                guard let list = selectedList else { return }
                focus.start(blockList: list,
                            minutes: minutes,
                            allowsBreaks: allowsBreaks,
                            allowsEndingEarly: !strictMode,
                            maxBreaks: settings.settings.maxBreaksPerSession,
                            intention: intention.trimmingCharacters(in: .whitespacesAndNewlines))
                intention = ""
                settings.settings.defaultSessionMinutes = minutes
            } label: {
                Label("Start focusing", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canStart)
            .opacity(canStart ? 1 : 0.5)
        }
        .card()
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
    }

    private func listChip(_ list: BlockList) -> some View {
        let isSelected = list.id == selectedList?.id
        return Button {
            selectedListID = list.id
        } label: {
            HStack(spacing: 6) {
                Text(list.emoji)
                Text(list.name).fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.omoPrimary : Color.omoInk.opacity(0.06), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
