import DeviceActivity
import SwiftUI

// Shared by the app (which embeds the report) and the ClepsyReport
// extension (which draws it), so the context names can't drift apart.

extension DeviceActivityReport.Context {
    static let productiveTime = Self("productiveTime")
}

enum ReportFormatting {
    /// "1h 35m" from an hour up, "2m 40s" under an hour, "40s" under a minute
    static func duration(seconds: Int) -> String {
        let seconds = max(0, seconds)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainder = seconds % 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return minutes > 0 ? "\(minutes)m \(remainder)s" : "\(remainder)s"
    }
}
