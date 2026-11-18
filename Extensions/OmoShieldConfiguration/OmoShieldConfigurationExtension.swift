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
        // Use the colours (and figure) of the OMO you've picked.
        let companion = SharedStore.settings.companion
        let palette = companion.palette
        let paper = UIColor(palette.paper)
        let ink = UIColor(palette.ink)
        let subtle = UIColor(palette.labels)
        let lapis = UIColor(palette.primary)
        let onLapis = UIColor(palette.onPrimary)
        let blur: UIBlurEffect.Style = companion.isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight

        if let lock = SharedStore.friendLock, !lock.isOnBreak {
            return ShieldConfiguration(
                backgroundBlurStyle: blur,
                backgroundColor: paper,
                icon: icon("person.2.badge.key.fill", lapis),
                title: .init(text: "\(lock.keyholderName) holds your key", color: ink),
                subtitle: .init(text: "\(name) stays closed until \(lock.keyholderName) unlocks you. Your circle is counting on you.",
                                color: subtle),
                primaryButtonLabel: .init(text: "Back to studying", color: onLapis),
                primaryButtonBackgroundColor: lapis,
                secondaryButtonLabel: .init(text: "Ask for a break", color: lapis)
            )
        }

        if let session = SharedStore.focusSession {
            let minutesLeft = Int((session.remaining() / 60).rounded(.up))
            let timeText = "\(name) is resting for \(minutesLeft) more minute\(minutesLeft == 1 ? "" : "s")."
            let subtitle = session.intention.map { "\(timeText)\n\nYour intention: \($0)" } ?? "\(timeText) Gather your thoughts."
            let breakText = session.canTakeBreak ? "Take a break" : nil
            return ShieldConfiguration(
                backgroundBlurStyle: blur,
                backgroundColor: paper,
                icon: UIImage(named: companion.imageName) ?? icon("building.columns.fill", lapis),
                title: .init(text: "Stay with your thoughts", color: ink),
                subtitle: .init(text: subtitle, color: subtle),
                primaryButtonLabel: .init(text: "Back to focus", color: onLapis),
                primaryButtonBackgroundColor: lapis,
                secondaryButtonLabel: breakText.map { ShieldConfiguration.Label(text: $0, color: lapis) }
            )
        }

        if let schedule = ScheduleEngine.activeSchedules().first {
            let until = schedule.endDate().map { " until \($0.formatted(date: .omitted, time: .shortened))" } ?? ""
            let title = schedule.name.isEmpty ? "Scheduled block" : schedule.name
            return ShieldConfiguration(
                backgroundBlurStyle: blur,
                backgroundColor: paper,
                icon: UIImage(named: companion.imageName) ?? icon("calendar.badge.clock", lapis),
                title: .init(text: title, color: ink),
                subtitle: .init(text: "\(name) is blocked\(until) by your schedule. This time is set aside on purpose.",
                                color: subtle),
                primaryButtonLabel: .init(text: "Back to it", color: onLapis),
                primaryButtonBackgroundColor: lapis
            )
        }

        return ShieldConfiguration(
            backgroundBlurStyle: blur,
            backgroundColor: paper,
            icon: icon("lock.fill", lapis),
            title: .init(text: "Blocked by OMO", color: ink),
            subtitle: .init(text: "Open OMO to see why.", color: subtle),
            primaryButtonLabel: .init(text: "OK", color: onLapis),
            primaryButtonBackgroundColor: lapis
        )
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
