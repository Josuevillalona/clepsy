import SwiftUI
import FamilyControls

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showVicePicker = false
    @State private var showProductivePicker = false

    var body: some View {
        NavigationStack {
            List {
                // Section 1: Daily Goal
                Section("Daily Goal") {
                    Button {
                        viewModel.showGoalPicker = true
                    } label: {
                        HStack {
                            Label("Daily Goal", systemImage: "target")
                            Spacer()
                            Text(viewModel.formattedDailyGoal)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Section 2: Vice Apps
                Section("Vice Apps") {
                    Button {
                        showVicePicker = true
                    } label: {
                        HStack {
                            Label("Manage vice apps", systemImage: "iphone")
                            Spacer()
                            Text(viewModel.viceAppCount == 0 ? "None" : "\(viewModel.viceAppCount) selected")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Section 3: Productive Apps
                Section("Productive Apps") {
                    Button {
                        showProductivePicker = true
                    } label: {
                        HStack {
                            Label("Manage productive apps", systemImage: "checkmark.circle")
                            Spacer()
                            Text(viewModel.productiveAppCount == 0 ? "None" : "\(viewModel.productiveAppCount) selected")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Section 4: Notifications
                Section("Notifications") {
                    Toggle(isOn: $viewModel.notificationsEnabled) {
                        Label("Milestone notifications", systemImage: "bell")
                    }

                    if viewModel.notificationsEnabled {
                        Button {
                            viewModel.showIntervalPicker = true
                        } label: {
                            HStack {
                                Label("Milestone interval", systemImage: "clock")
                                Spacer()
                                Text(viewModel.formattedMilestoneInterval)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                // Section 5: Account & Data
                Section("Account & Data") {
                    Button(role: .destructive) {
                        viewModel.showResetConfirmation = true
                    } label: {
                        Label("Reset all data", systemImage: "trash")
                    }
                }

                // Section 6: About
                Section("About") {
                    NavigationLink {
                        AboutClepsyView()
                    } label: {
                        Label("How Clepsy works", systemImage: "info.circle")
                    }

                    Link(destination: URL(string: "https://clepsy.app/privacy")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Link(destination: URL(string: "https://clepsy.app/terms")!) {
                        HStack {
                            Label("Terms of Service", systemImage: "doc.plaintext")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Link(destination: URL(string: "mailto:feedback@clepsy.app")!) {
                        HStack {
                            Label("Send Feedback", systemImage: "envelope")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Footer
                Section {
                    Text("Version \(viewModel.appVersion)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showGoalPicker) {
                GoalPickerSheet(
                    selectedGoal: $viewModel.dailyGoalMinutes,
                    isPresented: $viewModel.showGoalPicker
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $viewModel.showIntervalPicker) {
                IntervalPickerSheet(
                    selectedInterval: $viewModel.milestoneInterval,
                    isPresented: $viewModel.showIntervalPicker
                )
                .presentationDetents([.medium])
            }
            .alert("Reset All Data?", isPresented: $viewModel.showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetAllData()
                }
            } message: {
                Text("This will delete all your progress, settings, and start fresh. This cannot be undone.")
            }
            .familyActivityPicker(isPresented: $showVicePicker, selection: $viewModel.viceSelection)
            .familyActivityPicker(isPresented: $showProductivePicker, selection: $viewModel.productiveSelection)
            .alert("Pick specific apps", isPresented: $viewModel.showCategoryWarning) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Whole categories aren't supported. Open a category in the picker and select individual apps — your change wasn't saved.")
            }
        }
    }
}

// MARK: - Goal Picker Sheet

struct GoalPickerSheet: View {
    @Binding var selectedGoal: Int
    @Binding var isPresented: Bool

    // Must match DailyGoalView's options — a goal picked during onboarding
    // has to remain selectable here
    private let goalOptions = [15, 30, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("How much time do you want to earn daily?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Picker("Daily Goal", selection: $selectedGoal) {
                    ForEach(goalOptions, id: \.self) { minutes in
                        Text(formatMinutes(minutes)).tag(minutes)
                    }
                }
                .pickerStyle(.wheel)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Set Daily Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else if minutes == 60 {
            return "1 hour"
        } else {
            return "\(minutes / 60) hours"
        }
    }
}

// MARK: - Interval Picker Sheet

struct IntervalPickerSheet: View {
    @Binding var selectedInterval: Int
    @Binding var isPresented: Bool

    private let intervalOptions = [0, 15, 30, 60]

    var body: some View {
        NavigationStack {
            List {
                ForEach(intervalOptions, id: \.self) { interval in
                    Button {
                        selectedInterval = interval
                        isPresented = false
                    } label: {
                        HStack {
                            Text(formatInterval(interval))
                            Spacer()
                            if selectedInterval == interval {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Milestone Interval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func formatInterval(_ minutes: Int) -> String {
        switch minutes {
        case 0: return "Off"
        case 15: return "Every 15 minutes"
        case 30: return "Every 30 minutes"
        case 60: return "Every hour"
        default: return "\(minutes) minutes"
        }
    }
}

// MARK: - About Clepsy View

struct AboutClepsyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                aboutSection(
                    icon: "clock.badge.checkmark",
                    title: "Earn Time",
                    description: "Use productive apps like Kindle, Duolingo, or Khan Academy to earn screen time."
                )

                aboutSection(
                    icon: "lock.shield",
                    title: "Apps Are Blocked",
                    description: "Vice apps like TikTok and Instagram are blocked until you earn enough time."
                )

                aboutSection(
                    icon: "lock.open",
                    title: "Unlock & Enjoy",
                    description: "Once you have enough balance, unlock your vice apps guilt-free."
                )

                aboutSection(
                    icon: "arrow.clockwise",
                    title: "Daily Reset",
                    description: "Your balance resets each day at midnight. Start fresh every morning!"
                )
            }
            .padding()
        }
        .navigationTitle("How Clepsy Works")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutSection(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}
