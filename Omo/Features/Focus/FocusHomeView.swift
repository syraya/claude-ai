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
                        OmoHeader(selected: settings.settings.companion,
                                  stats: focus.lifetime,
                                  collapse: collapse) { companion in
                            settings.switchCompanion(to: companion)
                        }
                        .id("top")
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: HeaderOffsetKey.self,
                                                   value: geo.frame(in: .named("focusScroll")).minY)
                        })

                        if let event = focus.holidayToEarn {
                            HolidayCard(holiday: event.holiday, companion: event.companion)
                        }

                        if !screenTime.isApproved && !ScreenshotDemo.isActive {
                            permissionCard
                        }

                        if let lock = focus.friendLock {
                            friendLockCard(lock)
                        }

                        ScheduleStatusCard()

                        // The one primary action comes first; the numbers follow it.
                        if focus.session != nil {
                            ActiveSessionView()
                        } else {
                            StartSessionView()
                        }

                        todayCard

                        NavigationLink {
                            LifetimeView()
                        } label: {
                            LifetimeCard(lifetime: focus.lifetime)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
                .coordinateSpace(name: "focusScroll")
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
                    .buttonStyle(.plain)
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
            .navigationTitle(greeting)
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

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = auth.profile?.displayName.split(separator: " ").first.map(String.init)
        let base = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return name.map { "\(base), \($0)" } ?? base
    }

    /// Today's numbers in one quiet row.
    private var todayCard: some View {
        HStack(spacing: 0) {
            todayStat(Format.minutes(focus.today.focusMinutes), "focused today")
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
            Label("Screen Time access needed", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Color.omoGold)
            Text("OMO can't block anything until you allow it.")
                .foregroundStyle(.secondary)
            Button("Allow access") { Task { await screenTime.request() } }
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
        .buttonStyle(.plain)
    }
}
