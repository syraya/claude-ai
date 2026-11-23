import Foundation
import DeviceActivity
import FamilyControls

extension DeviceActivityName {
    static let dailyUsage = Self("omo.dailyUsage")
}

/// Names for the background timers. The monitor extension reads the prefix to
/// know what to do when one fires.
enum TimerName {
    static let focusEndPrefix = "omo.focusEnd."
    static let focusBreakPrefix = "omo.focusBreak."
    static let friendBreakPrefix = "omo.friendBreak."
    static let usageEventPrefix = "omo.usage."

    static func focusEnd(_ id: UUID) -> String { focusEndPrefix + id.uuidString }
    static func focusBreak(_ id: UUID) -> String { focusBreakPrefix + id.uuidString }
    static func friendBreak(_ sessionID: String) -> String { friendBreakPrefix + sessionID }
}

/// Wraps DeviceActivityCenter, which wakes the monitor extension at a given time even
/// when OMO isn't running. That's how sessions and breaks end on time.
enum ActivityScheduler {
    /// DeviceActivityCenter asks iOS's Screen Time service and waits for its answer,
    /// which can take many seconds when the service is busy (say, a schedule has just
    /// started). Waiting like that on the main thread froze OMO until iOS killed it, so
    /// every request goes through this queue, one at a time and in order.
    static let queue = DispatchQueue(label: "com.hserieh.omo.monitoring", qos: .userInitiated)

    /// `scheduleTimer`, without waiting for iOS. `failed` runs on the main thread if
    /// iOS refuses it.
    static func scheduleTimerSoon(named name: String, firingAt date: Date,
                                  failed: (@MainActor @Sendable () -> Void)? = nil) {
        queue.async {
            do {
                try scheduleTimer(named: name, firingAt: date)
            } catch {
                guard let failed else { return }
                DispatchQueue.main.async { MainActor.assumeIsolated { failed() } }
            }
        }
    }

    /// iOS refuses schedules shorter than 15 minutes.
    private static let minimumInterval: TimeInterval = 15 * 60

    /// Wakes the monitor extension at `date`. Slow: use `scheduleTimerSoon` from the app.
    ///
    /// For anything shorter than 15 minutes (most breaks), we schedule a longer
    /// interval and ask for an "ending soon" warning that lands on the real time.
    static func scheduleTimer(named name: String, firingAt date: Date) throws {
        let center = DeviceActivityCenter()
        let activity = DeviceActivityName(name)
        let now = Date()
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.hour, .minute, .second]

        var intervalEnd = date
        var warning: DateComponents?
        if date.timeIntervalSince(now) < minimumInterval {
            intervalEnd = now.addingTimeInterval(minimumInterval + 60)
            let lead = Int(intervalEnd.timeIntervalSince(date))
            warning = DateComponents(minute: lead / 60, second: lead % 60)
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(components, from: now),
            intervalEnd: calendar.dateComponents(components, from: intervalEnd),
            repeats: false,
            warningTime: warning
        )
        center.stopMonitoring([activity])
        try center.startMonitoring(activity, during: schedule)
    }

    /// Stops a timer, without waiting for iOS.
    static func cancelTimer(named name: String) {
        queue.async { DeviceActivityCenter().stopMonitoring([DeviceActivityName(name)]) }
    }

    /// Counts how long you spend in `selection` each day, in 15-minute steps, so
    /// friends can see it. Apple doesn't let apps read exact Screen Time numbers;
    /// this threshold approach is the closest thing allowed.
    static func startUsageTracking(for selection: FamilyActivitySelection) throws {
        let center = DeviceActivityCenter()
        center.stopMonitoring([.dailyUsage])
        guard !(selection.applicationTokens.isEmpty
                && selection.categoryTokens.isEmpty
                && selection.webDomainTokens.isEmpty) else { return }

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for minutes in stride(from: 15, through: 600, by: 15) {
            events[DeviceActivityEvent.Name(TimerName.usageEventPrefix + "\(minutes)")] = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                webDomains: selection.webDomainTokens,
                threshold: DateComponents(hour: minutes / 60, minute: minutes % 60)
            )
        }
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )
        try center.startMonitoring(.dailyUsage, during: schedule, events: events)
    }

    static func stopUsageTracking() {
        DeviceActivityCenter().stopMonitoring([.dailyUsage])
    }
}
