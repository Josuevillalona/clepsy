import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Clepsy Character
                    ClepsyCharacterView(
                        balancePercentage: min(viewModel.balancePercentage, 1.0),
                        expression: expressionForBalance
                    )
                    .padding(.top, 20)

                    // Current Balance Card
                    VStack(spacing: 8) {
                        Text("Current Balance")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(viewModel.formattedBalance)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.purple)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Today's Activity
                    HStack(spacing: 16) {
                        ActivityCard(
                            title: "Earned",
                            value: formatSeconds(viewModel.todayEarned),
                            icon: "arrow.up.circle.fill",
                            color: .green
                        )

                        ActivityCard(
                            title: "Spent",
                            value: formatSeconds(viewModel.todaySpent),
                            icon: "arrow.down.circle.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Quick Actions (placeholder for MVP)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)

                        Button(action: {
                            // Test: Add 5 minutes
                            viewModel.addTime(seconds: 300)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add 5 minutes (test)")
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Button(action: {
                            // Test: Subtract 2 minutes
                            viewModel.subtractTime(seconds: 120)
                        }) {
                            HStack {
                                Image(systemName: "minus.circle.fill")
                                Text("Subtract 2 minutes (test)")
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: Text("Settings")) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            viewModel.checkAndPerformDailyReset()
        }
    }

    private var expressionForBalance: ClepsyExpression {
        if viewModel.balancePercentage > 0.6 {
            return .celebrating
        } else if viewModel.balancePercentage > 0.2 {
            return .encouraging
        } else {
            return .patient
        }
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes)m"
    }
}

struct ActivityCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
}
