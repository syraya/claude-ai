import SwiftUI
import Combine

/// A schedule that's blocking, on the Focus tab: a live timer to its end, the focus it
/// has added so far, and a way to take a break. While a focus session is also running,
/// the session takes the space and this shrinks to a one-line card.
struct ScheduleFocusView: View {
    @Environment(FocusController.self) private var focus
    @Environment(BlockListStore.self) private var blockLists
    @Environment(AppRouter.self) private var router

    @State private var showBreakFlow = false
    /// Plays the panel building itself in when a schedule has only just begun.
    @State private var entered = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if focus.session != nil {
                ScheduleStatusCard()
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    if let featured = featured(at: context.date),
                       let list = blockLists.list(id: featured.schedule.blockListID) {
                        panel(featured.schedule, list: list, others: featured.others, now: context.date)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
            }
        }
        .onReceive(ticker) { _ in focus.tick() }
        .onAppear(perform: openBreakIfRequested)
        .onChange(of: router.wantsBreak) { _, _ in openBreakIfRequested() }
        .fullScreenCover(isPresented: $showBreakFlow) {
            BreakFlowView(kind: .schedule) { showBreakFlow = false }
        }
        .animation(.spring(duration: 0.6, bounce: 0.12), value: focus.scheduleBreak)
    }

    private var faint: Color { Color.omoOnPrimary.opacity(0.72) }

    /// The schedule to show: one on a break first, else the first one blocking.
    private func featured(at date: Date) -> (schedule: BlockSchedule, others: Int)? {
        let active = blockLists.schedules.filter { schedule in
            schedule.isActive(at: date)
                && blockLists.list(id: schedule.blockListID).map { !$0.isEmpty || ScreenshotDemo.isActive } == true
        }
        let lifted = focus.scheduleBreak?.scheduleIDs ?? []
        guard let first = active.first(where: { lifted.contains($0.id) }) ?? active.first else { return nil }
        return (first, active.count - 1)
    }

    @ViewBuilder
    private func panel(_ schedule: BlockSchedule, list: BlockList, others: Int, now: Date) -> some View {
        VStack(spacing: 18) {
            if let pause = focus.scheduleBreak, pause.scheduleIDs.contains(schedule.id) {
                breakContent(schedule, list: list, pause: pause, now: now)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                blockContent(schedule, list: list, others: others, now: now)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .foregroundStyle(Color.omoOnPrimary)
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.omoPrimary, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onAppear {
            // Fresh from its start time: build in like a new session. Otherwise just show it.
            let fresh = schedule.occurrenceStart(at: now).map { now.timeIntervalSince($0) < 120 } ?? false
            if fresh {
                withAnimation { entered = true }
            } else {
                var quiet = Transaction()
                quiet.disablesAnimations = true
                withTransaction(quiet) { entered = true }
            }
        }
        .onDisappear { entered = false }
    }

    private func blockContent(_ schedule: BlockSchedule, list: BlockList, others: Int, now: Date) -> some View {
        let start = schedule.occurrenceStart(at: now) ?? now
        let end = schedule.endDate(after: now) ?? now
        let total = end.timeIntervalSince(start)
        let progress = total > 0 ? min(1, max(0, now.timeIntervalSince(start) / total)) : 1
        let left = end.timeIntervalSince(now)
        let breaksLeft = ScheduleEngine.breaksLeft(schedule, at: now)
        let canBreak = ScheduleEngine.canTakeBreak(at: now)

        return VStack(spacing: 18) {
            VStack(spacing: 2) {
                Text("Scheduled focus")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .kerning(1.2)
                    .foregroundStyle(faint)
                Text(schedule.name.isEmpty ? "Scheduled block" : schedule.name)
                    .font(.omoSerif(.title2))
                Text("\(list.emoji) \(list.name) blocked" + (others > 0 ? " · \(others) more on" : ""))
                    .font(.subheadline)
                    .foregroundStyle(faint)
            }
            .entrance(entered, delay: 0.05)

            ZStack(alignment: .top) {
                RingArches(color: .omoOnPrimary, ringSize: 220)
                    .entrance(entered, delay: 0.1, rise: 0)
                ZStack {
                    // The ring draws itself in around the timer.
                    ProgressRing(progress: entered ? progress : 0, color: .omoGold, lineWidth: 8)
                        .mask(
                            Circle()
                                .trim(from: 0, to: entered ? 1 : 0)
                                .stroke(style: StrokeStyle(lineWidth: 12))
                                .rotationEffect(.degrees(-90))
                        )
                        .animation(.easeInOut(duration: 1.0).delay(0.15), value: entered)
                    VStack(spacing: 4) {
                        Text(Format.clock(left))
                            .font(.system(size: left >= 3600 ? 44 : 52, weight: .semibold, design: .serif).monospacedDigit())
                        Text("left · ends \(end.formatted(date: .omitted, time: .shortened))")
                            .font(.subheadline)
                            .foregroundStyle(faint)
                    }
                    .scaleEffect(entered ? 1 : 0.9)
                    .entrance(entered, delay: 0.3, rise: 0)
                }
                .frame(width: 220, height: 220)
            }
            .padding(.top, 36)
            .frame(maxWidth: .infinity)

            // How this block is going.
            HStack(spacing: 0) {
                stat(focusedText(schedule, now: now), "focused in this block")
                Rectangle().fill(faint.opacity(0.4)).frame(width: 1, height: 34)
                stat(Format.minutes(focus.today.focusMinutes + focus.runningMinutesToday(at: now)), "focused today")
            }
            .padding(.vertical, 10)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(faint.opacity(0.35), lineWidth: 1))
            .entrance(entered, delay: 0.5)

            VStack(spacing: 18) {
            if schedule.isStrict {
                Label("Strict schedule: no breaks until it ends", systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(faint)
            } else {
                Button {
                    showBreakFlow = true
                } label: {
                    Text(!canBreak ? "No breaks left"
                         : SharedStore.settings.hasUnlimitedBreaks ? "Take a break"
                         : "Take a break · \(breaksLeft) left")
                }
                .buttonStyle(SecondaryButtonStyle(color: .omoOnPrimary))
                .disabled(!canBreak)
                .opacity(canBreak ? 1 : 0.5)
            }

            NavigationLink("Edit schedules") { SchedulesScreen() }
                .font(.subheadline)
                .foregroundStyle(faint)
            }
            .entrance(entered, delay: 0.7)
        }
    }

    private func breakContent(_ schedule: BlockSchedule, list: BlockList, pause: ScheduleBreak, now: Date) -> some View {
        let length = pause.endsAt.timeIntervalSince(pause.startedAt)
        let left = max(0, pause.endsAt.timeIntervalSince(now))
        return VStack(spacing: 20) {
            VStack(spacing: 2) {
                Text("On a break")
                    .font(.omoSerif(.title2))
                Text(schedule.name.isEmpty ? "Scheduled block" : schedule.name)
                    .font(.subheadline)
                    .foregroundStyle(faint)
            }

            ZStack {
                ProgressRing(progress: length > 0 ? 1 - left / length : 1, color: .omoGold, lineWidth: 8)
                VStack(spacing: 4) {
                    Text(Format.clock(left))
                        .font(.system(size: 52, weight: .semibold, design: .serif).monospacedDigit())
                    Text("then \(list.name) locks again")
                        .font(.subheadline)
                        .foregroundStyle(faint)
                }
            }
            .frame(width: 230, height: 230)
            .frame(maxWidth: .infinity)

            Button("I'm done, back to focus") {
                withAnimation(.spring(duration: 0.6, bounce: 0.12)) { focus.endScheduleBreak() }
            }
                .buttonStyle(PrimaryButtonStyle(color: .omoOnPrimary, textColor: .omoPrimary))

            if let end = schedule.endDate(after: now) {
                Text("\(schedule.name.isEmpty ? "The schedule" : schedule.name) runs until \(end.formatted(date: .omitted, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(faint)
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .serif).weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(faint)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func focusedText(_ schedule: BlockSchedule, now: Date) -> String {
        guard schedule.countsTowardFocus else { return "Not counted" }
        let seconds = ScheduleEngine.focusedSeconds(in: schedule, at: now) ?? 0
        return Format.minutes(Int(seconds / 60))
    }

    /// "Take a break" on the block screen, or its notification, lands here when it's
    /// a schedule you're taking a break from.
    private func openBreakIfRequested() {
        guard router.wantsBreak, focus.session?.canTakeBreak != true else { return }
        router.wantsBreak = false
        if ScheduleEngine.canTakeBreak() { showBreakFlow = true }
    }
}
