import SwiftUI

/// OMO's palette, borrowed from Renaissance frescoes of philosophers at work:
/// plaster and parchment, lapis-lazuli ultramarine, ochre gold, burnt sienna,
/// verdigris and madder rose. Bright, warm and calm.
extension Color {
    static let omoParchment = Color(red: 0.98, green: 0.955, blue: 0.91)
    static let omoCard = Color.white
    static let omoInk = Color(red: 0.16, green: 0.17, blue: 0.27)
    static let omoLapis = Color(red: 0.18, green: 0.29, blue: 0.62)
    static let omoOchre = Color(red: 0.84, green: 0.63, blue: 0.23)
    static let omoSienna = Color(red: 0.75, green: 0.38, blue: 0.23)
    static let omoVerdigris = Color(red: 0.36, green: 0.61, blue: 0.54)
    static let omoRose = Color(red: 0.85, green: 0.55, blue: 0.48)
}

extension Font {
    /// Serif headings, like the inscriptions in a classical painting.
    static func omoSerif(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif).weight(weight)
    }
}

/// Warm plaster, with ochre light from above and a faint rose glow below, like
/// the sky behind a fresco's arches.
struct OmoBackground: View {
    var body: some View {
        ZStack {
            Color.omoParchment
            RadialGradient(colors: [Color.omoOchre.opacity(0.20), .clear],
                           center: .top, startRadius: 10, endRadius: 460)
            RadialGradient(colors: [Color.omoRose.opacity(0.14), .clear],
                           center: .bottomTrailing, startRadius: 10, endRadius: 380)
        }
        .ignoresSafeArea()
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.omoCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.omoInk.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.omoInk.opacity(0.06), radius: 12, y: 4)
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }

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

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .omoLapis

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.omoLapis)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.omoLapis.opacity(configuration.isPressed ? 0.25 : 0.14),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ProgressRing: View {
    var progress: Double
    var color: Color = .omoLapis
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
    var color: Color = .omoLapis

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
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
        let palette: [Color] = [.omoLapis, .omoVerdigris, .omoOchre, .pink, .purple, .teal]
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
            Text("INTENTION")
                .font(.system(.caption2, design: .serif).weight(.semibold))
                .kerning(3)
                .foregroundStyle(Color.omoSienna)
            Text(text)
                .font(.system(.body, design: .serif).italic())
                .foregroundStyle(Color.omoInk)
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

/// Three arches receding toward the centre, drawn faintly behind content.
struct ArcadeBackdrop: View {
    var color: Color = .omoLapis

    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                ArchShape()
                    .stroke(color.opacity(0.10 + Double(index) * 0.05), lineWidth: 1.5)
                    .scaleEffect(1 - CGFloat(index) * 0.16, anchor: .bottom)
            }
        }
    }
}
