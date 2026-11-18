import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Draws the screen that appears when you open a blocked app.
final class OmoShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(appName: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(appName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration(appName: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(appName: webDomain.domain)
    }

    private func makeConfiguration(appName: String?) -> ShieldConfiguration {
        let name = appName ?? "This app"
        // The colours, figure and voice of the OMO you've picked.
        let companion = SharedStore.settings.companion
        let palette = companion.palette
        let paper = UIColor(palette.paper)
        let ink = UIColor(palette.ink)
        let subtle = UIColor(palette.labels)
        let lapis = UIColor(palette.primary)
        let onLapis = UIColor(palette.onPrimary)
        let blur: UIBlurEffect.Style = companion.isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        let figure = figureIcon(companion) ?? icon("building.columns.fill", lapis)
        // A different line every time the screen appears.
        let quote = FocusQuotes.random(app: name, companion: companion)

        // After "Take a break" or "Ask for a break": point to the notification that opens OMO.
        if let pending = SharedStore.pendingShieldRequest,
           (pending == LocalNotifier.Route.takeBreak.rawValue && SharedStore.focusSession?.canTakeBreak == true)
            || (pending == LocalNotifier.Route.together.rawValue && SharedStore.friendLock != nil) {
            return ShieldConfiguration(
                backgroundBlurStyle: blur,
                backgroundColor: paper,
                icon: figure,
                title: .init(text: "Take a breath first", color: ink),
                subtitle: .init(text: "Tap the OMO notification at the top of your screen, or open OMO, to start your break.",
                                color: subtle),
                primaryButtonLabel: .init(text: "Never mind, back to focus", color: onLapis),
                primaryButtonBackgroundColor: lapis
            )
        }

        if let lock = SharedStore.friendLock, !lock.isOnBreak {
            return ShieldConfiguration(
                backgroundBlurStyle: blur,
                backgroundColor: paper,
                icon: figure,
                title: .init(text: "\(lock.keyholderName) holds your key", color: ink),
                subtitle: .init(text: "\(name) stays closed until \(lock.keyholderName) unlocks you.\n\n\(quote)",
                                color: subtle),
                primaryButtonLabel: .init(text: "Back to studying", color: onLapis),
                primaryButtonBackgroundColor: lapis,
                secondaryButtonLabel: .init(text: "Ask for a break", color: lapis)
            )
        }

        if let session = SharedStore.focusSession {
            let minutesLeft = Int((session.remaining() / 60).rounded(.up))
            var lines = ["\(name) is resting for \(minutesLeft) more minute\(minutesLeft == 1 ? "" : "s")."]
            if let intention = session.intention { lines.append("Your intention: \(intention)") }
            lines.append(quote)
            return ShieldConfiguration(
                backgroundBlurStyle: blur,
                backgroundColor: paper,
                icon: figure,
                title: .init(text: "Stay with your thoughts", color: ink),
                subtitle: .init(text: lines.joined(separator: "\n\n"), color: subtle),
                primaryButtonLabel: .init(text: "Back to focus", color: onLapis),
                primaryButtonBackgroundColor: lapis,
                secondaryButtonLabel: session.canTakeBreak ? .init(text: "Take a break", color: lapis) : nil
            )
        }

        if let schedule = ScheduleEngine.activeSchedules().first {
            let until = schedule.endDate().map { " until \($0.formatted(date: .omitted, time: .shortened))" } ?? ""
            let title = schedule.name.isEmpty ? "Scheduled block" : schedule.name
            return ShieldConfiguration(
                backgroundBlurStyle: blur,
                backgroundColor: paper,
                icon: figure,
                title: .init(text: title, color: ink),
                subtitle: .init(text: "\(name) is blocked\(until) by your schedule.\n\n\(quote)", color: subtle),
                primaryButtonLabel: .init(text: "Back to it", color: onLapis),
                primaryButtonBackgroundColor: lapis
            )
        }

        return ShieldConfiguration(
            backgroundBlurStyle: blur,
            backgroundColor: paper,
            icon: figure,
            title: .init(text: "Blocked by OMO", color: ink),
            subtitle: .init(text: quote, color: subtle),
            primaryButtonLabel: .init(text: "OK", color: onLapis),
            primaryButtonBackgroundColor: lapis
        )
    }

    /// Your OMO, drawn small. Shield extensions get very little memory, so the figure
    /// is rendered at icon size rather than loaded at full resolution.
    private func figureIcon(_ companion: OmoCompanion) -> UIImage? {
        guard let image = UIImage(named: companion.imageName) else { return nil }
        let size = CGSize(width: 88, height: 88)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func icon(_ symbol: String, _ color: UIColor) -> UIImage? {
        UIImage(systemName: symbol)?.withTintColor(color, renderingMode: .alwaysOriginal)
    }
}

private extension UIColor {
    convenience init(_ rgb: RGB) {
        self.init(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
    }
}
