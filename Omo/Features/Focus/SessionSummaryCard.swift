import SwiftUI

/// What the timer settles into when a session ends: your OMO, the minutes you put in
/// and what they were for. "Start another" fades it into the start card.
struct SessionSummaryCard: View {
    var finished: FocusController.FinishedSession

    @Environment(FocusController.self) private var focus
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var countedMinutes = 0

    private var faint: Color { Color.omoOnPrimary.opacity(0.72) }
    private var companion: OmoCompanion { OmoCompanion.current }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(finished.completed ? "Session complete" : "Session ended")
                    .font(.omoSerif(.title2))
                Text("\(finished.blockListName) is unlocked")
                    .font(.subheadline)
                    .foregroundStyle(faint)
            }

            // A gold ring draws itself closed around your OMO.
            ZStack {
                Circle()
                    .stroke(Color.omoOnPrimary.opacity(0.14), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: shown ? 1 : 0)
                    .stroke(Color.omoGold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                OmoFigure(companion: companion, size: 116, backdrop: true)
                    .hovering(4)
                    .scaleEffect(shown || reduceMotion ? 1 : 0.85)
            }
            .frame(width: 176, height: 176)
            .padding(.top, 4)

            VStack(spacing: 0) {
                Text("\(countedMinutes)")
                    .font(.system(size: 56, weight: .semibold, design: .serif).monospacedDigit())
                    .contentTransition(.numericText(value: Double(countedMinutes)))
                Text(finished.minutes == 1 ? "minute focused" : "minutes focused")
                    .font(.subheadline)
                    .foregroundStyle(faint)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(finished.minutes) minutes focused")

            if let intention = finished.intention {
                Text(intention)
                    .font(.system(.body, design: .serif).italic())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.omoGold, lineWidth: 1.25))
                    .accessibilityLabel("Intention: \(intention)")
            }

            Text("“\(companion.whisper)”\n\(companion.name)")
                .font(.system(.footnote, design: .serif).italic())
                .multilineTextAlignment(.center)
                .foregroundStyle(faint)
                .opacity(shown ? 1 : 0)

            Button("Start another") {
                withAnimation(.smooth(duration: 0.55)) { focus.dismissFinished() }
            }
                .buttonStyle(PrimaryButtonStyle(color: .omoOnPrimary, textColor: .omoPrimary))
        }
        .foregroundStyle(Color.omoOnPrimary)
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.omoPrimary, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .sensoryFeedback(.success, trigger: shown) { _, isShown in isShown && finished.completed }
        .task(id: finished.id) {
            // Let the card land before the ring closes and the minutes count up.
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 250))
            withAnimation(.easeInOut(duration: reduceMotion ? 0 : 1.1)) { shown = true }
            withAnimation(.easeOut(duration: reduceMotion ? 0 : 0.9)) { countedMinutes = finished.minutes }
        }
    }
}
