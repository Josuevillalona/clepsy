import Foundation
import FamilyControls

enum AppCategory: String, Codable, CaseIterable {
    case vice
    case productive

    var displayName: String {
        switch self {
        case .vice: return "Vice Apps"
        case .productive: return "Productive Apps"
        }
    }

    var isBlocked: Bool {
        switch self {
        case .vice: return true
        case .productive: return false
        }
    }

    static var defaultViceApps: [TrackedApp] {
        [
            TrackedApp(name: "TikTok", bundleIdentifier: "com.zhiliaoapp.musically", category: .vice),
            TrackedApp(name: "Instagram", bundleIdentifier: "com.burbn.instagram", category: .vice),
            TrackedApp(name: "Twitter/X", bundleIdentifier: "com.atebits.Tweetie2", category: .vice),
            TrackedApp(name: "Reddit", bundleIdentifier: "com.reddit.Reddit", category: .vice),
            TrackedApp(name: "Facebook", bundleIdentifier: "com.facebook.Facebook", category: .vice),
            TrackedApp(name: "YouTube", bundleIdentifier: "com.google.ios.youtube", category: .vice),
            TrackedApp(name: "Snapchat", bundleIdentifier: "com.toyopagroup.picaboo", category: .vice)
        ]
    }

    static var defaultProductiveApps: [TrackedApp] {
        [
            TrackedApp(name: "Kindle", bundleIdentifier: "com.amazon.Lassen", category: .productive),
            TrackedApp(name: "Duolingo", bundleIdentifier: "com.duolingo.DuolingoMobile", category: .productive),
            TrackedApp(name: "Headspace", bundleIdentifier: "com.getsomeheadspace.headspace", category: .productive),
            TrackedApp(name: "Khan Academy", bundleIdentifier: "org.khanacademy.Khan-Academy", category: .productive),
            TrackedApp(name: "Coursera", bundleIdentifier: "org.coursera.ios", category: .productive)
        ]
    }
}

struct TrackedApp: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let bundleIdentifier: String
    let category: AppCategory

    init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        category: AppCategory
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.category = category
    }
}
