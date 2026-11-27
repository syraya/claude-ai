import SwiftUI

/// What the focus Live Activity draws, shared by the OmoWidgets extension and the
/// app's simulator preview (the simulator can't show the real Lock Screen or Dynamic
/// Island in screenshots). Plain values in, so neither needs ActivityKit's context.
///
/// Like FocusActivity.swift, this file is compiled into the widget, so it must not
/// use anything else from Shared.
struct FocusActivityLook {
    let attributes: FocusActivityAttributes
    let state: FocusActivityAttributes.ContentState
    /// Past the session's end without OMO having closed it.
    let finished: Bool

    var paper: Color { Color(activityHex: attributes.paper) }
    var ink: Color { Color(activityHex: attributes.ink) }
    var labels: Color { Color(activityHex: attributes.labels) }
    var gold: Color { Color(activityHex: attributes.gold) }
    var primary: Color { Color(activityHex: attributes.primary) }

    var status: String {
        if finished { return "Session complete" }
        return state.isOnBreak ? "On a break" : "Focusing"
    }

    var headline: String {
        if finished { return "Well done" }
        if state.isOnBreak { return "Back to it soon" }
        return attributes.intention?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "\(attributes.blockListName) blocked"
    }
}

/// The Lock Screen and Notification Centre banner: the OMO's tile, what you're
/// focusing on, and the time left, in the OMO's own colours.
struct FocusBannerView: View {
    let look: FocusActivityLook

    var body: some View {
        HStack(spacing: 14) {
            FigureTile(name: look.attributes.figureImage, background: look.paper, size: 62)
                .overlay(RoundedRectangle(cornerRadius: 62 * 0.26, style: .continuous)
                    .stroke(look.ink.opacity(0.08), lineWidth: 1))
            VStack(alignment: .leading, spacing: 5) {
                Text("\(look.attributes.companionName) · \(look.status)".uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(look.labels)
                    .lineLimit(1)
                Text(look.headline)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(look.ink)
                    .lineLimit(2)
                FocusProgress(state: look.state, tint: look.state.isOnBreak ? look.gold : look.primary,
                              track: look.ink.opacity(0.1))
                    .padding(.top, 3)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 0) {
                FocusCountdown(state: look.state, finished: look.finished)
                    .font(.system(size: 30, weight: .semibold, design: .serif).monospacedDigit())
                    .foregroundStyle(look.ink)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 110, alignment: .trailing)
                Text(look.finished ? " " : "left")
                    .font(.caption)
                    .foregroundStyle(look.labels)
            }
        }
        .padding(16)
    }
}

/// The Dynamic Island, opened up: everything from the banner, on black.
struct FocusIslandExpandedView: View {
    let look: FocusActivityLook

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                FigureTile(name: look.attributes.figureImage, background: look.paper, size: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(look.attributes.companionName) · \(look.status)".uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(look.gold)
                        .lineLimit(1)
                    Text(look.headline)
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                FocusCountdown(state: look.state, finished: look.finished)
                    .font(.system(size: 26, weight: .semibold, design: .serif).monospacedDigit())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 96, alignment: .trailing)
            }
            FocusProgress(state: look.state, tint: look.gold, track: .white.opacity(0.18))
        }
    }
}

/// The OMO's figure on its paper colour, in the same rounded square as the app.
struct FigureTile: View {
    let name: String
    let background: Color
    let size: CGFloat

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .padding(size * 0.13)
            .frame(width: size, height: size)
            .background(background, in: RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
    }
}

/// Counts down by itself; the app doesn't need to update it every second.
struct FocusCountdown: View {
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

/// How far through the session (or break) you are, as a slim rounded bar that fills
/// by itself.
struct FocusProgress: View {
    let state: FocusActivityAttributes.ContentState
    let tint: Color
    let track: Color

    var body: some View {
        ProgressView(timerInterval: state.countdown, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(tint)
        .background(track, in: Capsule())
        .clipShape(Capsule())
    }
}

extension Color {
    init(activityHex hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
