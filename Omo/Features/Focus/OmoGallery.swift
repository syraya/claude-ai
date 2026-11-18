import SwiftUI

/// Gently floats a view up and down, like it's hovering.
private struct Hover: ViewModifier {
    var distance: CGFloat
    var delay: Double
    @State private var up = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(y: up ? -distance : distance)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(delay)) {
                    up = true
                }
            }
    }
}

extension View {
    func hovering(_ distance: CGFloat = 4, delay: Double = 0) -> some View {
        modifier(Hover(distance: distance, delay: delay))
    }
}

/// One OMO's figure. Locked ones show as a dark silhouette. With `backdrop`, the figure
/// sits on a circle of its own theme colour, so pale figures (like Selene) stay visible
/// on any theme.
struct OmoFigure: View {
    var companion: OmoCompanion
    var size: CGFloat
    var locked = false
    var backdrop = false

    var body: some View {
        Image(companion.imageName)
            .resizable()
            .scaledToFit()
            .padding(backdrop ? size * 0.1 : 0)
            .saturation(locked ? 0.25 : 1)
            .opacity(locked ? 0.45 : 1)
            .frame(width: size, height: size)
            .background {
                if backdrop {
                    Circle()
                        .fill(locked ? Color.omoInk.opacity(0.07) : Color(companion.palette.paper))
                        .overlay(Circle().stroke(Color.omoInk.opacity(0.12), lineWidth: 1))
                }
            }
            .accessibilityLabel(locked ? "\(companion.name), locked" : companion.name)
    }
}

/// The top of the Focus tab: your OMO, large and hovering, with the others in a row
/// beneath it to pick from. `collapse` (0...1) shrinks it away as you scroll down.
struct OmoHeader: View {
    var selected: OmoCompanion
    var stats: LifetimeStats
    var collapse: CGFloat
    var onSelect: (OmoCompanion) -> Void

    @State private var inspected: OmoCompanion?
    @State private var showCollection = false

    /// Yours first, then the ones still to earn.
    private var ordered: [OmoCompanion] {
        let all = OmoCompanion.allCases
        return all.filter { $0.isUnlocked(stats) } + all.filter { !$0.isUnlocked(stats) }
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 10) {
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(Color.omoInk.opacity(0.10))
                        .frame(width: 90, height: 12)
                        .blur(radius: 4)
                        .offset(y: 10)
                    OmoFigure(companion: selected, size: 150)
                        .shadow(color: Color.omoInk.opacity(0.18), radius: 14, y: 10)
                        .hovering(6)
                }
                .scaleEffect(1 - 0.45 * collapse, anchor: .top)
                .opacity(1 - collapse)

                VStack(spacing: 3) {
                    Text(selected.name)
                        .font(.omoSerif(.title2, weight: .bold))
                        .foregroundStyle(Color.omoInk)
                    Text(selected.epithet.uppercased())
                        .font(.caption2.weight(.semibold))
                        .kerning(1.5)
                        .foregroundStyle(Color.omoLabels)
                }
                Text("“\(selected.whisper)”")
                    .font(.system(.body, design: .serif).italic())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(ordered.enumerated()), id: \.element) { index, companion in
                        OmoPickButton(companion: companion,
                                      locked: !companion.isUnlocked(stats),
                                      isSelected: companion == selected,
                                      hoverDelay: Double(index) * 0.25) {
                            tap(companion)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            Button {
                showCollection = true
            } label: {
                Label("All OMOs · \(OmoCompanion.allCases.filter { $0.isUnlocked(stats) }.count) of \(OmoCompanion.allCases.count)",
                      systemImage: "square.grid.3x3.fill")
                    .font(.footnote.weight(.semibold))
            }
            .tint(.omoPrimary)

            if let inspected {
                OmoLockedInfo(companion: inspected, stats: stats)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: inspected)
        .sheet(isPresented: $showCollection) {
            OmoCollectionView(selected: selected, stats: stats) { companion in
                onSelect(companion)
                showCollection = false
            }
        }
    }

    private func tap(_ companion: OmoCompanion) {
        if companion.isUnlocked(stats) {
            inspected = nil
            onSelect(companion)
        } else {
            inspected = inspected == companion ? nil : companion
        }
    }
}

/// One OMO in the floating row.
struct OmoPickButton: View {
    var companion: OmoCompanion
    var locked: Bool
    var isSelected: Bool
    var hoverDelay: Double
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .bottomTrailing) {
                    OmoFigure(companion: companion, size: 62, locked: locked, backdrop: true)
                        .overlay(
                            Circle().stroke(Color.omoPrimary, lineWidth: isSelected ? 3 : 0)
                                .padding(-3)
                        )
                    if locked {
                        Image(systemName: companion.kind == .holiday ? "calendar" : "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.omoPaper)
                            .padding(5)
                            .background(Color.omoInk.opacity(0.8), in: Circle())
                    }
                }
                .hovering(3, delay: hoverDelay)
                Text(locked ? companion.shortRequirement : companion.name)
                    .font(.caption2.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.omoPrimary : .secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 74)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

/// Who a locked OMO is, and how to earn it.
struct OmoLockedInfo: View {
    var companion: OmoCompanion
    var stats: LifetimeStats

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            OmoFigure(companion: companion, size: 58, locked: true, backdrop: true)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(companion.name), \(companion.epithet.lowercased())").font(.headline)
                Text(companion.story).font(.subheadline).foregroundStyle(.secondary)
                Text(companion.requirement)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.omoLabels)
                if let progress = companion.progress(stats) {
                    Text(progress).font(.caption).foregroundStyle(.secondary)
                }
                Text("Brings: \(companion.themeDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

/// Every OMO, grouped by how you earn it.
struct OmoCollectionView: View {
    var selected: OmoCompanion
    var stats: LifetimeStats
    var onSelect: (OmoCompanion) -> Void

    @State private var kind: OmoCompanion.Kind = .path
    @State private var inspected: OmoCompanion?
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Group", selection: $kind) {
                        ForEach(OmoCompanion.Kind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    let collected = OmoCompanion.allCases.filter { $0.isUnlocked(stats) }.count
                    Text("\(collected) of \(OmoCompanion.allCases.count) collected · \(caption(for: kind))")
                        .font(.footnote)
                        .foregroundStyle(Color.omoLabels)

                    if let inspected, inspected.kind == kind {
                        OmoLockedInfo(companion: inspected, stats: stats)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(OmoCompanion.allCases.filter { $0.kind == kind }) { companion in
                            tile(companion)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .animation(.easeInOut(duration: 0.2), value: inspected)
            }
            .background(OmoBackground())
            .navigationTitle("Your OMOs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func caption(for kind: OmoCompanion.Kind) -> String {
        switch kind {
        case .path: return "One for each title, earned with focus hours."
        case .milestone: return "Earned with friends, sessions, streaks and Study Circles."
        case .holiday: return "Focus \(OmoHoliday.requiredMinutes) minutes on the day to keep one."
        }
    }

    /// A tile in the OMO's own colours, like a small painted panel.
    private func tile(_ companion: OmoCompanion) -> some View {
        let locked = !companion.isUnlocked(stats)
        let palette = companion.palette
        return Button {
            if locked {
                inspected = inspected == companion ? nil : companion
            } else {
                onSelect(companion)
            }
        } label: {
            VStack(spacing: 6) {
                Image(companion.imageName)
                    .resizable()
                    .scaledToFit()
                    .saturation(locked ? 0.25 : 1)
                    .opacity(locked ? 0.45 : 1)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .frame(maxHeight: .infinity)
                Text(companion.name)
                    .font(.omoSerif(.headline))
                    .foregroundStyle(Color(palette.ink))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.92, contentMode: .fit)
            .background(Color(palette.paper), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(companion == selected ? Color(palette.gold) : Color.omoInk.opacity(0.08),
                            lineWidth: companion == selected ? 2.5 : 0.75)
            )
            .overlay(alignment: .topTrailing) {
                if companion == selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color(palette.onPrimary), Color(palette.gold))
                        .padding(8)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if locked {
                    Label(companion.shortRequirement,
                          systemImage: companion.kind == .holiday ? "calendar" : "lock.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(palette.paper))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color(palette.ink).opacity(0.85), in: Capsule())
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(locked ? "\(companion.name), locked. \(companion.requirement)" : companion.name)
        .accessibilityAddTraits(companion == selected ? .isSelected : [])
    }
}

/// Shown on the Focus tab during a holiday whose OMO you haven't earned yet.
struct HolidayCard: View {
    var holiday: OmoHoliday
    var companion: OmoCompanion

    var body: some View {
        HStack(spacing: 14) {
            OmoFigure(companion: companion, size: 64, backdrop: true)
                .hovering(3)
            VStack(alignment: .leading, spacing: 4) {
                Text("It's \(holiday.name)").font(.omoSerif(.headline))
                Text("Focus for \(OmoHoliday.requiredMinutes) minutes today and \(companion.name) joins you for good.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

/// Your OMO, minimised, hovering in the corner while you scroll.
struct MiniOmo: View {
    var companion: OmoCompanion

    var body: some View {
        OmoFigure(companion: companion, size: 54)
            .shadow(color: Color.omoInk.opacity(0.25), radius: 8, y: 5)
            .hovering(4)
    }
}

/// Reports how far the Focus tab has scrolled.
struct HeaderOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
