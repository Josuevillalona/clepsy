import ManagedSettings
import ManagedSettingsUI
import os.log
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private static let log = Logger(subsystem: "com.clepsy.app.shieldconfiguration", category: "shield")

    private static let background = UIColor(red: 0.118, green: 0.165, blue: 0.227, alpha: 1) // #1E2A3A
    private static let gold       = UIColor(red: 0.957, green: 0.635, blue: 0.349, alpha: 1) // #F4A259
    private static let muted      = UIColor(white: 0.65, alpha: 1)

    private func makeConfiguration(appName: String? = nil) -> ShieldConfiguration {
        Self.log.info("Shield configuration requested for \(appName ?? "unknown", privacy: .public)")
        // Only UserDefaults reads here: this extension is killed by the
        // system (falling back to the default shield) if it's slow
        let storage = SharedStorageService()
        let today = DayKey.string(for: Date())
        let earn = storage.earnState.flatMap { $0.day == today ? $0 : nil }
        let content = ShieldRules.content(
            appName: appName,
            earnedMinutes: earn?.minutes ?? 0,
            goalMinutes: storage.goalMinutes(for: today),
            reached: earn?.reached ?? false
        )

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: Self.background,
            icon: UIImage(named: "shield_icon"),
            title: ShieldConfiguration.Label(text: content.title, color: .white),
            subtitle: ShieldConfiguration.Label(text: content.subtitle, color: Self.muted),
            primaryButtonLabel: ShieldConfiguration.Label(text: content.primaryButton, color: Self.background),
            primaryButtonBackgroundColor: Self.gold,
            secondaryButtonLabel: content.secondaryButton.map {
                ShieldConfiguration.Label(text: $0, color: Self.muted)
            }
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(appName: application.localizedDisplayName)
    }

    // Apps blocked via a category token route through this variant, not the
    // one above — without it iOS shows the default "Restricted" shield.
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(appName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }
}
