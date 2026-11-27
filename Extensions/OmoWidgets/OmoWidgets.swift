import ActivityKit
import SwiftUI
import WidgetKit

@main
struct OmoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FocusLiveActivity()
    }
}

/// Your focus session, live: on the Lock Screen and in Notification Centre as a
/// banner, and in the Dynamic Island around the camera. The views themselves are in
/// Shared/FocusActivityViews.swift, so the app can preview them too.
struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            let look = FocusActivityLook(attributes: context.attributes, state: context.state,
                                         finished: context.isStale)
            FocusBannerView(look: look)
                .activityBackgroundTint(look.paper)
                .activitySystemActionForegroundColor(look.ink)
        } dynamicIsland: { context in
            let look = FocusActivityLook(attributes: context.attributes, state: context.state,
                                         finished: context.isStale)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    FocusIslandExpandedView(look: look)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                }
            } compactLeading: {
                FigureTile(name: look.attributes.figureImage, background: look.paper, size: 24)
            } compactTrailing: {
                FocusCountdown(state: look.state, finished: look.finished)
                    .font(.system(.caption, design: .serif).weight(.semibold).monospacedDigit())
                    .foregroundStyle(look.gold)
                    .frame(maxWidth: 50)
            } minimal: {
                FigureTile(name: look.attributes.figureImage, background: look.paper, size: 22)
            }
            .keylineTint(look.gold)
        }
    }
}
