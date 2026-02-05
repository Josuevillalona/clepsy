import Foundation

struct TimeEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let seconds: Int              // Time earned or spent
    let timestamp: Date           // When event occurred
    let type: EventType           // .earned or .spent
    let appBundleId: String?      // Optional: which app triggered this

    init(
        id: UUID = UUID(),
        seconds: Int,
        timestamp: Date,
        type: EventType,
        appBundleId: String? = nil
    ) {
        self.id = id
        self.seconds = seconds
        self.timestamp = timestamp
        self.type = type
        self.appBundleId = appBundleId
    }

    enum EventType: String, Codable {
        case earned
        case spent
    }
}
