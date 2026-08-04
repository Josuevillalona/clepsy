import ManagedSettings
import ManagedSettingsUI
import os.log
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private static let log = Logger(subsystem: "com.clepsy.app.shieldconfiguration", category: "shield")

    private static let background = UIColor(red: 0.118, green: 0.165, blue: 0.227, alpha: 1) // #1E2A3A
    private static let gold       = UIColor(red: 0.957, green: 0.635, blue: 0.349, alpha: 1) // #F4A259
    private static let muted      = UIColor(white: 0.65, alpha: 1)

    private func makeConfiguration(appName: String? = nil, token: ApplicationToken? = nil) -> ShieldConfiguration {
        Self.log.info("Shield configuration requested for \(appName ?? "unknown", privacy: .public)")
        let title = appName.map { "\($0) is blocked" } ?? "This app is blocked"

        // fastBalanceSeconds reads only UserDefaults — this extension is killed
        // by the system (falling back to the default shield) if it's slow
        let storage = SharedStorageService()
        let availableMinutes = storage.fastBalanceSeconds() / 60

        // Record which screen this app got: iOS caches shield appearances, so
        // the action extension needs this to recognize taps on a stale screen
        if let token, let tokenData = try? JSONEncoder().encode(token) {
            storage.setShieldShowedBalance(availableMinutes > 0, tokenKey: tokenData.base64EncodedString())
        }
        let subtitleText: String
        let primaryText: String
        // Shield extensions can't launch apps, so a lone "Go Back" is the only
        // honest zero-balance action; the secondary button exists only when
        // the primary does something different (unlock).
        let secondaryLabel: ShieldConfiguration.Label?

        if availableMinutes > 0 {
            subtitleText = "You have \(availableMinutes) min. It only counts down while you're in blocked apps."
            primaryText = "Use My Time"
            secondaryLabel = ShieldConfiguration.Label(text: "Go Back", color: Self.muted)
        } else {
            subtitleText = "No time available yet. Earn minutes in your productive apps, then come back."
            primaryText = "Go Back"
            secondaryLabel = nil
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: Self.background,
            icon: UIImage(named: "shield_icon"),
            title: ShieldConfiguration.Label(text: title, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitleText, color: Self.muted),
            primaryButtonLabel: ShieldConfiguration.Label(text: primaryText, color: Self.background),
            primaryButtonBackgroundColor: Self.gold,
            secondaryButtonLabel: secondaryLabel
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(appName: application.localizedDisplayName, token: application.token)
    }

    // Apps blocked via a category token route through this variant, not the
    // one above — without it iOS shows the default "Restricted" shield.
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(appName: application.localizedDisplayName, token: application.token)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }
}
