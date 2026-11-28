import SwiftUI

/// Picking your OMO: swipe through each collection, each OMO standing in its own
/// landscape across the top of the sheet, with the whole sheet taking on the colours
/// of the one you're looking at. Choosing is a separate
/// tap, so browsing never changes anything; it closes the gallery and the app's usual
/// OMO transition plays. "Index" lists every OMO with a search.
struct OmoCollectionView: View {
    var selected: OmoCompanion
    var stats: LifetimeStats
    var onSelect: (OmoCompanion) -> Void

    @State private var kind: OmoCompanion.Kind
    @State private var focused: OmoCompanion?
    @State private var showIndex = false
    /// An OMO picked from the thumbnails or the index, for the carousel to glide to.
    /// Swiping never sets this, so the carousel never moves under your finger.
    @State private var jumpTo: OmoCompanion?
    @Namespace private var tabs
    /// Height of the header, tabs and counter laid over the scene, so the figure
    /// always stands clear below them.
    @State private var overlayHeight: CGFloat = 140
    @Environment(\.dismiss) private var dismiss

    /// `previewing` opens on another OMO than yours (used for screenshots).
    init(selected: OmoCompanion, stats: LifetimeStats, previewing: OmoCompanion? = nil,
         onSelect: @escaping (OmoCompanion) -> Void) {
        self.selected = selected
        self.stats = stats
        self.onSelect = onSelect
        _kind = State(initialValue: (previewing ?? selected).kind)
        _focused = State(initialValue: previewing ?? selected)
    }

    private var shown: OmoCompanion { focused ?? selected }
    private var palette: ThemePalette { shown.palette }
    private var members: [OmoCompanion] { OmoCompanion.allCases.filter { $0.kind == kind } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // The scene runs edge to edge behind the header and fades into the
                // page; swiping moves the whole landscape.
                ZStack(alignment: .top) {
                    carousel
                        .id(kind)
                        .transition(.opacity)
                    VStack(spacing: 0) {
                        header
                        OmoKindTabs(kind: $kind, palette: palette, namespace: tabs)
                            .padding(.top, 16)
                        HStack {
                            Spacer()
                            Text(String(format: "%02d / %02d", (members.firstIndex(of: shown) ?? 0) + 1, members.count))
                                .font(.system(.subheadline, design: .serif).monospacedDigit())
                                .foregroundStyle(Color(palette.labels))
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    }
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: OverlayHeightKey.self, value: proxy.size.height)
                    })
                }
                .onPreferenceChange(OverlayHeightKey.self) { overlayHeight = $0 }
                .frame(minHeight: 340, maxHeight: 600)

                // Words and controls keep their size; the scene above takes what's left,
                // so everything fits however tall the sheet is.
                details
                    .padding(.bottom, 12)
                    .fixedSize(horizontal: false, vertical: true)

                thumbnails

                chooseButton
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
            }
            .background(Color(palette.paper).ignoresSafeArea())
            .animation(.easeInOut(duration: 0.35), value: shown)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showIndex) {
                OmoIndexView(selected: selected, stats: stats, palette: palette,
                             onClose: { dismiss() },
                             onOpen: { companion in
                                 withAnimation(.spring(duration: 0.5, bounce: 0.1)) {
                                     kind = companion.kind
                                     focused = companion
                                 }
                                 jumpTo = companion
                                 showIndex = false
                             })
            }
        }
        .onChange(of: kind) { _, newKind in
            // A new collection starts on your OMO if it's in it, else on its first.
            guard shown.kind != newKind else { return }
            focused = newKind == selected.kind ? selected : OmoCompanion.allCases.first { $0.kind == newKind }
        }
    }

    private var header: some View {
        ZStack {
            Text("Your OMOs")
                .font(.omoSerif(.title3, weight: .semibold))
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.title3.weight(.medium))
                }
                .accessibilityLabel("Close")
                Spacer()
                Button { showIndex = true } label: {
                    Label("Index", systemImage: "list.bullet").font(.subheadline)
                }
            }
        }
        .foregroundStyle(Color(palette.ink))
        .padding(.horizontal, 20)
        .padding(.top, 22)
    }

    // MARK: Carousel

    private var carousel: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(members) { companion in
                        OmoScenePanel(companion: companion,
                                      locked: companion != selected && !companion.isUnlocked(stats),
                                      topInset: overlayHeight)
                            .containerRelativeFrame(.horizontal)
                            .id(companion)
                    }
                }
                .scrollTargetLayout()
            }
            // Follows your finger, so you can hold it halfway; letting go settles on
            // the nearest OMO, and a flick moves one at a time.
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $focused, anchor: .center)
            // Opening (or switching collection) lands on the right OMO. Swiping only
            // reports back through `focused`; it's never scrolled for you mid-drag.
            .onAppear { reader.scrollTo(shown, anchor: .center) }
            .onChange(of: jumpTo) { _, companion in
                guard let companion else { return }
                withAnimation(.spring(duration: 0.5, bounce: 0.1)) { reader.scrollTo(companion, anchor: .center) }
                jumpTo = nil
            }
        }
    }

    private var details: some View {
        let locked = shown != selected && !shown.isUnlocked(stats)
        return VStack(spacing: 4) {
            Text(shown.name)
                .font(.omoSerif(.largeTitle, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(shown.epithet)
                .font(.body)
                .foregroundStyle(Color(palette.labels))
            Text(locked ? shown.requirement : shown.story)
                .font(.body)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
                .minimumScaleFactor(0.85)
                .padding(.top, 4)
        }
        .foregroundStyle(Color(palette.ink))
        .padding(.horizontal, 28)
        .contentTransition(.opacity)
    }

    private var thumbnails: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(members) { companion in
                        Button {
                            withAnimation(.spring(duration: 0.5, bounce: 0.1)) { focused = companion }
                            jumpTo = companion
                        } label: {
                            OmoThumb(companion: companion,
                                     locked: companion != selected && !companion.isUnlocked(stats),
                                     isCurrent: companion == selected,
                                     isFocused: companion == shown,
                                     palette: palette)
                        }
                        .buttonStyle(PressableCardStyle())
                        .id(companion)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .onChange(of: shown) { _, companion in
                withAnimation(.easeInOut(duration: 0.3)) { reader.scrollTo(companion, anchor: .center) }
            }
            .onAppear { reader.scrollTo(shown, anchor: .center) }
        }
    }

    @ViewBuilder
    private var chooseButton: some View {
        let locked = !shown.isUnlocked(stats)
        VStack(spacing: 8) {
            if shown == selected {
                Button {} label: { Label("Current OMO", systemImage: "checkmark") }
                    .buttonStyle(PrimaryButtonStyle(color: Color(palette.primary), textColor: Color(palette.onPrimary)))
                    .allowsHitTesting(false)
                Text("Changes your app and breathing scene")
            } else if locked {
                let fraction = shown.progressFraction(stats)
                if let fraction {
                    LockedProgress(fraction: fraction, label: shown.progress(stats) ?? "", palette: palette)
                        .padding(.bottom, 4)
                }
                Button {} label: { Label(shown.lockText, systemImage: "lock.fill") }
                    .buttonStyle(SecondaryButtonStyle(color: Color(palette.labels)))
                    .allowsHitTesting(false)
                Text(fraction == nil ? (shown.progress(stats) ?? "Previewing · \(selected.name) is still selected")
                                     : "Previewing · \(selected.name) is still selected")
            } else {
                Button("Choose \(shown.name)") {
                    dismiss()
                    onSelect(shown)
                }
                    .buttonStyle(PrimaryButtonStyle(color: Color(palette.primary), textColor: Color(palette.onPrimary)))
                Text("Previewing · \(selected.name) is still selected")
            }
        }
        .font(.footnote)
        .foregroundStyle(Color(palette.labels))
    }
}

// MARK: - Pieces

private struct OverlayHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 140
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// The three collections, with a gold rule under the one you're in.
struct OmoKindTabs: View {
    @Binding var kind: OmoCompanion.Kind
    var palette: ThemePalette
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(OmoCompanion.Kind.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(duration: 0.45, bounce: 0.12)) { kind = tab }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(.body, design: .serif).weight(tab == kind ? .semibold : .regular))
                            .foregroundStyle(Color(palette.ink).opacity(tab == kind ? 1 : 0.75))
                        ZStack {
                            Color.clear.frame(height: 2.5)
                            if tab == kind {
                                Capsule()
                                    .fill(Color(palette.gold))
                                    .frame(width: 100, height: 2.5)
                                    .matchedGeometryEffect(id: "tab", in: namespace)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == kind ? .isSelected : [])
            }
        }
        .padding(.horizontal, 16)
    }
}

/// One OMO in its landscape, full width. The painting's top fades into its sky and
/// its foot into the page, and the figure always stands whole below the header.
struct OmoScenePanel: View {
    var companion: OmoCompanion
    var locked: Bool
    var topInset: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let scene = BreathingScene(for: companion)
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(colors: [Color(scene.sky), Color(scene.sky), Color(companion.palette.paper)],
                               startPoint: .top, endPoint: .bottom)
                SceneArt(scene: scene, size: proxy.size, topInset: topInset)
                    .saturation(locked ? 0.2 : 1)
                    .opacity(locked ? 0.55 : 1)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundStyle(Color(companion.palette.ink).opacity(0.7))
                        .padding(12)
                        .background(Color(companion.palette.paper).opacity(0.85), in: Circle())
                        .padding(20)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .accessibilityElement()
        .accessibilityLabel(locked ? "\(companion.name), locked" : companion.name)
    }
}

/// How close you are to a locked OMO: a slim bar in the OMO's gold with the count.
private struct LockedProgress: View {
    var fraction: Double
    var label: String
    var palette: ThemePalette

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(palette.ink))
                Spacer(minLength: 8)
                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Color(palette.labels))
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(palette.ink).opacity(0.1))
                    Capsule().fill(Color(palette.gold))
                        .frame(width: max(6, proxy.size.width * fraction))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

/// A small tile in the strip under the scene.
private struct OmoThumb: View {
    var companion: OmoCompanion
    var locked: Bool
    var isCurrent: Bool
    var isFocused: Bool
    var palette: ThemePalette

    var body: some View {
        VStack(spacing: 6) {
            OmoTile(companion: companion, locked: locked)
                .frame(width: 68, height: 68)
                .overlay(
                    RoundedRectangle(cornerRadius: 68 * 0.26, style: .continuous)
                        .stroke(Color(palette.gold), lineWidth: isFocused ? 2.5 : 0)
                )
                .overlay(alignment: .topTrailing) {
                    if isCurrent {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color(palette.onPrimary), Color(palette.gold))
                            .offset(x: 4, y: -2)
                    }
                }
            Text(companion.name)
                .font(.system(.footnote, design: .serif).weight(isFocused ? .semibold : .regular))
                .foregroundStyle(Color(palette.ink))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 72)
            Capsule()
                .fill(Color(palette.gold))
                .frame(width: 36, height: 2)
                .opacity(isFocused ? 1 : 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(companion.name + (isCurrent ? ", current" : "") + (locked ? ", locked" : ""))
    }
}

/// The OMO's painting placed so its figure is always whole: scaled until the figure
/// fills a box below the header, centred on the figure, and never leaving a gap at
/// the sides. The painting fades into its sky at the top and the page at the bottom.
private struct SceneArt: View {
    var scene: BreathingScene
    var size: CGSize
    var topInset: CGFloat

    var body: some View {
        let fade = LinearGradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.18),
            .init(color: .black, location: 0.86),
            .init(color: .clear, location: 1),
        ], startPoint: .top, endPoint: .bottom)
        if let focus = scene.focus {
            let art = CGSize(width: 1000 * scene.aspectRatio, height: 1000)
            let frame = Self.layout(art: art, focus: focus, in: size, topInset: topInset)
            SceneCanvas(scene: scene, fade: fade)
                .frame(width: frame.width, height: frame.height)
                .offset(x: frame.minX, y: frame.minY)
                .frame(width: size.width, height: size.height, alignment: .topLeading)
        } else {
            Image(scene.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
                .mask(fade)
        }
    }

    /// The painting's frame in the panel.
    static func layout(art: CGSize, focus: CGRect, in panel: CGSize, topInset: CGFloat) -> CGRect {
        let W = panel.width, H = panel.height
        // The figure stands in a box 62% of the width, from a little below the header
        // to 84% of the way down, with landscape around it and clear of the fade.
        let box = CGRect(x: W * 0.19, y: topInset + 24, width: W * 0.62,
                         height: max(80, H * 0.84 - topInset - 24))
        let fitWidth = box.width / max(focus.width * art.width, 1)
        let fitHeight = box.height / max(focus.height * art.height, 1)
        let cover = W / art.width
        let scale = max(min(fitWidth, fitHeight), cover)
        let w = art.width * scale, h = art.height * scale
        var x = box.midX - focus.midX * w
        x = min(0, max(W - w, x))
        let y = box.maxY - focus.maxY * h
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

/// The OMO's figure on its own colour, in a rounded square. Used in the strip and the index.
struct OmoTile: View {
    var companion: OmoCompanion
    var locked: Bool

    var body: some View {
        GeometryReader { proxy in
            let shape = RoundedRectangle(cornerRadius: proxy.size.width * 0.26, style: .continuous)
            Image(companion.imageName)
                .resizable()
                .scaledToFit()
                .padding(proxy.size.width * 0.12)
                .saturation(locked ? 0.25 : 1)
                .opacity(locked ? 0.5 : 1)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background(Color(companion.palette.paper))
                .clipShape(shape)
                .overlay(shape.stroke(Color.black.opacity(0.06), lineWidth: 1))
        }
    }
}

// MARK: - Index

/// Every OMO as a list, by collection, with a search.
struct OmoIndexView: View {
    var selected: OmoCompanion
    var stats: LifetimeStats
    var palette: ThemePalette
    var onClose: () -> Void
    var onOpen: (OmoCompanion) -> Void

    @State private var kind: OmoCompanion.Kind
    @State private var search = ""
    @State private var showAll = false
    @Namespace private var tabs

    init(selected: OmoCompanion, stats: LifetimeStats, palette: ThemePalette,
         onClose: @escaping () -> Void, onOpen: @escaping (OmoCompanion) -> Void) {
        self.selected = selected
        self.stats = stats
        self.palette = palette
        self.onClose = onClose
        self.onOpen = onOpen
        _kind = State(initialValue: selected.kind)
    }

    private var query: String { search.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Color(palette.labels))
                    TextField("Find an OMO", text: $search)
                        .foregroundStyle(Color(palette.ink))
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(palette.card), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(palette.ink).opacity(0.15), lineWidth: 0.75))

                if query.isEmpty {
                    OmoKindTabs(kind: $kind, palette: palette, namespace: tabs)
                    section
                    otherCollections
                    Text("\(OmoCompanion.allCases.count) OMOs across three collections")
                        .font(.footnote)
                        .foregroundStyle(Color(palette.labels))
                        .padding(.top, 4)
                } else {
                    let matches = OmoCompanion.allCases.filter {
                        $0.name.localizedCaseInsensitiveContains(query) || $0.epithet.localizedCaseInsensitiveContains(query)
                    }
                    if matches.isEmpty {
                        Text("No OMO called “\(query)”")
                            .foregroundStyle(Color(palette.labels))
                            .padding(.top, 30)
                    } else {
                        rows(matches)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .animation(.easeInOut(duration: 0.25), value: kind)
            .animation(.easeInOut(duration: 0.25), value: showAll)
            .animation(.easeInOut(duration: 0.2), value: query)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(palette.paper).ignoresSafeArea())
        .navigationTitle("Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color(palette.paper), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onClose) { Image(systemName: "xmark") }
                    .accessibilityLabel("Close")
            }
        }
        .tint(Color(palette.ink))
        .onChange(of: kind) { _, _ in showAll = false }
    }

    private var section: some View {
        let members = OmoCompanion.allCases.filter { $0.kind == kind }
        let collected = members.filter { $0.isUnlocked(stats) }.count
        let visible = showAll ? members : Array(members.prefix(6))
        return VStack(spacing: 8) {
            HStack {
                Text(kind.rawValue.uppercased())
                    .font(.system(.footnote, design: .serif).weight(.semibold))
                    .kerning(1.5)
                Spacer()
                Text("\(collected) of \(members.count) collected")
                    .font(.system(.footnote, design: .serif))
            }
            .foregroundStyle(Color(palette.ink))
            rows(visible)
            if members.count > visible.count {
                Button("View all \(members.count)") { showAll = true }
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .underline(color: Color(palette.gold))
                    .foregroundStyle(Color(palette.ink))
                    .padding(.top, 6)
            }
        }
    }

    private func rows(_ companions: [OmoCompanion]) -> some View {
        VStack(spacing: 0) {
            ForEach(companions) { companion in
                Button { onOpen(companion) } label: { row(companion) }
                    .buttonStyle(.plain)
                Divider().overlay(Color(palette.ink).opacity(0.1))
            }
        }
    }

    private func row(_ companion: OmoCompanion) -> some View {
        let locked = !companion.isUnlocked(stats)
        return HStack(spacing: 14) {
            OmoTile(companion: companion, locked: locked)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(companion.name)
                    .font(.omoSerif(.title3, weight: .semibold))
                    .foregroundStyle(Color(palette.ink))
                Text(companion.epithet)
                    .font(.subheadline)
                    .foregroundStyle(Color(palette.labels))
            }
            Spacer(minLength: 8)
            if companion == selected {
                Label("Current", systemImage: "checkmark")
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(Color(palette.gold))
            } else if locked {
                Label(companion.lockText, systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(Color(palette.ink))
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color(palette.ink))
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var otherCollections: some View {
        VStack(spacing: 10) {
            ForEach(OmoCompanion.Kind.allCases.filter { $0 != kind }, id: \.self) { other in
                Button {
                    withAnimation(.spring(duration: 0.45, bounce: 0.12)) { kind = other }
                } label: {
                    HStack {
                        Text(other.rawValue)
                            .font(.omoSerif(.title3, weight: .semibold))
                        Spacer()
                        Text("\(OmoCompanion.allCases.filter { $0.kind == other }.count) OMOs")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(Color(palette.ink))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(palette.card), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(palette.ink).opacity(0.15), lineWidth: 0.75))
                }
                .buttonStyle(PressableCardStyle())
            }
        }
        .padding(.top, 6)
    }
}

extension OmoCompanion {
    /// What unlocks it, short enough for a button or a row, e.g. "50 focus hours".
    var lockText: String {
        switch unlock {
        case .hours(let hours): return "\(hours.formatted()) focus hours"
        default: return shortRequirement
        }
    }
}
