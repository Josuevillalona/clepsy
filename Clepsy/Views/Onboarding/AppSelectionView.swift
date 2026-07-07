import SwiftUI
import FamilyControls

struct ViceAppSelectionView: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    @Binding var selection: FamilyActivitySelection

    @State private var showingPicker = false

    private var hasSelection: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }

    // Whole categories can't be unlocked per-app, so selections must be
    // individual apps. The system picker can't hide category checkboxes,
    // so this is enforced here instead.
    private var hasCategories: Bool {
        !selection.categoryTokens.isEmpty
    }

    private var canContinue: Bool {
        !selection.applicationTokens.isEmpty && !hasCategories
    }

    private var selectionSummary: String {
        let appCount = selection.applicationTokens.count
        return "\(appCount) app\(appCount == 1 ? "" : "s")"
    }

    var body: some View {
        ZStack {
            Color.clepsyMidnight.ignoresSafeArea()

            VStack(spacing: 0) {
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

                Spacer()

                VStack(spacing: ClepsySpacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.clepsyOrange)

                    Text("Apps to Block")
                        .font(.clepsyLargeTitle)
                        .foregroundColor(.clepsyTextPrimary)

                    Text("Pick the specific apps to block. Tap a category to see the apps inside it.")
                        .font(.clepsySubheadline)
                        .foregroundColor(.clepsyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ClepsySpacing.md)

                    if hasCategories {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.clepsyOrange)
                            Text("Whole categories can't be blocked — open each category in the picker and choose individual apps instead.")
                                .font(.clepsyBody)
                                .foregroundColor(.clepsyTextPrimary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.clepsySurface)
                        .cornerRadius(12)
                        .padding(.horizontal, ClepsySpacing.md)
                    } else if hasSelection {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.clepsyTeal)
                            Text(selectionSummary + " selected")
                                .font(.clepsyBody)
                                .foregroundColor(.clepsyTextPrimary)
                        }
                        .padding()
                        .background(Color.clepsySurface)
                        .cornerRadius(12)
                        .padding(.horizontal, ClepsySpacing.md)
                    }

                    Button {
                        showingPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "apps.iphone")
                            Text(hasSelection ? "Change Selection" : "Choose Apps")
                        }
                    }
                    .buttonStyle(.clepsyPrimary)
                    .padding(.horizontal, ClepsySpacing.md)
                }

                Spacer()

                Button(action: onContinue) {
                    Text("Continue")
                }
                .buttonStyle(.clepsyPrimary)
                .disabled(!canContinue)
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.vertical, ClepsySpacing.sm)
            }
        }
        .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
    }
}

struct ProductiveAppSelectionView: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    @Binding var selection: FamilyActivitySelection

    @State private var showingPicker = false

    private var hasSelection: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }

    // Same apps-only rule as the vice picker, kept consistent so earning
    // and spending both operate on specific apps
    private var hasCategories: Bool {
        !selection.categoryTokens.isEmpty
    }

    private var canContinue: Bool {
        !selection.applicationTokens.isEmpty && !hasCategories
    }

    private var selectionSummary: String {
        let appCount = selection.applicationTokens.count
        return "\(appCount) app\(appCount == 1 ? "" : "s")"
    }

    var body: some View {
        ZStack {
            Color.clepsyMidnight.ignoresSafeArea()

            VStack(spacing: 0) {
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

                Spacer()

                VStack(spacing: ClepsySpacing.md) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.clepsyTeal)

                    Text("Productive Apps")
                        .font(.clepsyLargeTitle)
                        .foregroundColor(.clepsyTextPrimary)

                    Text("Pick the specific apps to earn time from. Tap a category to see the apps inside it.")
                        .font(.clepsySubheadline)
                        .foregroundColor(.clepsyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ClepsySpacing.md)

                    if hasCategories {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.clepsyOrange)
                            Text("Whole categories aren't supported — open each category in the picker and choose individual apps instead.")
                                .font(.clepsyBody)
                                .foregroundColor(.clepsyTextPrimary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.clepsySurface)
                        .cornerRadius(12)
                        .padding(.horizontal, ClepsySpacing.md)
                    } else if hasSelection {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.clepsyTeal)
                            Text(selectionSummary + " selected")
                                .font(.clepsyBody)
                                .foregroundColor(.clepsyTextPrimary)
                        }
                        .padding()
                        .background(Color.clepsySurface)
                        .cornerRadius(12)
                        .padding(.horizontal, ClepsySpacing.md)
                    }

                    Button {
                        showingPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "apps.iphone")
                            Text(hasSelection ? "Change Selection" : "Choose Apps")
                        }
                    }
                    .buttonStyle(.clepsyPrimary)
                    .padding(.horizontal, ClepsySpacing.md)
                }

                Spacer()

                Button(action: onContinue) {
                    Text("Continue")
                }
                .buttonStyle(.clepsyPrimary)
                .disabled(!canContinue)
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.vertical, ClepsySpacing.sm)
            }
        }
        .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
    }
}

#Preview("Vice Apps") {
    ViceAppSelectionView(
        onContinue: {},
        onBack: {},
        selection: .constant(FamilyActivitySelection())
    )
}

#Preview("Productive Apps") {
    ProductiveAppSelectionView(
        onContinue: {},
        onBack: {},
        selection: .constant(FamilyActivitySelection())
    )
}
