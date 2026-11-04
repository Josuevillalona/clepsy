import DeviceActivity
import SwiftUI

/// Renders Screen Time usage inside Clepsy's own screens. iOS hands this
/// extension the real usage data, but nothing can leave it — the app only
/// embeds the view, so this is display-only and never drives the balance.
@main
struct ClepsyReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        ProductiveTimeReport { totalSeconds in
            ProductiveTimeView(totalSeconds: totalSeconds)
        }
    }
}

extension DeviceActivityReport.Context {
    static let productiveTime = Self("productiveTime")
}

/// Total time today in the apps the host's filter selects (productive apps)
struct ProductiveTimeReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .productiveTime
    let content: (Int) -> ProductiveTimeView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> Int {
        // Sum per-app durations rather than the segment total: the segment
        // total can cover all device usage, not just the filtered apps
        var total: TimeInterval = 0
        for await device in data {
            for await segment in device.activitySegments {
                for await category in segment.categories {
                    for await app in category.applications {
                        total += app.totalActivityDuration
                    }
                }
            }
        }
        return Int(total)
    }
}

struct ProductiveTimeView: View {
    let totalSeconds: Int

    private var formatted: String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hourglass")
                .font(.caption)
                .foregroundColor(.clepsyTeal)
            Text("Productive apps today: \(formatted)")
                .font(.clepsyCaption)
                .foregroundColor(.clepsyTextSecondary)
            Spacer(minLength: 0)
        }
    }
}
