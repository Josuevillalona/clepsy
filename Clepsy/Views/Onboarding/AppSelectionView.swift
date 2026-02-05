import SwiftUI

struct ViceAppSelectionView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var selectedApps = Set<UUID>()

    var body: some View {
        ZStack {
            Color.clepsyMidnight.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.clepsyGold)
                    }
                    Spacer()
                }
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.top, ClepsySpacing.sm)

                Text("Apps to Block")
                    .font(.clepsyLargeTitle)
                    .foregroundColor(.clepsyTextPrimary)
                    .padding(.top, ClepsySpacing.xs)

                Text("Select the apps you want Clepsy to lock")
                    .font(.clepsySubheadline)
                    .foregroundColor(.clepsyTextSecondary)
                    .padding(.top, 4)
                    .padding(.bottom, ClepsySpacing.sm)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(AppCategory.defaultViceApps) { app in
                            AppToggleRow(
                                app: app,
                                isSelected: selectedApps.contains(app.id),
                                onToggle: {
                                    if selectedApps.contains(app.id) {
                                        selectedApps.remove(app.id)
                                    } else {
                                        selectedApps.insert(app.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, ClepsySpacing.md)
                    .padding(.vertical)
                }

                Button(action: onContinue) {
                    Text("Continue")
                }
                .buttonStyle(.clepsyPrimary)
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.vertical, ClepsySpacing.sm)
            }
        }
    }
}

struct ProductiveAppSelectionView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var selectedApps = Set<UUID>()

    var body: some View {
        ZStack {
            Color.clepsyMidnight.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.clepsyGold)
                    }
                    Spacer()
                }
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.top, ClepsySpacing.sm)

                Text("Productive Apps")
                    .font(.clepsyLargeTitle)
                    .foregroundColor(.clepsyTextPrimary)
                    .padding(.top, ClepsySpacing.xs)

                Text("Earn time by using these apps")
                    .font(.clepsySubheadline)
                    .foregroundColor(.clepsyTextSecondary)
                    .padding(.top, 4)
                    .padding(.bottom, ClepsySpacing.sm)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(AppCategory.defaultProductiveApps) { app in
                            AppToggleRow(
                                app: app,
                                isSelected: selectedApps.contains(app.id),
                                onToggle: {
                                    if selectedApps.contains(app.id) {
                                        selectedApps.remove(app.id)
                                    } else {
                                        selectedApps.insert(app.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, ClepsySpacing.md)
                    .padding(.vertical)
                }

                Button(action: onContinue) {
                    Text("Continue")
                }
                .buttonStyle(.clepsyPrimary)
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.vertical, ClepsySpacing.sm)
            }
        }
    }
}

struct AppToggleRow: View {
    let app: TrackedApp
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                AppIconView(bundleIdentifier: app.bundleIdentifier)
                    .frame(width: 36, height: 36)

                Text(app.name)
                    .foregroundColor(.clepsyTextPrimary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .clepsyGold : .clepsyTextSecondary)
                    .font(.title2)
            }
            .padding()
            .background(Color.clepsySurface)
            .cornerRadius(12)
        }
    }
}

#Preview("Vice Apps") {
    ViceAppSelectionView(onContinue: {}, onBack: {})
}

#Preview("Productive Apps") {
    ProductiveAppSelectionView(onContinue: {}, onBack: {})
}
