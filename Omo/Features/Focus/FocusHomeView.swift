import SwiftUI

struct FocusHomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(FocusController.self) private var focus
    @Environment(ScreenTimeAuthorizer.self) private var screenTime
    @Environment(AuthService.self) private var auth
    @Environment(SettingsStore.self) private var settings

    /// How far the OMO header has scrolled away (0 = fully shown, 1 = minimised).
    @State private var collapse: CGFloat = 0

    var body: some View {
        @Bindable var focus = focus

        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                        // Smaller than a large title and centred, so a name never gets cut off.
                        Text(greeting)
                            .font(.omoSerif(.title2))
                            .foregroundStyle(Color.omoInk)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                            .id("top")
                            .background(GeometryReader { geo in
                                Color.clear.preference(key: HeaderOffsetKey.self,
                                                       value: geo.frame(in: .named("focusScroll")).minY)
                            })

                        OmoHeader(selected: settings.settings.companion,
                                  stats: focus.lifetime,
                                  collapse: collapse)

                        // Your total focus is the headline, with today's numbers right under it.
                        NavigationLink {
                            LifetimeView()
                        } label: {
                            // Ticks up while a session runs, like today's minutes below.
                            TimelineView(.periodic(from: .now, by: 15)) { context in
                                LifetimeCard(lifetime: focus.lifetimeIncluding(runningMinutes: focus.runningMinutesToday(at: context.date)))
                            }
                        }
                        .buttonStyle(PressableCardStyle())

                        todayCard

                        if let event = focus.holidayToEarn {
                            HolidayCard(holiday: event.holiday, companion: event.companion)
                        }

                        if !screenTime.isApproved && !ScreenshotDemo.isActive {
                            permissionCard
                        }

                        if let lock = focus.friendLock {
                            friendLockCard(lock)
                        }

                        ScheduleFocusView()

                        // The timer settles into a summary, then the start card, rather than
                        // snapping from one to the next.
                        // Stacked, not listed: while one card fades out and the next fades in
                        // they share the same spot, so nothing lands below and jumps up.
                        ZStack(alignment: .top) {
                            if focus.session != nil {
                                ActiveSessionView()
                                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                                                            removal: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))))
                            } else if let finished = focus.lastFinished {
                                SessionSummaryCard(finished: finished)
                                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                            } else {
                                StartSessionView()
                                    .transition(.opacity.combined(with: .offset(y: 16)))
                            }
                        }
                        .id("sessionCard")
                        .animation(.smooth(duration: 0.55), value: sessionPhase)
                    }
                    .padding()
                }
                .coordinateSpace(name: "focusScroll")
                .task {
                    // Simulator demo: scroll to the timer, end the session, then start
                    // another, to record the hand-offs.
                    guard ScreenshotDemo.screen == "end-anim" else { return }
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation(.smooth(duration: 0.6)) { proxy.scrollTo("sessionCard", anchor: .bottom) }
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation(.smooth(duration: 0.55)) { focus.endEarly() }
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(.smooth(duration: 0.55)) { focus.dismissFinished() }
                }
                .onChange(of: sessionPhase) { _, phase in
                    // After a session ends (or you start another), glide to the new card
                    // rather than leaving the page wherever the taller timer had it.
                    guard !phase.hasPrefix("active") else { return }
                    withAnimation(.smooth(duration: 0.6)) {
                        proxy.scrollTo("sessionCard", anchor: phase == "start" ? .top : .center)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onPreferenceChange(HeaderOffsetKey.self) { minY in
                    // The figure has fully shrunk away after about 180 points of scrolling.
                    collapse = min(1, max(0, (16 - minY) / 180))
                }
                .overlay(alignment: .topTrailing) {
                    // Your OMO, minimised, keeps you company while you scroll.
                    Button {
                        withAnimation { proxy.scrollTo("top", anchor: .top) }
                    } label: {
                        MiniOmo(companion: settings.settings.companion)
                    }
                    .buttonStyle(PressableCardStyle())
                    .padding(.trailing, 16)
                    .padding(.top, 6)
                    .scaleEffect(0.4 + 0.6 * collapse, anchor: .topTrailing)
                    // Fully hidden until you've actually scrolled (collapse rests a little above 0).
                    .opacity(max(0, collapse - 0.15) / 0.85)
                    .allowsHitTesting(collapse > 0.6)
                    .accessibilityHidden(collapse < 0.6)
                }
            }
            .background(OmoBackground())
            .toolbar(.hidden, for: .navigationBar)
            .errorAlert($focus.errorMessage)
            .sheet(item: Binding(
                get: { focus.uncelebratedCompanion },
                set: { if $0 == nil, let companion = focus.uncelebratedCompanion { focus.markCelebrated(companion) } }
            )) { companion in
                OmoJoinsView(companion: companion,
                             onUse: {
                                 focus.markCelebrated(companion)
                                 settings.switchCompanion(to: companion)
                             },
                             onClose: { focus.markCelebrated(companion) })
            }
        }
    }

    /// Which of the three session cards is showing, for animating between them.
    private var sessionPhase: String {
        if let session = focus.session { return "active-\(session.id)" }
        if let finished = focus.lastFinished { return "finished-\(finished.id)" }
        return "start"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = auth.profile?.displayName.split(separator: " ").first.map(String.init)
        let base = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return name.map { "\(base), \($0)" } ?? base
    }

    /// Today's numbers in one quiet row.
    private var todayCard: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            todayRow(focusedMinutes: focus.today.focusMinutes + focus.runningMinutesToday(at: context.date))
        }
    }

    private func todayRow(focusedMinutes: Int) -> some View {
        HStack(spacing: 0) {
            todayStat(Format.minutes(focusedMinutes), "focused today")
            Divider().frame(height: 36)
            todayStat("\(focus.today.sessionsCompleted)", focus.today.sessionsCompleted == 1 ? "session" : "sessions")
            Divider().frame(height: 36)
            todayStat("\(focus.today.breaksTaken)", focus.today.breaksTaken == 1 ? "break" : "breaks")
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.omoCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.omoInk.opacity(0.09), lineWidth: 0.75))
    }

    private func todayStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .serif).weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.omoInk)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.omoLabels)
        }
        .frame(maxWidth: .infinity)
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Screen Time", systemImage: "hourglass")
                .font(.headline)
                .foregroundStyle(Color.omoGold)
            Text("OMO blocks apps through Screen Time, which you haven't set up for OMO yet. Continue to see iOS's request.")
                .foregroundStyle(.secondary)
            Button("Continue") { Task { await screenTime.request() } }
                .buttonStyle(SecondaryButtonStyle())
        }
        .card()
    }

    private func friendLockCard(_ lock: FriendLockState) -> some View {
        Button {
            router.tab = .together
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.2.badge.key.fill")
                    .font(.title)
                    .foregroundStyle(Color.omoSuccess)
                VStack(alignment: .leading, spacing: 4) {
                    Text(lock.isOnBreak ? "On a break from your study session" : "\(lock.keyholderName) has your key")
                        .font(.headline)
                    Text("Tap to see your study session")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .card()
        }
        .buttonStyle(PressableCardStyle())
    }
}
