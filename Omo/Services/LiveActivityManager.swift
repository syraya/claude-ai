import ActivityKit
import Foundation

/// Keeps the focus session's Live Activity in step with the session itself: started
/// when a session starts, updated for breaks, ended when the session ends.
/// FocusController calls `sync` whenever it refreshes, so every change lands here.
@MainActor
enum LiveActivityManager {
    static func sync(session: FocusSession?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let activities = Activity<FocusActivityAttributes>.activities

        guard let session, session.endsAt > Date() else {
            end(activities)
            return
        }

        let state = FocusActivityAttributes.ContentState(
            startedAt: session.startedAt,
            endsAt: session.endsAt,
            breakStartedAt: session.breakStartedAt,
            breakEndsAt: session.breakEndsAt
        )
        // Past the end it shows "Session complete", even if OMO isn't opened.
        let content = ActivityContent(state: state, staleDate: session.endsAt)

        if let current = activities.first(where: { $0.attributes.sessionID == session.id.uuidString }) {
            end(activities.filter { $0.id != current.id })
            guard current.content.state != state else { return }
            Task { await current.update(content) }
            return
        }

        end(activities)
        let companion = OmoCompanion.current
        let palette = companion.palette
        let attributes = FocusActivityAttributes(
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
            labels: hex(palette.labels)
        )
        _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
    }

    private static func end(_ activities: [Activity<FocusActivityAttributes>]) {
        for activity in activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    static func hex(_ rgb: RGB) -> UInt32 {
        func channel(_ value: Double) -> UInt32 { UInt32((min(max(value, 0), 1) * 255).rounded()) }
        return channel(rgb.r) << 16 | channel(rgb.g) << 8 | channel(rgb.b)
    }
}
