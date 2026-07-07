import SwiftUI

// MARK: - App Icon View
// Used by DashboardView to render app icons for vice/productive app cards.

struct AppIconView: View {
    let bundleIdentifier: String

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(iconColor)
            .overlay {
                Image(systemName: iconSymbol)
                    .font(.title3)
                    .foregroundColor(.clepsyTextPrimary)
            }
    }

    private var iconColor: Color {
        switch bundleIdentifier {
        case "com.zhiliaoapp.musically": return .black
        case "com.burbn.instagram": return Color(red: 0.83, green: 0.18, blue: 0.55)
        case "com.atebits.Tweetie2": return .black
        case "com.reddit.Reddit": return .orange
        case "com.facebook.Facebook": return .blue
        case "com.google.ios.youtube": return .red
        case "com.toyopagroup.picaboo": return .yellow
        case "com.amazon.Lassen": return .blue
        case "com.duolingo.DuolingoMobile": return .green
        case "com.getsomeheadspace.headspace": return .orange
        case "org.khanacademy.Khan-Academy": return .green
        case "org.coursera.ios": return .blue
        default: return .gray
        }
    }

    private var iconSymbol: String {
        switch bundleIdentifier {
        case "com.zhiliaoapp.musically": return "music.note"
        case "com.burbn.instagram": return "camera"
        case "com.atebits.Tweetie2": return "at"
        case "com.reddit.Reddit": return "bubble.left.and.bubble.right"
        case "com.facebook.Facebook": return "person.2"
        case "com.google.ios.youtube": return "play.rectangle"
        case "com.toyopagroup.picaboo": return "camera.viewfinder"
        case "com.amazon.Lassen": return "book"
        case "com.duolingo.DuolingoMobile": return "globe"
        case "com.getsomeheadspace.headspace": return "brain.head.profile"
        case "org.khanacademy.Khan-Academy": return "graduationcap"
        case "org.coursera.ios": return "play.circle"
        default: return "app"
        }
    }
}
