import DeviceActivity
import SwiftUI

// Shared by the app (which embeds the report) and the ClepsyReport
// extension (which draws it), so the context names can't drift apart.

extension DeviceActivityReport.Context {
    static let productiveTime = Self("productiveTime")
}

enum ReportFormatting {
    /// "2m 40s", or "40s" under a minute
    static func duration(seconds: Int) -> String {
        let seconds = max(0, seconds)
        let minutes = seconds / 60
        let remainder = seconds % 60
        return minutes > 0 ? "\(minutes)m \(remainder)s" : "\(remainder)s"
    }
}
