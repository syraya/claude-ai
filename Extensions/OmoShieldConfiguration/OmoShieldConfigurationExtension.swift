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
        // OMO's bright palette: washi paper, indigo ink, torii vermilion.
        let paper = UIColor(red: 0.98, green: 0.965, blue: 0.935, alpha: 1)
        let ink = UIColor(red: 0.17, green: 0.19, blue: 0.31, alpha: 1)
        let subtle = ink.withAlphaComponent(0.7)
        let vermilion = UIColor(red: 0.90, green: 0.33, blue: 0.24, alpha: 1)

        if let lock = SharedStore.friendLock, !lock.isOnBreak {
            return ShieldConfiguration(
                backgroundBlurStyle: .systemUltraThinMaterialLight,
                backgroundColor: paper,
                icon: icon("person.2.badge.key.fill", vermilion),
                title: .init(text: "\(lock.keyholderName) holds your key", color: ink),
                subtitle: .init(text: "\(name) stays closed until \(lock.keyholderName) unlocks you. Your study circle is counting on you.",
                                color: subtle),
                primaryButtonLabel: .init(text: "Back to studying", color: .white),
                primaryButtonBackgroundColor: vermilion,
                secondaryButtonLabel: .init(text: "Ask for a break", color: vermilion)
            )
        }

        if let session = SharedStore.focusSession {
            let minutesLeft = Int((session.remaining() / 60).rounded(.up))
            let timeText = "\(name) is resting for \(minutesLeft) more minute\(minutesLeft == 1 ? "" : "s")."
            let subtitle = session.intention.map { "\(timeText)\n\nYour intention: \($0)" } ?? "\(timeText) Gather your thoughts."
            let breakText = session.canTakeBreak ? "Take a break" : nil
            return ShieldConfiguration(
                backgroundBlurStyle: .systemUltraThinMaterialLight,
                backgroundColor: paper,
                icon: icon("sun.horizon.fill", vermilion),
                title: .init(text: "Stay with your thoughts", color: ink),
                subtitle: .init(text: subtitle, color: subtle),
                primaryButtonLabel: .init(text: "Back to focus", color: .white),
                primaryButtonBackgroundColor: vermilion,
                secondaryButtonLabel: breakText.map { ShieldConfiguration.Label(text: $0, color: vermilion) }
            )
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialLight,
            backgroundColor: paper,
            icon: icon("lock.fill", vermilion),
            title: .init(text: "Blocked by OMO", color: ink),
            subtitle: .init(text: "Open OMO to see why.", color: subtle),
            primaryButtonLabel: .init(text: "OK", color: .white),
            primaryButtonBackgroundColor: vermilion
        )
    }

    private func icon(_ symbol: String, _ color: UIColor) -> UIImage? {
        UIImage(systemName: symbol)?.withTintColor(color, renderingMode: .alwaysOriginal)
    }
}
