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
            .colorMultiply(locked ? Color(white: 0.15) : .white)
            .opacity(locked ? 0.5 : 1)
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
                        .foregroundStyle(Color.omoClay)
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
                            .foregroundStyle(.white)
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
                    .foregroundStyle(Color.omoClay)
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

    @State private var inspected: OmoCompanion?
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(OmoCompanion.Kind.allCases, id: \.self) { kind in
                        let group = OmoCompanion.allCases.filter { $0.kind == kind }
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(kind.rawValue).font(.omoSerif(.title3))
                                Spacer()
                                Text("\(group.filter { $0.isUnlocked(stats) }.count) of \(group.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(caption(for: kind)).font(.caption).foregroundStyle(.secondary)
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(group) { companion in
                                    cell(companion)
                                }
                            }
                        }
                    }
                    if let inspected {
                        OmoLockedInfo(companion: inspected, stats: stats)
                    }
                }
                .padding()
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
        case .path: return "Earned with lifetime focus hours, one for each title."
        case .milestone: return "Earned with friends, sessions, streaks and Study Circles."
        case .holiday: return "Focus for \(OmoHoliday.requiredMinutes) minutes on the day and they're yours to keep."
        }
    }

    private func cell(_ companion: OmoCompanion) -> some View {
        let locked = !companion.isUnlocked(stats)
        return Button {
            if locked {
                inspected = inspected == companion ? nil : companion
            } else {
                onSelect(companion)
            }
        } label: {
            VStack(spacing: 6) {
                OmoFigure(companion: companion, size: 80, locked: locked, backdrop: true)
                    .overlay(Circle().stroke(Color.omoPrimary, lineWidth: companion == selected ? 3 : 0).padding(-3))
                Text(companion.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(locked ? .secondary : Color.omoInk)
                    .lineLimit(1)
                Text(locked ? companion.shortRequirement : companion.epithet)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
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
