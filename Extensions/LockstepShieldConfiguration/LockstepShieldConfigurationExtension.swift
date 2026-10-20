import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Draws the screen that appears when you open a blocked app.
final class LockstepShieldConfigurationExtension: ShieldConfigurationDataSource {
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
        let background = UIColor(red: 0.07, green: 0.08, blue: 0.13, alpha: 1)
        let accent = UIColor(red: 0.42, green: 0.55, blue: 1.0, alpha: 1)
        let subtle = UIColor(white: 1, alpha: 0.7)

        if let lock = SharedStore.friendLock, !lock.isOnBreak {
            return ShieldConfiguration(
                backgroundBlurStyle: .systemUltraThinMaterialDark,
                backgroundColor: background,
                icon: UIImage(systemName: "person.2.badge.key.fill"),
                title: .init(text: "\(lock.keyholderName) has your key 🔑", color: .white),
                subtitle: .init(text: "\(name) stays locked until \(lock.keyholderName) unlocks you. You can ask them for a break.",
                                color: subtle),
                primaryButtonLabel: .init(text: "Back to studying", color: .white),
                primaryButtonBackgroundColor: accent,
                secondaryButtonLabel: .init(text: "Ask for a break", color: accent)
            )
        }

        if let session = SharedStore.focusSession {
            let minutesLeft = Int((session.remaining() / 60).rounded(.up))
            let breakText = session.canTakeBreak ? "Take a break" : nil
            return ShieldConfiguration(
                backgroundBlurStyle: .systemUltraThinMaterialDark,
                backgroundColor: background,
                icon: UIImage(systemName: "moon.stars.fill"),
                title: .init(text: "Stay focused", color: .white),
                subtitle: .init(text: "\(name) is blocked for \(minutesLeft) more minute\(minutesLeft == 1 ? "" : "s"). You've got this.",
                                color: subtle),
                primaryButtonLabel: .init(text: "Back to focus", color: .white),
                primaryButtonBackgroundColor: accent,
                secondaryButtonLabel: breakText.map { ShieldConfiguration.Label(text: $0, color: accent) }
            )
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: background,
            icon: UIImage(systemName: "lock.fill"),
            title: .init(text: "Blocked by Lockstep", color: .white),
            subtitle: .init(text: "Open Lockstep to see why.", color: subtle),
            primaryButtonLabel: .init(text: "OK", color: .white),
            primaryButtonBackgroundColor: accent
        )
    }
}
