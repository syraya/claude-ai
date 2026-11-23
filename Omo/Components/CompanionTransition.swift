import SwiftUI
import UIKit

/// Switching OMOs from outside the gallery (a new OMO joining you, say). The OMO's arch
/// rises and fills the screen, then the new theme is revealed underneath, so even
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

    /// 0: a small arch in the middle; 1: risen into place; 2: filling the screen.
    @State private var stage = 0
    @State private var opacity = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width - 96, 300)
            let small = CGSize(width: width, height: width * 1.2)
            let full = CGSize(width: geo.size.width + 4, height: geo.size.height + 4)
            let size = stage == 2 ? full : small
            ZStack {
                // The page behind dims as the arch arrives.
                Color.black.opacity(stage == 0 ? 0 : 0.35)
                OmoArchPanel(companion: companion, locked: false, arched: stage != 2)
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(stage == 0 ? 0.85 : 1)
                    .opacity(stage == 0 ? 0 : 1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(opacity)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())  // swallow taps while it plays
        .accessibilityHidden(true)
        .task { await play() }
    }

    /// The same move as choosing in the gallery: the OMO's arch rises, fills the
    /// screen, the new theme lands underneath, and it fades away.
    private func play() async {
        if reduceMotion {
            stage = 2
            opacity = 0
            withAnimation(.easeInOut(duration: 0.3)) { opacity = 1 }
            try? await Task.sleep(for: .milliseconds(320))
        } else {
            withAnimation(.spring(duration: 0.45, bounce: 0.12)) { stage = 1 }
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.spring(duration: 0.65, bounce: 0.06)) { stage = 2 }
            try? await Task.sleep(for: .milliseconds(700))
        }

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        onCovered()

        try? await Task.sleep(for: .milliseconds(reduceMotion ? 250 : 450))
        withAnimation(.easeInOut(duration: 0.55)) { opacity = 0 }
        try? await Task.sleep(for: .milliseconds(570))
        onFinished()
    }
}
