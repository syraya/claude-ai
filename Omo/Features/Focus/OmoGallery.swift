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
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button {
            router.showOmoGallery = true
        } label: {
            HStack(alignment: .center, spacing: 18) {
                OmoFigure(companion: selected, size: 128)
                    .hovering(5)
                    .scaleEffect(1 - 0.4 * collapse, anchor: .leading)
                    .opacity(1 - collapse)

                Rectangle()
                    .fill(Color.omoInk.opacity(0.15))
                    .frame(width: 0.75, height: 96)

                VStack(alignment: .leading, spacing: 4) {
                    Text(selected.name)
                        .font(.omoSerif(.title, weight: .semibold))
                        .foregroundStyle(Color.omoInk)
                    Text(selected.epithet)
                        .font(.system(.subheadline, design: .serif).italic())
                        .foregroundStyle(Color.omoLabels)
                    Text("“\(selected.whisper)”")
                        .font(.system(.footnote, design: .serif).italic())
                        .foregroundStyle(Color.omoLabels)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                    Label("All OMOs · \(OmoCompanion.allCases.filter { $0.isUnlocked(stats) }.count) of \(OmoCompanion.allCases.count)",
                          systemImage: "square.grid.2x2")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.omoPrimary)
                        .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(selected.name), \(selected.epithet). Show all OMOs")
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
