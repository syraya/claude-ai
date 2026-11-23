import SwiftUI
import Combine

struct ActiveSessionView: View {
    @Environment(FocusController.self) private var focus
    @Environment(AppRouter.self) private var router

    @State private var showBreakFlow = false
    @State private var showEndFlow = false
    @State private var endConfirmed = false
    /// Plays the panel building itself in, for a session that has only just started.
    @State private var entered = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if let session = focus.session {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(spacing: 22) {
                    if let breakEnd = session.breakEndsAt {
                        breakContent(session: session, breakEnd: breakEnd, now: context.date)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    } else {
                        focusContent(session: session, now: context.date)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                // A break ending on its own glides back too, not just one you end yourself.
                .animation(.spring(duration: 0.6, bounce: 0.12), value: session.isOnBreak)
                // The session is the one thing that matters while it runs, so it gets the
                // theme's primary colour as a panel of its own.
                .foregroundStyle(Color.omoOnPrimary)
                .padding(22)
                .frame(maxWidth: .infinity)
                .background(Color.omoPrimary, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .onReceive(ticker) { _ in focus.tick() }
            .onAppear {
                if Date().timeIntervalSince(session.startedAt) < 4 {
                    withAnimation { entered = true }
                } else {
                    var quiet = Transaction()
                    quiet.disablesAnimations = true
                    withTransaction(quiet) { entered = true }
                }
                openBreakIfRequested()
            }
            .onChange(of: router.wantsBreak) { _, _ in openBreakIfRequested() }
            .fullScreenCover(isPresented: $showBreakFlow) {
                BreakFlowView { showBreakFlow = false }
            }
            .fullScreenCover(isPresented: $showEndFlow, onDismiss: {
                // End only once the reflection screen has slid away, so you see the
                // timer settle into its summary instead of it vanishing underneath.
                guard endConfirmed else { return }
                endConfirmed = false
                withAnimation(.smooth(duration: 0.55)) { focus.endEarly() }
            }) {
                ReflectionView(seconds: max(15, SharedStore.settings.reflectionSeconds),
                               title: "End your session early?",
                               confirmLabel: "End session",
                               onConfirm: {
                                   endConfirmed = true
                                   showEndFlow = false
                               },
                               onCancel: { showEndFlow = false })
            }
        }
    }

    private var faint: Color { Color.omoOnPrimary.opacity(0.72) }

    private func focusContent(session: FocusSession, now: Date) -> some View {
        VStack(spacing: 18) {
            VStack(spacing: 2) {
                Text("Focusing")
                    .font(.omoSerif(.title2))
                Text("\(session.blockListName) blocked")
                    .font(.subheadline)
                    .foregroundStyle(faint)
            }
            .entrance(entered, delay: 0.05)

            ZStack(alignment: .top) {
                RingArches(color: .omoOnPrimary, ringSize: 230)
                    .entrance(entered, delay: 0.1, rise: 0)
                ZStack {
                    // The ring draws itself in around the timer.
                    Circle()
                        .stroke(Color.omoOnPrimary.opacity(0.12), lineWidth: 8)
                        .opacity(entered ? 0 : 1)
                    ProgressRing(progress: entered ? session.progress(at: now) : 0, color: .omoGold, lineWidth: 8)
                        .mask(
                            Circle()
                                .trim(from: 0, to: entered ? 1 : 0)
                                .stroke(style: StrokeStyle(lineWidth: 12))
                                .rotationEffect(.degrees(-90))
                        )
                        .animation(.easeInOut(duration: 1.0).delay(0.15), value: entered)
                    VStack(spacing: 4) {
                        Text(Format.clock(session.remaining(at: now)))
                            .font(.system(size: 52, weight: .semibold, design: .serif).monospacedDigit())
                        Text("ends \(session.endsAt.formatted(date: .omitted, time: .shortened))")
                            .font(.subheadline)
                            .foregroundStyle(faint)
                    }
                    .scaleEffect(entered ? 1 : 0.9)
                    .entrance(entered, delay: 0.3, rise: 0)
                }
                .frame(width: 230, height: 230)
            }
            .padding(.top, 36)
            .frame(maxWidth: .infinity)

            if let intention = session.intention {
                Text(intention)
                    .font(.system(.body, design: .serif).italic())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.omoGold, lineWidth: 1.25))
                    .accessibilityLabel("Intention: \(intention)")
                    .entrance(entered, delay: 0.45)
            }

            VStack(spacing: 6) {
                OmoFigure(companion: OmoCompanion.current, size: 104, backdrop: true)
                    .hovering(4)
                Text(OmoCompanion.current.name)
                    .font(.omoSerif(.subheadline))
                    .foregroundStyle(faint)
            }
            .padding(.vertical, 4)
            // Your OMO settles in from above.
            .entrance(entered, delay: 0.55, rise: -18)

            VStack(spacing: 18) {

            if session.allowsBreaks {
                Button {
                    showBreakFlow = true
                } label: {
                    Text(session.hasUnlimitedBreaks ? "Take a break"
                         : session.breaksLeft > 0 ? "Take a break · \(session.breaksLeft) left"
                         : "No breaks left")
                }
                .buttonStyle(SecondaryButtonStyle(color: .omoOnPrimary))
                .disabled(!session.canTakeBreak)
                .opacity(session.canTakeBreak ? 1 : 0.5)
            }

            if session.allowsEndingEarly {
                Button("End session") { showEndFlow = true }
                    .font(.subheadline)
                    .foregroundStyle(faint)
            } else {
                Label("Strict mode: this session can't be ended early", systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(faint)
            }
            }
            .entrance(entered, delay: 0.75)
        }
    }

    private func breakContent(session: FocusSession, breakEnd: Date, now: Date) -> some View {
        let breakLength = breakEnd.timeIntervalSince(session.breakStartedAt ?? now)
        let left = max(0, breakEnd.timeIntervalSince(now))
        return VStack(spacing: 20) {
            Text("On a break")
                .font(.omoSerif(.title2))

            ZStack {
                ProgressRing(progress: breakLength > 0 ? 1 - left / breakLength : 1, color: .omoGold, lineWidth: 8)
                VStack(spacing: 4) {
                    Text(Format.clock(left))
                        .font(.system(size: 52, weight: .semibold, design: .serif).monospacedDigit())
                    Text("then \(session.blockListName) locks again")
                        .font(.subheadline)
                        .foregroundStyle(faint)
                }
            }
            .frame(width: 240, height: 240)
            .frame(maxWidth: .infinity)

            Button("I'm done, back to focus") {
                withAnimation(.spring(duration: 0.6, bounce: 0.12)) { focus.endBreak() }
            }
                .buttonStyle(PrimaryButtonStyle(color: .omoOnPrimary, textColor: .omoPrimary))

            Text("Session ends at \(session.endsAt.formatted(date: .omitted, time: .shortened))")
                .font(.footnote)
                .foregroundStyle(faint)
        }
    }

    private func openBreakIfRequested() {
        // A request this session can't take may be for a schedule's break instead.
        guard router.wantsBreak, focus.session?.canTakeBreak == true else { return }
        router.wantsBreak = false
        showBreakFlow = true
    }
}

/// Reflection countdown first, then pick how long.
struct BreakFlowView: View {
    enum Kind { case session, schedule }

    var kind: Kind = .session
    var onDone: () -> Void

    @Environment(FocusController.self) private var focus
    @Environment(SettingsStore.self) private var settings
    @State private var reflected = false

    var body: some View {
        if !reflected {
            ReflectionView(seconds: settings.settings.reflectionSeconds,
                           title: "Take a moment",
                           confirmLabel: "Take a break",
                           onConfirm: { reflected = true },
                           onCancel: onDone)
        } else {
            VStack(spacing: 24) {
                Spacer()
                Text("How long?")
                    .font(.omoSerif(.largeTitle, weight: .bold))
                Text("Your apps unlock for this long, then lock again on their own.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                let remaining = Int(remainingSeconds / 60)
                let options = AppSettings.breakOptions.filter { $0 <= max(1, remaining) }
                VStack(spacing: 10) {
                    ForEach(options, id: \.self) { minutes in
                        Button("\(minutes) minute\(minutes == 1 ? "" : "s")") {
                            withAnimation(.spring(duration: 0.6, bounce: 0.12)) {
                                switch kind {
                                case .session: focus.startBreak(minutes: minutes)
                                case .schedule: focus.startScheduleBreak(minutes: minutes)
                                }
                            }
                            onDone()
                        }
                        .buttonStyle(minutes == settings.settings.defaultBreakMinutes
                                     ? AnyButtonStyle(PrimaryButtonStyle())
                                     : AnyButtonStyle(SecondaryButtonStyle()))
                    }
                }
                Spacer()
                Button("Actually, never mind", action: onDone)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(OmoBackground())
        }
    }

    /// Time left in what you're taking a break from; longer breaks aren't offered.
    private var remainingSeconds: TimeInterval {
        switch kind {
        case .session:
            return focus.session?.remaining() ?? 0
        case .schedule:
            let now = Date()
            let ends = ScheduleEngine.breakableSchedules(at: now).compactMap { $0.endDate(after: now) }
            return ends.max()?.timeIntervalSince(now) ?? 0
        }
    }
}

/// Lets one `.buttonStyle` pick between two styles.
struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        make(configuration)
    }
}
