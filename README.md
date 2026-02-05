# Clepsy

A time-trading iOS app that blocks social media until you earn screen time through productive apps.

## How It Works

1. **Vice apps are blocked** — TikTok, Instagram, YouTube, etc. start locked
2. **Earn time being productive** — Use Kindle, Duolingo, Khan Academy to earn minutes
3. **Spend time on vice apps** — Unlock social media with your earned balance
4. **Daily reset at midnight** — Fresh start every day, no rollover

## Architecture

- **Pattern:** MVVM with SwiftUI
- **Target:** iOS 16+
- **Frameworks:** FamilyControls, ManagedSettings, DeviceActivity
- **Project generation:** XcodeGen (`project.yml`)

### Project Structure

```
Clepsy/
├── Models/          # TimeBalance, AppCategory, UserSettings, TimeEvent
├── Services/        # PersistenceService, ScreenTimeService, AppBlockingService,
│                      SharedStorageService, EarningSessionManager, UsageTrackingService
├── ViewModels/      # DashboardViewModel, OnboardingViewModel, SettingsViewModel
├── Views/
│   ├── Onboarding/  # WelcomeView, PermissionView, AppSelectionView, DailyGoalView
│   ├── Dashboard/   # DashboardView (main screen)
│   ├── Settings/    # SettingsView, SettingsAppSelectionView
│   ├── Shield/      # ShieldConfigurationView (blocked app screen)
│   └── Components/  # ClepsyCharacterView (animated mascot)
├── Theme/           # ClepsyTheme (colors, typography, spacing, button styles)
└── Assets.xcassets/ # Mascot assets (body levels + face expressions), app icon
ClepsyMonitor/       # DeviceActivityMonitor extension (background usage tracking)
ClepsyTests/         # Unit tests for models and services
```

## Setup

### Prerequisites

- macOS with Xcode installed
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build & Run

```bash
# Generate Xcode project
xcodegen generate

# Open in Xcode
open Clepsy.xcodeproj
```

1. Select your signing team in **Signing & Capabilities**
2. Build with **Cmd+B**
3. Run on simulator with **Cmd+R**

### Device Testing

Screen Time features (FamilyControls) require:
- A paid Apple Developer account
- Uncomment the entitlements in `project.yml` and `Clepsy/Clepsy.entitlements`
- Uncomment the ClepsyMonitor dependency in `project.yml`

## Design System

| Token | Color | Usage |
|-------|-------|-------|
| Midnight Blue | `#1E2A3A` | Background |
| Surface | `#2A3B4D` | Cards |
| Sand Gold | `#F4A259` | Accent, CTA |
| Teal | `#4ECDC4` | Success, earned |
| Orange | `#FF8C42` | Warnings, spent |
| Text Primary | `#F9F6F0` | Headlines |
| Text Secondary | `#D4CFC4` | Body text |

## Mascot (Clepsy)

The mascot uses a **decoupled layering system** — body and face are separate assets composited in a ZStack. The body shows sand level (0/25/50/75/100%) based on balance relative to daily goal. The face shows expression (patient/encouraging/celebrating) based on context.

## License

Proprietary. All rights reserved.
