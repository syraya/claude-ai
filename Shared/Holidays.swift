import Foundation

/// Holidays with their own OMO. Focus for 25 minutes in one session during the holiday
/// and that OMO is yours to keep.
enum OmoHoliday: String, CaseIterable, Codable {
    case newYear, lunarNewYear, valentines, earthDay, canadaDay, teachersDay, halloween, thanksgiving, christmas

    var name: String {
        switch self {
        case .newYear: return "New Year"
        case .lunarNewYear: return "Lunar New Year"
        case .valentines: return "Valentine's Day"
        case .earthDay: return "Earth Day"
        case .canadaDay: return "Canada Day"
        case .teachersDay: return "World Teachers' Day"
        case .halloween: return "Halloween"
        case .thanksgiving: return "Thanksgiving"
        case .christmas: return "Christmas"
        }
    }

    /// When it happens, in words.
    var when: String {
        switch self {
        case .newYear: return "December 31 and January 1"
        case .lunarNewYear: return "the first three days of the Lunar New Year"
        case .valentines: return "February 14"
        case .earthDay: return "April 22"
        case .canadaDay: return "July 1"
        case .teachersDay: return "October 5"
        case .halloween: return "October 31"
        case .thanksgiving: return "Canadian or American Thanksgiving weekend"
        case .christmas: return "December 24 to 26"
        }
    }

    /// Minutes of focus in one session needed during the holiday.
    static let requiredMinutes = 25

    /// The first day of each Lunar New Year. Extend this list as the years go by.
    private static let lunarNewYears: [Int: (month: Int, day: Int)] = [
        2026: (2, 17), 2027: (2, 6), 2028: (1, 26), 2029: (2, 13), 2030: (2, 3),
        2031: (1, 23), 2032: (2, 11), 2033: (1, 31), 2034: (2, 19), 2035: (2, 8),
    ]

    func isActive(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        let c = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        guard let year = c.year, let month = c.month, let day = c.day else { return false }
        switch self {
        case .newYear: return (month == 12 && day == 31) || (month == 1 && day == 1)
        case .valentines: return month == 2 && day == 14
        case .earthDay: return month == 4 && day == 22
        case .canadaDay: return month == 7 && day == 1
        case .teachersDay: return month == 10 && day == 5
        case .halloween: return month == 10 && day == 31
        case .christmas: return month == 12 && (24...26).contains(day)
        case .lunarNewYear:
            guard let first = Self.lunarNewYears[year],
                  let start = calendar.date(from: DateComponents(year: year, month: first.month, day: first.day)),
                  let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: start),
                                                     to: calendar.startOfDay(for: date)).day else { return false }
            return (0...2).contains(days)
        case .thanksgiving:
            return Self.isCanadianThanksgivingWeekend(date, calendar) || Self.isAmericanThanksgivingWeekend(date, calendar)
        }
    }

    /// Saturday to Monday, where Monday is the second Monday of October.
    private static func isCanadianThanksgivingWeekend(_ date: Date, _ calendar: Calendar) -> Bool {
        (0...2).contains { offset in
            guard let d = calendar.date(byAdding: .day, value: offset, to: date) else { return false }
            let c = calendar.dateComponents([.month, .day, .weekday], from: d)
            return c.month == 10 && c.weekday == 2 && (8...14).contains(c.day ?? 0)
        }
    }

    /// Thursday to Sunday, where Thursday is the fourth Thursday of November.
    private static func isAmericanThanksgivingWeekend(_ date: Date, _ calendar: Calendar) -> Bool {
        (0...3).contains { offset in
            guard let d = calendar.date(byAdding: .day, value: -offset, to: date) else { return false }
            let c = calendar.dateComponents([.month, .day, .weekday], from: d)
            return c.month == 11 && c.weekday == 5 && (22...28).contains(c.day ?? 0)
        }
    }

    static func active(on date: Date = Date()) -> [OmoHoliday] {
        allCases.filter { $0.isActive(on: date) }
    }
}
