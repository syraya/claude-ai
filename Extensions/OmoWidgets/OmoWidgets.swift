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
/// banner, and in the Dynamic Island around the camera.
struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            FocusBanner(context: context)
                .activityBackgroundTint(Color(hex: context.attributes.primary))
                .activitySystemActionForegroundColor(Color(hex: context.attributes.onPrimary))
        } dynamicIsland: { context in
            let attributes = context.attributes
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Figure(name: attributes.figureImage, paper: attributes.paper, size: 46)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Countdown(state: state, finished: context.isStale)
                        .font(.system(size: 30, weight: .semibold, design: .serif).monospacedDigit())
                        .foregroundStyle(Color(hex: attributes.gold))
                        .frame(maxWidth: 120, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(title(state: state, finished: context.isStale))
                            .font(.system(.headline, design: .serif))
                        Text(attributes.intention ?? "\(attributes.blockListName) blocked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Bar(state: state, tint: Color(hex: attributes.gold))
                        .padding(.horizontal, 6)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Figure(name: attributes.figureImage, paper: attributes.paper, size: 24)
            } compactTrailing: {
                Countdown(state: state, finished: context.isStale)
                    .font(.system(.caption, design: .serif).weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color(hex: attributes.gold))
                    .frame(maxWidth: 48)
            } minimal: {
                Figure(name: attributes.figureImage, paper: attributes.paper, size: 22)
            }
            .keylineTint(Color(hex: attributes.gold))
        }
    }
}

private func title(state: FocusActivityAttributes.ContentState, finished: Bool) -> String {
    if finished { return "Session complete" }
    return state.isOnBreak ? "On a break" : "Focusing"
}

/// The Lock Screen and Notification Centre banner.
private struct FocusBanner: View {
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        let attributes = context.attributes
        let state = context.state
        HStack(spacing: 14) {
            Figure(name: attributes.figureImage, paper: attributes.paper, size: 54)
            VStack(alignment: .leading, spacing: 4) {
                Text(title(state: state, finished: context.isStale))
                    .font(.system(.headline, design: .serif))
                Text(attributes.intention ?? "\(attributes.blockListName) blocked")
                    .font(.subheadline)
                    .opacity(0.8)
                    .lineLimit(1)
                Bar(state: state, tint: Color(hex: attributes.gold))
                    .padding(.top, 2)
            }
            Spacer(minLength: 8)
            Countdown(state: state, finished: context.isStale)
                .font(.system(size: 34, weight: .semibold, design: .serif).monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120, alignment: .trailing)
        }
        .foregroundStyle(Color(hex: attributes.onPrimary))
        .padding(16)
    }
}

/// Counts down by itself; the app doesn't need to update it every second.
private struct Countdown: View {
    let state: FocusActivityAttributes.ContentState
    let finished: Bool

    var body: some View {
        if finished || state.countdown.upperBound <= Date() {
            Text("Done")
        } else {
            Text(timerInterval: state.countdown, countsDown: true)
        }
    }
}

/// How far through the session (or break) you are.
private struct Bar: View {
    let state: FocusActivityAttributes.ContentState
    let tint: Color

    var body: some View {
        ProgressView(timerInterval: state.countdown, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(tint)
    }
}

/// Your OMO on a small disc of its paper colour.
private struct Figure: View {
    let name: String
    let paper: UInt32
    let size: CGFloat

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .padding(size * 0.12)
            .frame(width: size, height: size)
            .background(Color(hex: paper), in: Circle())
            .clipShape(Circle())
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
