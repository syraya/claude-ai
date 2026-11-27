import Foundation
import ActivityKit

/// A focus session shown live on the Lock Screen, in Notification Centre and in the
/// Dynamic Island. The app starts it and keeps it up to date (LiveActivityManager);
/// the OmoWidgets extension draws it.
///
/// This file is the only shared code the widget extension compiles, so it must not
/// use anything else from Shared (in particular nothing from Screen Time).
struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startedAt: Date
        var endsAt: Date
        /// Both set while you're on a break.
        var breakStartedAt: Date?
        var breakEndsAt: Date?

        var isOnBreak: Bool { breakEndsAt != nil }

        /// The stretch the timer counts down: the break while on one, else the session.
        var countdown: ClosedRange<Date> {
            if let breakStartedAt, let breakEndsAt, breakStartedAt < breakEndsAt {
                return breakStartedAt...breakEndsAt
            }
            return min(startedAt, endsAt)...endsAt
        }
    }

    /// Which session this is, so a new session replaces the old activity.
    var sessionID: String
    var intention: String?
    var blockListName: String
    var companionName: String
    /// The OMO's figure in Figures.xcassets.
    var figureImage: String
    /// The OMO's theme colours as 0xRRGGBB.
    var primary: UInt32
    var onPrimary: UInt32
    var paper: UInt32
    var gold: UInt32
    var ink: UInt32
    var labels: UInt32
}
