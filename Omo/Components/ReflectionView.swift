import SwiftUI

/// The pause before a break (or ending early). You have to sit through a short
/// countdown before the button unlocks, which is usually enough to change your mind.
struct ReflectionView: View {
    var seconds: Int
    var title: String
    var confirmLabel: String
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @State private var startedAt = Date()
    @State private var breatheIn = false
    @State private var promptIndex = Int.random(in: 0..<ReflectionView.prompts.count)

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
        "“The unexamined life is not worth living.” (Socrates) What are you avoiding?",
        "“You have power over your mind, not outside events.” (Marcus Aurelius)",
        "“We suffer more often in imagination than in reality.” (Seneca)",
    ]

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 0.25)) { context in
            let elapsed = context.date.timeIntervalSince(startedAt)
            let remaining = max(0, Double(seconds) - elapsed)
            let done = remaining <= 0

            VStack(spacing: 28) {
                Spacer()

                Text(title)
                    .font(.omoSerif(.title2))
                    .multilineTextAlignment(.center)

                ZStack {
                    Circle()
                        .fill(Color.omoSuccess.opacity(0.15))
                        .scaleEffect(breatheIn ? 1.0 : 0.6)
                    Circle()
                        .fill(Color.omoSuccess.opacity(0.25))
                        .scaleEffect(breatheIn ? 0.75 : 0.45)
                    VStack(spacing: 6) {
                        Text(done ? "✓" : "\(Int(remaining.rounded(.up)))")
                            .font(.system(size: 64, weight: .semibold, design: .serif).monospacedDigit())
                            .foregroundStyle(Color.omoInk)
                        Text(done ? "Your call" : (Int(elapsed / 4) % 2 == 0 ? "Breathe in" : "Breathe out"))
                            .font(.subheadline)
                            .foregroundStyle(Color.omoLabels)
                    }
                }
                .frame(width: 240, height: 240)

                Text(Self.prompts[promptIndex])
                    .font(.system(.title3, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.omoInk)
                    .padding(.horizontal, 24)
                    .onTapGesture { promptIndex = (promptIndex + 1) % Self.prompts.count }

                Spacer()

                VStack(spacing: 12) {
                    Button("Back to focus", action: onCancel)
                        .buttonStyle(PrimaryButtonStyle())
                    Button(action: onConfirm) {
                        if done {
                            Text(confirmLabel)
                        } else {
                            Label("Available in \(Int(remaining.rounded(.up))) seconds", systemImage: "lock.fill")
                                .monospacedDigit()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle(color: done ? .omoPrimary : .omoLabels))
                    .disabled(!done)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(OmoBackground())
        .onAppear {
            startedAt = Date()
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breatheIn = true
            }
        }
    }
}
