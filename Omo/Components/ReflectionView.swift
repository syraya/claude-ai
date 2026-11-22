import SwiftUI

/// The pause before a break (or ending early): your OMO's landscape, a breathing
/// countdown and a line to think about. The confirm button stays locked until the
/// wait is over, which is usually enough to change your mind. "Back to focus" is
/// always there.
struct ReflectionView: View {
    var seconds: Int
    var title: String
    var confirmLabel: String
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @State private var startedAt = Date()
    @State private var promptIndex = Int.random(in: 0..<ReflectionView.prompts.count)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let scene = BreathingScene(for: .current)
    /// Seconds in each breath, in and out. The numeral counts these down, separately
    /// from the wait before the confirm button unlocks.
    private static let phaseLength = 5

    static let prompts = [
        "What were you about to open, and why?",
        "Will this make the next hour better or worse?",
        "Are you bored, tired, or actually done?",
        "Could a glass of water or a stretch do the job instead?",
        "How will you feel about this break in 10 minutes?",
        "What's the very next small step on your task?",
        "Is this a choice, or a habit choosing for you?",
        "What would the version of you who passes this exam do now?",
        "Who are you studying for? Picture them for a moment.",
    ]

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 0.25)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(startedAt))
            let remaining = max(0, Double(seconds) - elapsed)
            let done = remaining <= 0
            let phase = Int(elapsed) / Self.phaseLength
            let inhaling = phase % 2 == 0
            let count = Self.phaseLength - Int(elapsed) % Self.phaseLength

            VStack(spacing: 0) {
                topBar

                Text(title)
                    .font(.omoSerif(.title2))
                    .kerning(title.count <= 16 ? 3 : 0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.omoInk)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                VStack(spacing: -6) {
                    Text("\(count)")
                        .font(.system(size: 112, weight: .semibold, design: .serif).monospacedDigit())
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.easeInOut(duration: 0.35), value: count)
                    Text(inhaling ? "Breathe in" : "Breathe out")
                        .font(.omoSerif(.largeTitle, weight: .bold))
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: inhaling)
                }
                .foregroundStyle(Color.omoInk)
                .accessibilityElement(children: .combine)

                Spacer(minLength: 0)

                sceneArt(inhaling: inhaling)

                VStack(spacing: 4) {
                    Text("“\(scene.quote.text)”")
                        .font(.system(.title3, design: .serif).italic())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.omoInk)
                    Text(scene.quote.author)
                        .font(.subheadline)
                        .foregroundStyle(Color.omoLabels)
                }
                .padding(.horizontal, 28)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(scene.quote.text), \(scene.quote.author), \(scene.quote.source)")

                Text(Self.prompts[promptIndex])
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.omoInk.opacity(0.85))
                    .padding(.horizontal, 40)
                    .padding(.top, 14)
                    .contentTransition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            promptIndex = (promptIndex + 1) % Self.prompts.count
                        }
                    }
                    .accessibilityHint("Tap for another question")

                Spacer(minLength: 12)

                VStack(spacing: 12) {
                    Button("Back to focus", action: onCancel)
                        .buttonStyle(PrimaryButtonStyle())
                    confirmButton(done: done, progress: 1 - remaining / Double(max(1, seconds)), remaining: remaining)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .background(Color(scene.background).ignoresSafeArea())
        .onAppear { startedAt = Date() }
    }

    private var topBar: some View {
        HStack {
            Button(action: onCancel) {
                Label("Focus", systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
                    .font(.body)
            }
            .foregroundStyle(Color.omoInk)
            .accessibilityLabel("Back to focus")
            Spacer()
            Text("OMO")
                .font(.omoSerif(.title2))
                .kerning(1.5)
                .foregroundStyle(Color.omoInk)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    /// The landscape, fading into the paper at its edges and swelling a little with
    /// each breath in. Still with Reduce Motion.
    private func sceneArt(inhaling: Bool) -> some View {
        Image(scene.imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .mask(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.14),
                    .init(color: .black, location: 0.8),
                    .init(color: .clear, location: 1),
                ], startPoint: .top, endPoint: .bottom)
            )
            .scaleEffect(reduceMotion ? 1 : (inhaling ? 1.04 : 1))
            .animation(reduceMotion ? nil : .easeInOut(duration: Double(Self.phaseLength)), value: inhaling)
            .padding(.bottom, 4)
            .accessibilityHidden(true)
    }

    /// Locked and filling up while you wait, then yours to press.
    private func confirmButton(done: Bool, progress: Double, remaining: Double) -> some View {
        Button(action: onConfirm) {
            if done {
                Text(confirmLabel)
            } else {
                Label(confirmLabel, systemImage: "lock.fill")
            }
        }
        .buttonStyle(LockedButtonStyle(unlocked: done, progress: progress))
        .disabled(!done)
        .animation(.easeInOut(duration: 0.3), value: done)
        .accessibilityLabel(done ? confirmLabel : "\(confirmLabel), available in \(Int(remaining.rounded(.up))) seconds")
    }
}

/// The confirm button: grey and filling from the left while locked, outlined in the
/// theme's colour once it opens.
private struct LockedButtonStyle: ButtonStyle {
    var unlocked: Bool
    var progress: Double

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let tint = unlocked ? Color.omoPrimary : Color.omoLabels
        configuration.label
            .font(.headline)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                ZStack(alignment: .leading) {
                    shape.fill(Color.omoInk.opacity(unlocked ? 0 : 0.05))
                    GeometryReader { proxy in
                        Rectangle()
                            .fill(Color.omoInk.opacity(unlocked ? 0 : 0.06))
                            .frame(width: proxy.size.width * min(1, max(0, progress)))
                            .animation(.linear(duration: 0.25), value: progress)
                    }
                    .clipShape(shape)
                    shape.fill(tint.opacity(configuration.isPressed ? 0.12 : 0))
                }
            }
            .overlay(shape.stroke(tint.opacity(unlocked ? 1 : 0.45), lineWidth: 1.25))
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
