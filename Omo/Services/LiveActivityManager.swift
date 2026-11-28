import ActivityKit
import Foundation

/// Keeps the focus session's Live Activity in step with the session itself: started
/// when a session starts, updated for breaks, ended when the session ends.
/// FocusController calls `sync` whenever it refreshes, so every change lands here.
///
/// ActivityKit's calls wait on iOS, so the work runs on its own serial queue: the
/// interface never waits for it (ending a session used to stutter here), and changes
/// still apply in the order they happened.
@MainActor
enum LiveActivityManager {
    private static let queue = DispatchQueue(label: "omo.liveActivity", qos: .userInitiated)

    static func sync(session: FocusSession?) {
        // Read everything that lives on the main actor here; hand plain values over.
        let wanted: (id: String, state: FocusActivityAttributes.ContentState, ends: Date,
                     attributes: FocusActivityAttributes)?
        if let session, session.endsAt > Date() {
            let companion = OmoCompanion.current
            let palette = companion.palette
            wanted = (
                id: session.id.uuidString,
                state: FocusActivityAttributes.ContentState(
                    startedAt: session.startedAt,
                    endsAt: session.endsAt,
                    breakStartedAt: session.breakStartedAt,
                    breakEndsAt: session.breakEndsAt),
                ends: session.endsAt,
                attributes: FocusActivityAttributes(
                    sessionID: session.id.uuidString,
                    intention: session.intention,
                    blockListName: session.blockListName,
                    companionName: companion.name,
                    figureImage: companion.imageName,
                    primary: hex(palette.primary),
                    onPrimary: hex(palette.onPrimary),
                    paper: hex(palette.paper),
                    gold: hex(palette.gold),
                    ink: hex(palette.ink),
                    labels: hex(palette.labels))
            )
        } else {
            wanted = nil
        }
        queue.async { apply(wanted) }
    }

    nonisolated private static func apply(_ wanted: (id: String, state: FocusActivityAttributes.ContentState, ends: Date,
                                                      attributes: FocusActivityAttributes)?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let activities = Activity<FocusActivityAttributes>.activities
        guard let wanted else {
            end(activities)
            return
        }
        // Past the end it shows "Session complete", even if OMO isn't opened.
        let content = ActivityContent(state: wanted.state, staleDate: wanted.ends)
        if let current = activities.first(where: { $0.attributes.sessionID == wanted.id }) {
            end(activities.filter { $0.id != current.id })
            guard current.content.state != wanted.state else { return }
            Task { await current.update(content) }
            return
        }
        end(activities)
        _ = try? Activity.request(attributes: wanted.attributes, content: content, pushType: nil)
    }

    nonisolated private static func end(_ activities: [Activity<FocusActivityAttributes>]) {
        for activity in activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    nonisolated static func hex(_ rgb: RGB) -> UInt32 {
        func channel(_ value: Double) -> UInt32 { UInt32((min(max(value, 0), 1) * 255).rounded()) }
        return channel(rgb.r) << 16 | channel(rgb.g) << 8 | channel(rgb.b)
    }
}
