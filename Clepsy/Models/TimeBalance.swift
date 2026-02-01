import Foundation

struct TimeBalance: Codable, Equatable {
    private(set) var currentSeconds: Int

    init(currentSeconds: Int = 0) {
        self.currentSeconds = max(0, currentSeconds)
    }

    mutating func add(seconds: Int) {
        currentSeconds += seconds
    }

    mutating func subtract(seconds: Int) {
        currentSeconds = max(0, currentSeconds - seconds)
    }

    var formattedTime: String {
        let hours = currentSeconds / 3600
        let minutes = (currentSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
}
