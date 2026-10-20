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
        // Use the theme picked in OMO's settings.
        let theme = SharedStore.settings.theme
        let palette = theme.palette
        let paper = UIColor(palette.paper)
        let ink = UIColor(palette.ink)
        let subtle = ink.withAlphaComponent(0.7)
        let lapis = UIColor(palette.primary)
        let blur: UIBlurEffect.Style = theme.isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight

        if let lock = SharedStore.friendLock, !lock.isOnBreak {
            return ShieldConfiguration(
                backgroundBlurStyle: blur,
                backgroundColor: paper,
                icon: icon("person.2.badge.key.fill", lapis),
                title: .init(text: "\(lock.keyholderName) holds your key", color: ink),
                subtitle: .init(text: "\(name) stays closed until \(lock.keyholderName) unlocks you. Your circle is counting on you.",
                                color: subtle),
                primaryButtonLabel: .init(text: "Back to studying", color: .white),
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
                icon: icon("building.columns.fill", lapis),
                title: .init(text: "Stay with your thoughts", color: ink),
                subtitle: .init(text: subtitle, color: subtle),
                primaryButtonLabel: .init(text: "Back to focus", color: .white),
                primaryButtonBackgroundColor: lapis,
                secondaryButtonLabel: breakText.map { ShieldConfiguration.Label(text: $0, color: lapis) }
            )
        }

        return ShieldConfiguration(
            backgroundBlurStyle: blur,
            backgroundColor: paper,
            icon: icon("lock.fill", lapis),
            title: .init(text: "Blocked by OMO", color: ink),
            subtitle: .init(text: "Open OMO to see why.", color: subtle),
            primaryButtonLabel: .init(text: "OK", color: .white),
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
