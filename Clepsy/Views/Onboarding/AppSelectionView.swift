import SwiftUI

struct AppSelectionView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var selectedViceApps = Set<UUID>()
    @State private var selectedProductiveApps = Set<UUID>()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Text("Choose Your Apps")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 8)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Vice Apps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Vice Apps (to block)")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("These apps will be locked by default")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(AppCategory.defaultViceApps) { app in
                            AppToggleRow(
                                app: app,
                                isSelected: selectedViceApps.contains(app.id),
                                onToggle: {
                                    if selectedViceApps.contains(app.id) {
                                        selectedViceApps.remove(app.id)
                                    } else {
                                        selectedViceApps.insert(app.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 8)

                    // Productive Apps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Productive Apps")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Earn time by using these apps")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(AppCategory.defaultProductiveApps) { app in
                            AppToggleRow(
                                app: app,
                                isSelected: selectedProductiveApps.contains(app.id),
                                onToggle: {
                                    if selectedProductiveApps.contains(app.id) {
                                        selectedProductiveApps.remove(app.id)
                                    } else {
                                        selectedProductiveApps.insert(app.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }

            // Continue Button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
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
                Image(systemName: "app.fill")
                    .foregroundColor(.purple)

                Text(app.name)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    AppSelectionView(onContinue: {}, onBack: {})
}
