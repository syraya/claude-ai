import Foundation
import DeviceActivity
import ManagedSettings

/// A block that turns itself on at set times, e.g. "Work: weekdays, 9:00 to 17:00".
struct BlockSchedule: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String = ""
    /// The block list it blocks. Edits to that list apply from the next check.
    var blockListID: UUID?
    var startHour = 9
    var startMinute = 0
    var endHour = 17
    var endMinute = 0
    /// Calendar weekdays: 1 is Sunday, 7 is Saturday. For a block that runs past
    /// midnight, this is the day it starts.
    var weekdays: Set<Int> = BlockSchedule.weekdaysOnly
    var isEnabled = true
    /// A strict schedule can't be turned off, edited or deleted while it's blocking.
    var isStrict = false
    /// Whether its blocked time adds to your focus totals. Unset means the default:
    /// yes for daytime schedules, no for overnight ones, so sleep doesn't count.
    var countsAsFocus: Bool?

    var countsTowardFocus: Bool { countsAsFocus ?? !crossesMidnight }

    static let everyDay: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    static let weekdaysOnly: Set<Int> = [2, 3, 4, 5, 6]
    static let weekendsOnly: Set<Int> = [1, 7]
    /// iOS won't run a repeating schedule shorter than this.
    static let minimumMinutes = 15

    var startMinutes: Int { startHour * 60 + startMinute }
    var endMinutes: Int { endHour * 60 + endMinute }
    var crossesMidnight: Bool { endMinutes <= startMinutes }
    var durationMinutes: Int { (endMinutes - startMinutes + 1440) % 1440 }

    /// Whether it should be blocking at `date`.
    func isActive(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard isEnabled else { return false }
        let parts = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        guard let weekday = parts.weekday, let hour = parts.hour, let minute = parts.minute else { return false }
        let now = hour * 60 + minute
        if !crossesMidnight {
            return weekdays.contains(weekday) && now >= startMinutes && now < endMinutes
        }
        let yesterday = weekday == 1 ? 7 : weekday - 1
        return (weekdays.contains(weekday) && now >= startMinutes)
            || (weekdays.contains(yesterday) && now < endMinutes)
    }

    /// When the block that's on at `date` lifts.
    func endDate(after date: Date = Date(), calendar: Calendar = .current) -> Date? {
        calendar.nextDate(after: date, matching: DateComponents(hour: endHour, minute: endMinute),
                          matchingPolicy: .nextTime)
    }

    /// When the block that's on at `date` started (yesterday, for one past midnight).
    func occurrenceStart(at date: Date, calendar: Calendar = .current) -> Date? {
        guard isActive(at: date, calendar: calendar),
              let today = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: date)
        else { return nil }
        return today <= date ? today : calendar.date(byAdding: .day, value: -1, to: today)
    }

    /// Locked: strict and blocking right now.
    func isLocked(at date: Date = Date()) -> Bool { isStrict && isActive(at: date) }

    /// "9:00 AM – 5:00 PM", in the phone's own time format.
    var timeText: String {
        func text(_ hour: Int, _ minute: Int) -> String {
            let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
            return date.formatted(date: .omitted, time: .shortened)
        }
        return "\(text(startHour, startMinute)) – \(text(endHour, endMinute))"
    }

    /// "Weekdays", "Weekends", "Every day" or "Mon, Wed, Fri".
    var daysText: String {
        switch weekdays {
        case Self.everyDay: return "Every day"
        case Self.weekdaysOnly: return "Weekdays"
        case Self.weekendsOnly: return "Weekends"
        case []: return "No days"
        default:
            let symbols = Calendar.current.shortWeekdaySymbols
            return Self.orderedWeekdays.filter(weekdays.contains).map { symbols[$0 - 1] }.joined(separator: ", ")
        }
    }

    /// Weekdays in the order this phone's calendar shows them (Sunday or Monday first).
    static var orderedWeekdays: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }
}

/// A scheduled block that's running and counts as focus, so its time can be added up.
struct ScheduleRun: Codable, Equatable {
    /// When this occurrence of the schedule began.
    var occurrence: Date
    /// When counting began: when OMO first saw this block running. That's the
    /// occurrence when iOS wakes OMO at the start time, or later if the schedule was
    /// switched on halfway through.
    var start: Date
    /// When this occurrence is scheduled to end. Counting never goes past it.
    var end: Date
    /// Time a focus session or friend lock already counted while this block ran.
    var excludedSeconds: TimeInterval = 0
    /// Set on runs started by this version. Runs saved by the first version counted
    /// from the scheduled start even when the schedule was switched on later.
    var startsWhenSeen: Bool?
}

extension ManagedSettingsStore.Name {
    /// Each schedule has its own store, so one ending never lifts another.
    static func schedule(_ id: UUID) -> Self { Self("omo.schedule." + id.uuidString) }
}

/// Runs the schedules. iOS wakes the monitor extension at every start and end time,
/// even with OMO closed; the extension and the app both call into this.
enum ScheduleEngine {
    static let activityPrefix = "omo.schedule."
    /// iOS caps how many schedules one app can monitor. This leaves room for the
    /// session, break and usage timers.
    static let maxSchedules = 12

    static func activityName(_ id: UUID) -> DeviceActivityName {
        DeviceActivityName(activityPrefix + id.uuidString)
    }

    /// Registers the schedules with iOS after one was added, changed or removed.
    /// Throws if iOS refuses one (e.g. too short, or too many).
    static func sync() throws {
        let center = DeviceActivityCenter()
        let schedules = SharedStore.schedules
        let wanted = Set(schedules.filter(\.isEnabled).map { activityName($0.id) })
        center.stopMonitoring(center.activities.filter { $0.rawValue.hasPrefix(activityPrefix) && !wanted.contains($0) })

        var firstError: Error?
        for schedule in schedules where schedule.isEnabled {
            do {
                try center.startMonitoring(activityName(schedule.id), during: deviceSchedule(for: schedule))
            } catch {
                firstError = firstError ?? error
            }
        }
        reconcile()
        if let firstError { throw firstError }
    }

    /// Puts every schedule's block in the state it should be in at `date`, and adds up
    /// the focus time of any block that has ended.
    static func reconcile(at date: Date = Date()) {
        let lists = SharedStore.blockLists
        let center = DeviceActivityCenter()
        let monitored = Set(center.activities)
        trackFocusTime(at: date, lists: lists)
        for schedule in SharedStore.schedules {
            // Re-register anything iOS forgot, e.g. after restoring the phone.
            if schedule.isEnabled, !monitored.contains(activityName(schedule.id)) {
                try? center.startMonitoring(activityName(schedule.id), during: deviceSchedule(for: schedule))
            }
            if schedule.isActive(at: date),
               let list = lists.first(where: { $0.id == schedule.blockListID }), !list.isEmpty {
                ShieldManager.shield(list.selection, in: .schedule(schedule.id))
            } else {
                ShieldManager.clear(.schedule(schedule.id))
            }
        }
    }

    /// Called by the monitor extension when a schedule starts or ends. Checks a little
    /// ahead, since iOS can wake us a few seconds early.
    static func handleEvent(named name: String) {
        guard name.hasPrefix(activityPrefix) else { return }
        reconcile(at: Date().addingTimeInterval(30))
    }

    /// Stops a deleted schedule and lifts its block.
    static func remove(_ schedule: BlockSchedule) {
        DeviceActivityCenter().stopMonitoring([activityName(schedule.id)])
        ShieldManager.clear(.schedule(schedule.id))
    }

    // MARK: Focus time

    /// How late iOS's start-time wake-up can be and still count from the scheduled start.
    private static let startSlack: TimeInterval = 3 * 60

    /// Starts counting blocks that have begun and records the ones that have ended.
    private static func trackFocusTime(at date: Date, lists: [BlockList]) {
        let now = Date()
        let schedules = SharedStore.schedules
        var runs = SharedStore.scheduleRuns
        let before = runs
        for schedule in schedules {
            let key = schedule.id.uuidString
            let blocking = schedule.countsTowardFocus
                && lists.contains { $0.id == schedule.blockListID && !$0.isEmpty }
            let occurrence = blocking ? schedule.occurrenceStart(at: date) : nil
            if let run = runs[key], run.occurrence != occurrence {
                // That block is over (or was switched off): count its time.
                record(run, until: min(now, run.end))
                runs[key] = nil
            }
            if let occurrence, runs[key] == nil {
                // Count from now, not from the scheduled start: a block only counts once
                // OMO has seen it running. iOS wakes OMO at the start time, so a schedule
                // that was on all along still counts in full (within a little slack).
                let seen = now.timeIntervalSince(occurrence) < startSlack ? occurrence : now
                runs[key] = ScheduleRun(occurrence: occurrence, start: seen,
                                        end: occurrence.addingTimeInterval(TimeInterval(schedule.durationMinutes * 60)),
                                        startsWhenSeen: true)
            } else if let run = runs[key], run.startsWhenSeen == nil {
                // A run from the first version may have counted from the scheduled start
                // even though the schedule was switched on later. Count it from now.
                runs[key]?.start = max(run.start, now)
                runs[key]?.startsWhenSeen = true
            }
        }
        // Schedules that were deleted while blocking.
        for (key, run) in runs where !schedules.contains(where: { $0.id.uuidString == key }) {
            record(run, until: min(now, run.end))
            runs[key] = nil
        }
        if runs != before { SharedStore.scheduleRuns = runs }
    }

    private static func record(_ run: ScheduleRun, until end: Date) {
        // A run left by the first version may start too early; never count it before now.
        let start = run.startsWhenSeen == nil ? max(run.start, Date()) : run.start
        let minutes = Int((end.timeIntervalSince(start) - run.excludedSeconds) / 60)
        guard minutes > 0 else { return }
        FocusEngine.recordScheduledFocus(minutes: minutes, endedAt: end)
    }

    /// A session or friend lock from `start` to now has already been counted, so the
    /// schedules blocking at the same time don't count it again.
    static func excludeOverlap(from start: Date, to end: Date = Date()) {
        var runs = SharedStore.scheduleRuns
        guard !runs.isEmpty else { return }
        for (key, run) in runs {
            runs[key]?.excludedSeconds += max(0, end.timeIntervalSince(max(run.start, start)))
        }
        SharedStore.scheduleRuns = runs
    }

    /// Focus minutes today from blocks still running. `alsoCounting` is the start of a
    /// session or friend lock running now, whose overlap shouldn't count twice.
    static func runningMinutesToday(at now: Date, alsoCounting otherStart: Date?) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: now)
        var seconds: TimeInterval = 0
        for run in SharedStore.scheduleRuns.values {
            let from = max(run.start, startOfDay)
            let until = min(now, run.end)
            var counted = until.timeIntervalSince(from) - run.excludedSeconds
            if let otherStart { counted -= max(0, until.timeIntervalSince(max(from, otherStart))) }
            seconds += max(0, counted)
        }
        return Int(seconds / 60)
    }

    /// The schedules blocking now, for the block screen and the Focus tab.
    static func activeSchedules(at date: Date = Date()) -> [BlockSchedule] {
        let lists = SharedStore.blockLists
        return SharedStore.schedules.filter { schedule in
            schedule.isActive(at: date)
                && lists.contains { $0.id == schedule.blockListID && !$0.isEmpty }
        }
    }

    private static func deviceSchedule(for schedule: BlockSchedule) -> DeviceActivitySchedule {
        // Daily at these times; the weekdays are checked when it fires, so one
        // schedule needs only one of iOS's limited monitoring slots.
        DeviceActivitySchedule(
            intervalStart: DateComponents(hour: schedule.startHour, minute: schedule.startMinute),
            intervalEnd: DateComponents(hour: schedule.endHour, minute: schedule.endMinute),
            repeats: true
        )
    }
}
