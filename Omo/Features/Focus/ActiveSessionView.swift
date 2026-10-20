import SwiftUI
import Combine

struct ActiveSessionView: View {
    @Environment(FocusController.self) private var focus
    @Environment(AppRouter.self) private var router

    @State private var showBreakFlow = false
    @State private var showEndFlow = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if let session = focus.session {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(spacing: 22) {
                    if let breakEnd = session.breakEndsAt {
                        breakContent(session: session, breakEnd: breakEnd, now: context.date)
                    } else {
                        focusContent(session: session, now: context.date)
                    }
                }
                .card()
            }
            .onReceive(ticker) { _ in focus.tick() }
            .onAppear(perform: openBreakIfRequested)
            .onChange(of: router.wantsBreak) { _, _ in openBreakIfRequested() }
            .fullScreenCover(isPresented: $showBreakFlow) {
                BreakFlowView { showBreakFlow = false }
            }
            .fullScreenCover(isPresented: $showEndFlow) {
                ReflectionView(seconds: max(15, SharedStore.settings.reflectionSeconds),
                               title: "End your session early?",
                               confirmLabel: "End session",
                               onConfirm: {
                                   focus.endEarly()
                                   showEndFlow = false
                               },
                               onCancel: { showEndFlow = false })
            }
        }
    }

    private func focusContent(session: FocusSession, now: Date) -> some View {
        VStack(spacing: 22) {
            HStack {
                Label("Focusing", systemImage: "building.columns.fill")
                    .font(.headline)
                    .foregroundStyle(Color.omoLapis)
                Spacer()
                Text("\(session.blockListName) blocked")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                ArcadeBackdrop()
                ZStack {
                    ProgressRing(progress: session.progress(at: now))
                    VStack(spacing: 4) {
                        Text(Format.clock(session.remaining(at: now)))
                            .font(.system(size: 52, weight: .semibold, design: .serif).monospacedDigit())
                            .foregroundStyle(Color.omoInk)
                        Text("ends \(session.endsAt.formatted(date: .omitted, time: .shortened))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 240, height: 240)
                .offset(y: 22)
            }
            .frame(width: 290, height: 330)
            .frame(maxWidth: .infinity)

            if let intention = session.intention {
                IntentionCard(text: intention)
            }

            if session.allowsBreaks {
                Button {
                    showBreakFlow = true
                } label: {
                    Label(session.breaksLeft > 0
                          ? "Take a break (\(session.breaksLeft) left)"
                          : "No breaks left",
                          systemImage: "cup.and.saucer.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!session.canTakeBreak)
                .opacity(session.canTakeBreak ? 1 : 0.5)
            }

            if session.allowsEndingEarly {
                Button("End early") { showEndFlow = true }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Label("Strict mode: this session can't be ended early", systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func breakContent(session: FocusSession, breakEnd: Date, now: Date) -> some View {
        let breakLength = breakEnd.timeIntervalSince(session.breakStartedAt ?? now)
        let left = max(0, breakEnd.timeIntervalSince(now))
        return VStack(spacing: 22) {
            Label("On a break", systemImage: "cup.and.saucer.fill")
                .font(.headline)
                .foregroundStyle(Color.omoOchre)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                ProgressRing(progress: breakLength > 0 ? 1 - left / breakLength : 1, color: .omoOchre)
                VStack(spacing: 4) {
                    Text(Format.clock(left))
                        .font(.system(size: 52, weight: .bold, design: .rounded).monospacedDigit())
                    Text("then \(session.blockListName) locks again")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 250, height: 250)
            .frame(maxWidth: .infinity)

            Button("I'm done, back to focus") { focus.endBreak() }
                .buttonStyle(PrimaryButtonStyle(color: .omoVerdigris))

            Text("Session ends at \(session.endsAt.formatted(date: .omitted, time: .shortened))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func openBreakIfRequested() {
        guard router.wantsBreak else { return }
        router.wantsBreak = false
        if focus.session?.canTakeBreak == true { showBreakFlow = true }
    }
}

/// Reflection countdown first, then pick how long.
struct BreakFlowView: View {
    var onDone: () -> Void

    @Environment(FocusController.self) private var focus
    @Environment(SettingsStore.self) private var settings
    @State private var reflected = false

    var body: some View {
        if !reflected {
            ReflectionView(seconds: settings.settings.reflectionSeconds,
                           title: "Before you take a break…",
                           confirmLabel: "I still want a break",
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

                let remaining = Int((focus.session?.remaining() ?? 0) / 60)
                let options = AppSettings.breakOptions.filter { $0 <= max(1, remaining) }
                VStack(spacing: 10) {
                    ForEach(options, id: \.self) { minutes in
                        Button("\(minutes) minute\(minutes == 1 ? "" : "s")") {
                            focus.startBreak(minutes: minutes)
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
