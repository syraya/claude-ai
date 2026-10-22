import SwiftUI
import UIKit

/// Switching OMOs. The new OMO's colour spreads out from where your OMO floats, the
/// figure appears for a moment, then the new theme is revealed underneath, so even
/// going from a dark theme to a light one never snaps.
///
/// The app's colours aren't animatable (every screen is rebuilt with the new theme),
/// so the swap happens while this veil covers everything.
struct CompanionTransitionView: View {
    var companion: OmoCompanion
    /// Called once the screen is fully covered: switch the theme here.
    var onCovered: () -> Void
    /// Called when the veil has faded away.
    var onFinished: () -> Void

    @State private var spread: CGFloat = 0
    @State private var showFigure = false
    @State private var opacity = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            // Roughly where the large OMO hovers on the Focus tab.
            let origin = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.24)
            let radius = hypot(max(origin.x, geo.size.width - origin.x), max(origin.y, geo.size.height - origin.y))
            let palette = companion.palette

            ZStack {
                Circle()
                    .fill(Color(palette.paper))
                    .frame(width: radius * 2, height: radius * 2)
                    .scaleEffect(spread)
                    .position(origin)

                VStack(spacing: 10) {
                    OmoFigure(companion: companion, size: 150)
                        .shadow(color: Color(palette.ink).opacity(0.25), radius: 16, y: 10)
                    Text(companion.name)
                        .font(.omoSerif(.title2, weight: .bold))
                        .foregroundStyle(Color(palette.ink))
                    Text(companion.epithet.uppercased())
                        .font(.caption2.weight(.semibold))
                        .kerning(1.5)
                        .foregroundStyle(Color(palette.clay))
                }
                .scaleEffect(showFigure ? 1 : 0.92)
                .opacity(showFigure ? 1 : 0)
                .position(x: origin.x, y: origin.y + 60)
            }
            .opacity(opacity)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())  // swallow taps while it plays
        .accessibilityHidden(true)
        .task { await play() }
    }

    private func play() async {
        if reduceMotion {
            // A plain cross-fade.
            spread = 1
            showFigure = true
            withAnimation(.easeInOut(duration: 0.3)) { opacity = 1 }
            try? await Task.sleep(for: .milliseconds(320))
        } else {
            opacity = 1
            withAnimation(.timingCurve(0.6, 0, 0.3, 1, duration: 0.5)) { spread = 1 }
            withAnimation(.easeOut(duration: 0.35).delay(0.22)) { showFigure = true }
            try? await Task.sleep(for: .milliseconds(520))
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        onCovered()

        try? await Task.sleep(for: .milliseconds(reduceMotion ? 250 : 480))
        withAnimation(.easeInOut(duration: 0.5)) { opacity = 0 }
        try? await Task.sleep(for: .milliseconds(520))
        onFinished()
    }
}
