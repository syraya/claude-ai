import SwiftUI

/// The opening: the logo on lapis with a line to think about, then it lifts away to
/// reveal the app. About two and a half seconds; tap to skip.
struct IntroView: View {
    var onFinished: () -> Void

    @State private var quote = FocusQuotes.forIntro()
    @State private var appeared = false
    @State private var leaving = false
    @State private var finished = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Same colour as the launch screen, so the hand-off from iOS is seamless.
            Brand.lapis.ignoresSafeArea()

            VStack(spacing: 18) {
                OmoLogo(size: 132)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.94)

                VStack(spacing: 2) {
                    Text("OMO")
                        .font(.omoSerif(.largeTitle, weight: .bold))
                        .kerning(8)
                    Text("thoughts of many")
                        .font(.system(.title3, design: .serif).italic())
                        .opacity(0.75)
                }
                .foregroundStyle(Brand.parchment)

                Rectangle()
                    .fill(Brand.gold)
                    .frame(width: 44, height: 1)
                    .padding(.vertical, 6)

                VStack(spacing: 6) {
                    Text("“\(quote.text)”")
                        .font(.system(.body, design: .serif).italic())
                        .multilineTextAlignment(.center)
                    Text(quote.source)
                        .font(.footnote)
                        .opacity(0.7)
                }
                .foregroundStyle(Brand.parchment)
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)
            }
            .offset(y: appeared || reduceMotion ? 0 : 10)
        }
        .opacity(leaving ? 0 : 1)
        .scaleEffect(leaving && !reduceMotion ? 1.08 : 1)
        .contentShape(Rectangle())
        .onTapGesture { leave() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens OMO")
        .task {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            try? await Task.sleep(for: .milliseconds(2100))
            leave()
        }
    }

    private func leave() {
        guard !leaving else { return }
        withAnimation(.easeInOut(duration: 0.55)) { leaving = true }
        Task {
            try? await Task.sleep(for: .milliseconds(560))
            guard !finished else { return }
            finished = true
            onFinished()
        }
    }
}
