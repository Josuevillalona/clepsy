import SwiftUI

struct SettingsAppSelectionView: View {
    let title: String
    let subtitle: String
    @Binding var apps: [SelectableApp]
    let category: AppCategory

    var body: some View {
        List {
            Section {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach($apps) { $app in
                    AppSelectionRow(app: $app)
                }
            }

            Section {
                HStack {
                    Spacer()
                    Text("\(selectedCount) of \(apps.count) selected")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Select All") {
                        selectAll()
                    }
                    Button("Deselect All") {
                        deselectAll()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var selectedCount: Int {
        apps.filter { $0.isSelected }.count
    }

    private func selectAll() {
        for index in apps.indices {
            apps[index].isSelected = true
        }
    }

    private func deselectAll() {
        for index in apps.indices {
            apps[index].isSelected = false
        }
    }
}

// MARK: - App Selection Row

struct AppSelectionRow: View {
    @Binding var app: SelectableApp

    var body: some View {
        Button {
            app.isSelected.toggle()
        } label: {
            HStack(spacing: 12) {
                // App icon placeholder
                AppIconView(bundleIdentifier: app.bundleIdentifier)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(app.bundleIdentifier)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: app.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(app.isSelected ? .accentColor : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Icon View

struct AppIconView: View {
    let bundleIdentifier: String

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(iconColor)
            .overlay {
                Image(systemName: iconSymbol)
                    .font(.title3)
                    .foregroundColor(.white)
            }
    }

    private var iconColor: Color {
        switch bundleIdentifier {
        // Vice apps
        case "com.zhiliaoapp.musically": return .black // TikTok
        case "com.burbn.instagram": return Color(red: 0.83, green: 0.18, blue: 0.55) // Instagram
        case "com.atebits.Tweetie2": return .black // Twitter/X
        case "com.reddit.Reddit": return .orange // Reddit
        case "com.facebook.Facebook": return .blue // Facebook
        case "com.google.ios.youtube": return .red // YouTube
        case "com.toyopagroup.picaboo": return .yellow // Snapchat

        // Productive apps
        case "com.amazon.Lassen": return .blue // Kindle
        case "com.duolingo.DuolingoMobile": return .green // Duolingo
        case "com.getsomeheadspace.headspace": return .orange // Headspace
        case "org.khanacademy.Khan-Academy": return .green // Khan Academy
        case "org.coursera.ios": return .blue // Coursera

        default: return .gray
        }
    }

    private var iconSymbol: String {
        switch bundleIdentifier {
        // Vice apps
        case "com.zhiliaoapp.musically": return "music.note"
        case "com.burbn.instagram": return "camera"
        case "com.atebits.Tweetie2": return "at"
        case "com.reddit.Reddit": return "bubble.left.and.bubble.right"
        case "com.facebook.Facebook": return "person.2"
        case "com.google.ios.youtube": return "play.rectangle"
        case "com.toyopagroup.picaboo": return "camera.viewfinder"

        // Productive apps
        case "com.amazon.Lassen": return "book"
        case "com.duolingo.DuolingoMobile": return "globe"
        case "com.getsomeheadspace.headspace": return "brain.head.profile"
        case "org.khanacademy.Khan-Academy": return "graduationcap"
        case "org.coursera.ios": return "play.circle"

        default: return "app"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsAppSelectionView(
            title: "Vice Apps",
            subtitle: "Select apps you want to block",
            apps: .constant([
                SelectableApp(
                    trackedApp: TrackedApp(name: "TikTok", bundleIdentifier: "com.zhiliaoapp.musically", category: .vice),
                    isSelected: true
                ),
                SelectableApp(
                    trackedApp: TrackedApp(name: "Instagram", bundleIdentifier: "com.burbn.instagram", category: .vice),
                    isSelected: false
                )
            ]),
            category: .vice
        )
    }
}
