import SwiftUI

/// OMO's palette, taken from a Shinto shrine on a bright morning: washi paper,
/// torii vermilion, indigo ink, temple gold, matcha and sakura.
extension Color {
    static let omoPaper = Color(red: 0.98, green: 0.965, blue: 0.935)
    static let omoCard = Color.white
    static let omoInk = Color(red: 0.17, green: 0.19, blue: 0.31)
    static let omoVermilion = Color(red: 0.90, green: 0.33, blue: 0.24)
    static let omoGold = Color(red: 0.91, green: 0.66, blue: 0.23)
    static let omoMatcha = Color(red: 0.40, green: 0.64, blue: 0.40)
    static let omoSakura = Color(red: 0.96, green: 0.66, blue: 0.73)
}

extension Font {
    /// Serif headings: calmer and more contemplative than the default.
    static func omoSerif(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif).weight(weight)
    }
}

/// Warm paper with soft morning light in the corners.
struct OmoBackground: View {
    var body: some View {
        ZStack {
            Color.omoPaper
            RadialGradient(colors: [Color.omoGold.opacity(0.22), .clear],
                           center: .topTrailing, startRadius: 10, endRadius: 420)
            RadialGradient(colors: [Color.omoSakura.opacity(0.18), .clear],
                           center: .bottomLeading, startRadius: 10, endRadius: 380)
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
    var color: Color = .omoVermilion

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
            .foregroundStyle(Color.omoVermilion)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.omoVermilion.opacity(configuration.isPressed ? 0.25 : 0.14),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ProgressRing: View {
    var progress: Double
    var color: Color = .omoVermilion
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
    var color: Color = .omoVermilion

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
        let palette: [Color] = [.omoVermilion, .omoMatcha, .omoGold, .pink, .purple, .teal]
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

/// A small wooden ema plaque showing your intention for the session.
struct EmaView: View {
    var text: String

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color.omoVermilion)
                .frame(width: 8, height: 8)
            Text("絵馬 · intention")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.omoInk.opacity(0.5))
            Text(text)
                .font(.system(.body, design: .serif).italic())
                .foregroundStyle(Color.omoInk)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color(red: 0.98, green: 0.91, blue: 0.78), Color(red: 0.95, green: 0.85, blue: 0.68)],
                           startPoint: .top, endPoint: .bottom),
            in: UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 10,
                                       bottomTrailingRadius: 10, topTrailingRadius: 28, style: .continuous)
        )
    }
}
