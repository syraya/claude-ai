import SwiftUI
import FamilyControls

struct BlockListsView: View {
    @Environment(BlockListStore.self) private var blockLists
    @Environment(FocusController.self) private var focus

    @State private var editing: BlockList?
    @State private var creating: BlockList?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if blockLists.lists.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "square.stack.3d.up.slash")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("No block lists yet")
                                .font(.headline)
                            Text("Make lists like “Social”, “Games” or “Everything but music” and pick one each time you focus.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    }

                    ForEach(blockLists.lists) { list in
                        Button { editing = list } label: { row(list) }
                            .buttonStyle(.plain)
                    }

                    Text("Apple lets one list block up to 50 individual apps. Pick whole categories if you need more.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding()
            }
            .background(OmoBackground())
            .navigationTitle("Block Lists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        creating = BlockList(name: "")
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editing) { list in
                BlockListEditorView(list: list, isNew: false)
            }
            .sheet(item: $creating) { list in
                BlockListEditorView(list: list, isNew: true)
            }
        }
    }

    private func row(_ list: BlockList) -> some View {
        HStack(spacing: 14) {
            Text(list.emoji)
                .font(.largeTitle)
            VStack(alignment: .leading, spacing: 6) {
                Text(list.name).font(.headline)
                Text(list.summary).font(.subheadline).foregroundStyle(.secondary)
                if !list.selection.applicationTokens.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(list.selection.applicationTokens.prefix(6)), id: \.self) { token in
                            Label(token)
                                .labelStyle(.iconOnly)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .card()
    }
}

struct BlockListEditorView: View {
    @Environment(BlockListStore.self) private var blockLists
    @Environment(FocusController.self) private var focus
    @Environment(\.dismiss) private var dismiss

    @State var list: BlockList
    var isNew: Bool
    var onSave: ((BlockList) -> Void)?

    @State private var showPicker = false
    @State private var confirmDelete = false

    private let emojis = ["🚫", "📱", "🎮", "📺", "🛍️", "💬", "🎵", "📰", "🍿", "🧠", "📚", "🌙"]

    init(list: BlockList, isNew: Bool, onSave: ((BlockList) -> Void)? = nil) {
        _list = State(initialValue: list)
        self.isNew = isNew
        self.onSave = onSave
    }

    private var canSave: Bool {
        !list.name.trimmingCharacters(in: .whitespaces).isEmpty && !list.isEmpty
    }

    /// Editing the list a running session uses would change nothing until next time.
    private var isInUse: Bool {
        focus.session?.blockListName == list.name && !isNew
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Social media", text: $list.name)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(emojis, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.title2)
                                    .padding(6)
                                    .background(list.emoji == emoji ? Color.omoPrimary.opacity(0.4) : .clear, in: Circle())
                                    .onTapGesture { list.emoji = emoji }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showPicker = true
                    } label: {
                        Label(list.isEmpty ? "Choose apps & websites" : "Change apps & websites",
                              systemImage: "app.badge.checkmark")
                    }
                    if !list.isEmpty {
                        Text(list.summary).foregroundStyle(.secondary)
                    }
                    ForEach(Array(list.selection.applicationTokens), id: \.self) { token in
                        Label(token)
                    }
                    ForEach(Array(list.selection.categoryTokens), id: \.self) { token in
                        Label(token)
                    }
                    ForEach(Array(list.selection.webDomainTokens), id: \.self) { token in
                        Label(token)
                    }
                } header: {
                    Text("Blocked")
                } footer: {
                    if isInUse {
                        Text("Changes apply from your next session.")
                    }
                }

                if !isNew {
                    Section {
                        Button("Delete list", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(OmoBackground())
            .navigationTitle(isNew ? "New block list" : list.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        list.name = list.name.trimmingCharacters(in: .whitespaces)
                        blockLists.save(list)
                        onSave?(list)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .familyActivityPicker(isPresented: $showPicker, selection: $list.selection)
            .confirmationDialog("Delete “\(list.name)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    blockLists.delete(list)
                    dismiss()
                }
            }
        }
    }
}
