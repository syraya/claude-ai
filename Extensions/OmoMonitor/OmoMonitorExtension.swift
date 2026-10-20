import DeviceActivity
import Foundation

/// iOS wakes this up in the background when one of our scheduled timers ends or a
/// usage threshold is crossed. It has a small memory budget, so keep it lean.
final class OmoMonitorExtension: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        FocusEngine.handleTimer(named: activity.rawValue)
    }

    /// Short timers (under 15 minutes) land here instead; see ActivityScheduler.
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        FocusEngine.handleTimer(named: activity.rawValue)
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard activity == .dailyUsage else { return }
        FocusEngine.recordUsageThreshold(eventName: event.rawValue)
    }
}
