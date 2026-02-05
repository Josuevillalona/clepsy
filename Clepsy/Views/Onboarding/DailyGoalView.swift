import SwiftUI

struct DailyGoalView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var selectedMinutes: Int = 30

    private let goalOptions = [15, 30, 45, 60, 90, 120]

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

                Spacer()

                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(.clepsyGold)
                    .padding(.bottom, ClepsySpacing.sm)

                Text("Set Your Daily Goal")
                    .font(.clepsyLargeTitle)
                    .foregroundColor(.clepsyTextPrimary)

                Text("How much productive time do you want to earn each day?")
                    .font(.clepsySubheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.clepsyTextSecondary)
                    .padding(.horizontal, ClepsySpacing.md)
                    .padding(.top, 4)

                // Goal display
                Text(formattedGoal)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.clepsyGold)
                    .padding(.top, ClepsySpacing.md)

                // Goal picker
                VStack(spacing: 10) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(goalOptions, id: \.self) { minutes in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedMinutes = minutes
                                }
                            } label: {
                                Text(labelForMinutes(minutes))
                                    .font(.clepsyHeadline)
                                    .foregroundColor(selectedMinutes == minutes ? .clepsyMidnight : .clepsyTextPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(selectedMinutes == minutes ? Color.clepsyGold : Color.clepsySurface)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.top, ClepsySpacing.md)

                Text("You can change this later in Settings")
                    .font(.clepsyCaption)
                    .foregroundColor(.clepsyTextSecondary)
                    .padding(.top, ClepsySpacing.sm)

                Spacer()

                Button {
                    saveGoal()
                    onContinue()
                } label: {
                    Text("Continue")
                }
                .buttonStyle(.clepsyPrimary)
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.bottom, ClepsySpacing.lg)
            }
        }
    }

    private var formattedGoal: String {
        if selectedMinutes < 60 {
            return "\(selectedMinutes) min"
        } else if selectedMinutes == 60 {
            return "1 hour"
        } else {
            let hours = selectedMinutes / 60
            let mins = selectedMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours) hours"
        }
    }

    private func labelForMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else if minutes == 60 {
            return "1 hour"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours) hrs"
        }
    }

    private func saveGoal() {
        let persistence = PersistenceService()
        var settings = persistence.loadUserSettings()
        settings.dailyGoalMinutes = selectedMinutes
        persistence.saveUserSettings(settings)
    }
}

#Preview {
    DailyGoalView(onContinue: {}, onBack: {})
}
