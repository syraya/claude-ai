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

/// One OMO's figure. Locked ones show as a dark silhouette.
struct OmoFigure: View {
    var companion: OmoCompanion
    var size: CGFloat
    var locked = false

    var body: some View {
        Image(companion.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .colorMultiply(locked ? Color(white: 0.15) : .white)
            .opacity(locked ? 0.45 : 1)
            .accessibilityLabel(locked ? "\(companion.name), locked" : companion.name)
    }
}

/// The top of the Focus tab: your OMO, large and hovering, with the others in a row
/// beneath it to pick from. `collapse` (0...1) shrinks it away as you scroll down.
struct OmoHeader: View {
    var selected: OmoCompanion
    var totalMinutes: Int
    var collapse: CGFloat
    var onSelect: (OmoCompanion) -> Void

    @State private var inspected: OmoCompanion?

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
                    ForEach(Array(OmoCompanion.allCases.enumerated()), id: \.element) { index, companion in
                        let locked = !companion.isUnlocked(totalMinutes: totalMinutes)
                        Button {
                            if locked {
                                inspected = inspected == companion ? nil : companion
                            } else {
                                inspected = nil
                                onSelect(companion)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                ZStack(alignment: .bottomTrailing) {
                                    OmoFigure(companion: companion, size: 58, locked: locked)
                                        .overlay(
                                            Circle().stroke(Color.omoPrimary, lineWidth: companion == selected ? 3 : 0)
                                                .padding(-3)
                                        )
                                    if locked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(5)
                                            .background(Color.omoInk.opacity(0.8), in: Circle())
                                    }
                                }
                                .hovering(3, delay: Double(index) * 0.25)
                                Text(locked ? "\(companion.requiredHours.formatted()) h" : companion.name)
                                    .font(.caption2.weight(companion == selected ? .bold : .regular))
                                    .foregroundStyle(companion == selected ? Color.omoPrimary : .secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }

            if let inspected {
                lockedInfo(inspected)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: inspected)
    }

    private func lockedInfo(_ companion: OmoCompanion) -> some View {
        let title = FocusRank.all.first { $0.hours == companion.requiredHours }?.title ?? "a new title"
        let left = max(0, companion.requiredHours * 60 - totalMinutes)
        let leftText = left < 60 ? "\(left) minutes" : "\(LifetimeFormat.hours(left)) hours"
        return HStack(alignment: .top, spacing: 14) {
            OmoFigure(companion: companion, size: 54, locked: true)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(companion.name), \(companion.epithet.lowercased())").font(.headline)
                Text(companion.story).font(.subheadline).foregroundStyle(.secondary)
                Text("Joins you when you become a \(title) at \(companion.requiredHours.formatted()) hours of focus. \(leftText) to go.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.omoClay)
                Text("Brings: \(companion.themeDescription)")
                    .font(.caption)
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
