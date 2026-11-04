import SwiftUI
import FamilyControls

struct SettingsView: View {
    @ObservedObject var store: GoalStore
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showVicePicker = false
    @State private var showProductivePicker = false
    @State private var showGoalSetup = false
    /// A lowered goal waiting for confirmation, since it can unlock today early
    @State private var pendingLowerGoal: (mode: GoalMode, goal: Int)?

    var body: some View {
        NavigationStack {
            List {
                // Section 1: Daily Goal
                Section {
                    Button {
                        showGoalSetup = true
                    } label: {
                        HStack {
                            Label("Daily goal", systemImage: "target")
                            Spacer()
                            Text(GoalFormatting.plan(store.plan))
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Daily Goal")
                } footer: {
                    if let pending = store.plan.pendingGoal {
                        Text("Changes to \(GoalFormatting.minutes(pending)) tomorrow. Today's goal is already done.")
                    }
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
                        Label("Notifications", systemImage: "bell")
                    }
                    Toggle(isOn: $viewModel.hapticsEnabled) {
                        Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
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
            .sheet(isPresented: $showGoalSetup) {
                NavigationStack {
                    GoalSetupView(plan: store.plan, doneTitle: "Save") { mode, goal in
                        saveGoal(mode: mode, goal: goal)
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showGoalSetup = false }
                        }
                    }
                }
                .preferredColorScheme(.dark)
            }
            .alert(
                "Lower today's goal?",
                isPresented: Binding(get: { pendingLowerGoal != nil }, set: { if !$0 { pendingLowerGoal = nil } })
            ) {
                Button("Keep \(GoalFormatting.minutes(store.todayGoal))", role: .cancel) { pendingLowerGoal = nil }
                Button("Lower it") {
                    if let pending = pendingLowerGoal { store.setPlan(mode: pending.mode, goal: pending.goal) }
                    pendingLowerGoal = nil
                }
            } message: {
                if let pending = pendingLowerGoal {
                    Text("Today's goal becomes \(GoalFormatting.minutes(pending.goal)). That's fine. It's your goal, just make sure it's what you want.")
                }
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

    /// Lowering today's (unreached) goal asks first; everything else saves
    private func saveGoal(mode: GoalMode, goal: Int) {
        showGoalSetup = false
        if !store.reachedToday && goal < store.todayGoal {
            pendingLowerGoal = (mode, goal)
        } else {
            store.setPlan(mode: mode, goal: goal)
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
                    icon: "target",
                    title: "Set a Daily Goal",
                    description: "Pick how much productive time you want each day, or build up to it a little at a time."
                )

                aboutSection(
                    icon: "lock.shield",
                    title: "Socials Start Locked",
                    description: "Vice apps like TikTok and Instagram stay locked until you hit your goal in apps like Kindle or Duolingo."
                )

                aboutSection(
                    icon: "lock.open",
                    title: "Claim Your Unlock",
                    description: "Hit your goal, open Clepsy and claim it. Your socials are yours for the rest of the day, guilt-free."
                )

                aboutSection(
                    icon: "arrow.clockwise",
                    title: "Daily Reset",
                    description: "Apps lock again at midnight. Hit your goal each day to grow your streak and earn badges."
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
    SettingsView(store: GoalStore())
}
