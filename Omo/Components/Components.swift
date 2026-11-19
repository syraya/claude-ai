import SwiftUI

/// OMO's colours, by role. They come from the OMO you've picked (see
/// Shared/Companions.swift); RootView rebuilds the screen when it changes.
extension Color {
    init(_ rgb: RGB) { self.init(red: rgb.r, green: rgb.g, blue: rgb.b) }

    private static var palette: ThemePalette { OmoCompanion.current.palette }
    static var omoPaper: Color { Color(palette.paper) }
    static var omoCard: Color { Color(palette.card) }
    static var omoInk: Color { Color(palette.ink) }
    /// Secondary text and small labels.
    static var omoLabels: Color { Color(palette.labels) }
    static var omoPrimary: Color { Color(palette.primary) }
    /// Text and icons on a primary-coloured fill.
    static var omoOnPrimary: Color { Color(palette.onPrimary) }
    static var omoGold: Color { Color(palette.gold) }
    static var omoClay: Color { Color(palette.clay) }
    static var omoSuccess: Color { Color(palette.success) }
    static var omoBlush: Color { Color(palette.blush) }
    /// Text on an `omoSuccess` button. Dark themes use a light success colour, so it gets dark text.
    static var omoOnSuccess: Color { OmoCompanion.current.isDark ? Color(palette.paper) : Color(palette.onPrimary) }
}

/// The logo's own colours (design reference 02). They stay the same in every theme.
enum Brand {
    static let lapis = Color(RGB(0x293F78))
    static let gold = Color(RGB(0xB4975A))
    static let parchment = Color(RGB(0xF5EFE3))
}

/// UIKit pieces SwiftUI doesn't style for us: serif navigation titles in the theme's ink.
enum ThemeAppearance {
    static func apply() {
        let ink = UIColor(Color.omoInk)
        func serif(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: serif(34, .bold), .foregroundColor: ink]
        appearance.titleTextAttributes = [.font: serif(17, .semibold), .foregroundColor: ink]
    }
}

extension Font {
    /// Serif headings, like the inscriptions in a classical painting.
    static func omoSerif(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif).weight(weight)
    }
}

/// The theme's paper, flat. Colour and proportion carry the Renaissance feel;
/// depth is kept for things that really sit above the page.
struct OmoBackground: View {
    var body: some View {
        Color.omoPaper.ignoresSafeArea()
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.omoCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.omoInk.opacity(0.09), lineWidth: 0.75)
            )
    }
}

/// Several rows in one surface, separated by thin dividers (the rows add their own).
struct GroupedCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.omoCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.omoInk.opacity(0.09), lineWidth: 0.75)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }
    func groupedCard() -> some View { modifier(GroupedCardModifier()) }

    /// Shows `message` as an alert and clears it when dismissed.
    func errorAlert(_ message: Binding<String?>) -> some View {
        alert("Heads up", isPresented: Binding(
            get: { message.wrappedValue != nil },
            set: { if !$0 { message.wrappedValue = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}

/// A short message that drops in from the top of the screen and goes away on its own.
struct TopBannerModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Color.omoClay)
                        Text(message)
                            .foregroundStyle(Color.omoInk)
                            .multilineTextAlignment(.leading)
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.omoCard, in: Capsule())
                    .overlay(Capsule().stroke(Color.omoClay.opacity(0.3), lineWidth: 1))
                    .shadow(color: Color.omoInk.opacity(0.15), radius: 12, y: 6)
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { self.message = nil }
                    .task(id: message) {
                        AccessibilityNotification.Announcement(message).post()
                        try? await Task.sleep(for: .seconds(2.5))
                        if self.message == message { self.message = nil }
                    }
                }
            }
            .animation(.spring(duration: 0.35), value: message)
    }
}

extension View {
    func topBanner(_ message: Binding<String?>) -> some View { modifier(TopBannerModifier(message: message)) }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .omoPrimary
    var textColor: Color = .omoOnPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    /// The outline and text colour. On a primary-coloured panel, use `.omoOnPrimary`.
    var color: Color = .omoPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(configuration.isPressed ? 0.12 : 0),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color, lineWidth: 1.25))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// For cards that open something: they give a little under your finger.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(duration: 0.25, bounce: 0.2), value: configuration.isPressed)
    }
}

/// Fades a tab's page in each time you arrive on it, instead of it snapping in.
private struct TabArrival: ViewModifier {
    @State private var arrived = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(arrived ? 1 : 0)
            .offset(y: arrived || reduceMotion ? 0 : 10)
            .onAppear { withAnimation(.easeOut(duration: 0.3)) { arrived = true } }
            .onDisappear { arrived = false }
    }
}

extension View {
    func tabArrival() -> some View { modifier(TabArrival()) }
}

struct ProgressRing: View {
    var progress: Double
    var color: Color = .omoPrimary
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

struct StatPill: View {
    var value: String
    var label: String
    var color: Color = .omoPrimary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .serif).weight(.semibold).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct Avatar: View {
    var name: String
    var size: CGFloat = 40

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }

    private var color: Color {
        let palette: [Color] = [.omoPrimary, .omoSuccess, .omoGold, .pink, .purple, .teal]
        let hash = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[abs(hash) % palette.count]
    }

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: Circle())
    }
}

enum Format {
    /// 1:05:09 or 12:34
    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }

    /// "1h 20m" or "45m"
    static func minutes(_ minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes)m" }
        let rest = minutes % 60
        return rest == 0 ? "\(minutes / 60)h" : "\(minutes / 60)h \(rest)m"
    }
}

/// Your intention for the session, drawn as a cartellino: the little slip of
/// paper Renaissance painters tucked into their pictures, bearing an inscription.
struct IntentionCard: View {
    var text: String

    var body: some View {
        VStack(spacing: 6) {
            // The slip is always paper-coloured, so its text keeps dark ink in every theme.
            Text("INTENTION")
                .font(.system(.caption2, design: .serif).weight(.semibold))
                .kerning(3)
                .foregroundStyle(Color(red: 0.75, green: 0.38, blue: 0.23))
            Text(text)
                .font(.system(.body, design: .serif).italic())
                .foregroundStyle(Color(red: 0.16, green: 0.17, blue: 0.27))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color(red: 0.99, green: 0.96, blue: 0.89), Color(red: 0.96, green: 0.91, blue: 0.80)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 4, style: .continuous)
        )
        .shadow(color: Color.omoInk.opacity(0.12), radius: 6, x: 2, y: 3)
        .rotationEffect(.degrees(-1.2))
        .padding(.horizontal, 6)
    }
}

/// A classical round arch: straight sides with a semicircle on top. OMO's main
/// visual motif, taken from the arcades in Renaissance paintings.
struct ArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.width / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.minY + radius), radius: radius,
                    startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Two arches around the timer ring, sharing its centre so their curves run alongside
/// the ring instead of crossing it. Put it behind a ring of `ringSize`, aligned to the top.
struct RingArches: View {
    var color: Color = .omoPrimary
    var ringSize: CGFloat
    /// How far the legs run below the ring.
    var legs: CGFloat = 28

    var body: some View {
        ZStack(alignment: .top) {
            ForEach([18, 34] as [CGFloat], id: \.self) { gap in
                ArchShape()
                    .stroke(color.opacity(gap < 20 ? 0.22 : 0.11), lineWidth: 1)
                    .frame(width: ringSize + gap * 2, height: ringSize + gap + legs)
                    .offset(y: -gap)
            }
        }
        .frame(width: ringSize, height: ringSize + legs, alignment: .top)
        .accessibilityHidden(true)
    }
}

/// The OMO logo, drawn to match the app icon (docs/brand/omo-logo.svg).
/// Leonardo's circle over a square, with two columns at the centre: a pause,
/// a place of thought, and two friends side by side.
struct OmoLogo: View {
    var size: CGFloat = 120

    var body: some View {
        Canvas { context, canvas in
            // Everything is laid out on the icon's 100 x 100 grid.
            let u = canvas.width / 100
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * u, y: y * u, width: w * u, height: h * u)
            }

            context.fill(Path(rect(0, 0, 100, 100)), with: .color(Brand.lapis))
            context.stroke(Path(rect(25, 30.5, 50, 50)), with: .color(Brand.gold), lineWidth: 3 * u)
            context.stroke(Path(ellipseIn: rect(19.5, 19.5, 61, 61)), with: .color(Brand.parchment), lineWidth: 3 * u)

            let top: CGFloat = 34.4, bottom: CGFloat = 74.41, capHeight: CGFloat = 2.8
            for shaftX in [40.75, 53.25] as [CGFloat] {
                let middle = shaftX + 3
                context.fill(Path(rect(shaftX, top + capHeight, 6, bottom - top - 2 * capHeight)),
                             with: .color(Brand.parchment))
                for capY in [top, bottom - capHeight] {
                    context.fill(Path(roundedRect: rect(middle - 4.8, capY, 9.6, capHeight), cornerRadius: 0.6 * u),
                                 with: .color(Brand.gold))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
        .accessibilityLabel("OMO")
    }
}
