import SwiftUI
import FamilyControls

#if targetEnvironment(simulator)

/// Demo data for App Store screenshots, in the simulator only (it can't pick real apps
/// or sign in). Launch with `-OMODemo <screen>` and optionally `-OMODemoOMO <omo>`.
/// Screens: focus, session, break, schedules, lifetime, omos.
enum ScreenshotDemo {
    static let screen = UserDefaults.standard.string(forKey: "OMODemo")
    static var isActive: Bool { screen != nil }

    /// What the demo lists would hold on a real phone (the simulator has no app tokens).
    static func summary(for list: BlockList) -> String? {
        guard isActive else { return nil }
        return ["Social": "6 apps · 1 category", "Games": "4 apps · 1 category",
                "Streaming": "5 apps · 2 sites"][list.name]
    }

    /// Fills the shared store before any of the app's stores read it.
    static func seedIfRequested() -> Bool {
        guard let screen else { return false }
        let now = Date()
        let calendar = Calendar.current

        var settings = AppSettings()
        settings.hasCompletedOnboarding = true
        settings.companion = OmoCompanion(rawValue: UserDefaults.standard.string(forKey: "OMODemoOMO") ?? "") ?? .glaux
        SharedStore.settings = settings

        // About seven months of steadily growing focus.
        var lifetime = LifetimeStats()
        lifetime.startedAt = calendar.date(byAdding: .month, value: -7, to: now) ?? now
        let monthly = [1680, 2940, 4320, 5160, 6900, 7740, 8460, 3240]
        for (index, minutes) in monthly.enumerated() {
            let month = calendar.date(byAdding: .month, value: index - 7, to: now) ?? now
            lifetime.monthlyMinutes[LifetimeStats.monthFormatter.string(from: month)] = minutes
        }
        lifetime.totalFocusMinutes = monthly.reduce(0, +)
        lifetime.sessionsCompleted = 312
        lifetime.friendSessions = 18
        lifetime.longestSessionMinutes = 214
        lifetime.currentStreak = 23
        lifetime.longestStreak = 31
        lifetime.lastFocusDay = DailyStats.key(for: now)
        lifetime.maxFriends = 6
        lifetime.celebratedHours = 10_000
        lifetime.celebratedCompanions = OmoCompanion.allCases.map(\.rawValue)
        SharedStore.lifetime = lifetime
        SharedStore.updateStats(for: now) {
            $0.focusMinutes = 145
            $0.sessionsCompleted = 3
            $0.breaksTaken = 1
        }

        let social = BlockList(name: "Social", emoji: "📱")
        let games = BlockList(name: "Games", emoji: "🎮")
        let streaming = BlockList(name: "Streaming", emoji: "📺")
        SharedStore.blockLists = [social, games, streaming]
        SharedStore.schedules = [
            BlockSchedule(name: "Work", blockListID: social.id),
            BlockSchedule(name: "Bedtime", blockListID: streaming.id, startHour: 22, startMinute: 30,
                          endHour: 7, endMinute: 0, weekdays: BlockSchedule.everyDay, isStrict: true),
            BlockSchedule(name: "Weekend reset", blockListID: games.id, startHour: 10, endHour: 14,
                          weekdays: BlockSchedule.weekendsOnly),
        ]

        SharedStore.friendLock = nil
        if screen == "scheduled" {
            // A schedule halfway through, to show its timer on the Focus tab.
            let calendar = Calendar.current
            let start = now.addingTimeInterval(-95 * 60)
            let end = now.addingTimeInterval(70 * 60)
            let s = calendar.dateComponents([.hour, .minute], from: start)
            let e = calendar.dateComponents([.hour, .minute], from: end)
            let deepWork = BlockSchedule(name: "Deep work", blockListID: social.id,
                                         startHour: s.hour ?? 9, startMinute: s.minute ?? 0,
                                         endHour: e.hour ?? 17, endMinute: e.minute ?? 0,
                                         weekdays: BlockSchedule.everyDay)
            SharedStore.schedules = [deepWork] + SharedStore.schedules
            if let occurrence = deepWork.occurrenceStart(at: now) {
                SharedStore.scheduleRuns = [deepWork.id.uuidString: ScheduleRun(
                    occurrence: occurrence, start: occurrence,
                    end: occurrence.addingTimeInterval(TimeInterval(deepWork.durationMinutes * 60)),
                    startsWhenSeen: true)]
            }
        }
        if screen == "session" || screen == "break" || screen == "end-anim" {
            SharedStore.focusSession = FocusSession(
                blockListName: social.name, selection: FamilyActivitySelection(),
                startedAt: now.addingTimeInterval(-17 * 60), endsAt: now.addingTimeInterval(28 * 60),
                allowsBreaks: true, allowsEndingEarly: true, maxBreaks: 3,
                intention: "Finish chapter 4 of biology")
        } else if screen == "ended" {
            // Ran out a minute ago, so opening the app finishes it and shows the summary.
            SharedStore.focusSession = FocusSession(
                blockListName: social.name, selection: FamilyActivitySelection(),
                startedAt: now.addingTimeInterval(-46 * 60), endsAt: now.addingTimeInterval(-60),
                allowsBreaks: true, allowsEndingEarly: true, maxBreaks: 3,
                intention: "Finish chapter 4 of biology")
        } else {
            SharedStore.focusSession = nil
        }
        return true
    }

    /// Points the app at the screen being captured.
    @MainActor static func route(_ router: AppRouter) {
        switch screen {
        case "schedules": router.tab = .lists
        case "break": router.tab = .focus; router.wantsBreak = true
        case .some: router.tab = .focus
        case nil: break
        }
    }
}

#else

/// Screenshot demo mode exists only in the simulator.
enum ScreenshotDemo {
    static let screen: String? = nil
    static let isActive = false
    static func summary(for list: BlockList) -> String? { nil }
    static func seedIfRequested() -> Bool { false }
    @MainActor static func route(_ router: AppRouter) {}
}

#endif
