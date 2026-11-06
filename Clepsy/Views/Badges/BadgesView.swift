import SwiftUI

struct BadgesView: View {
    let badges: [BadgeID: Date]
    @Environment(\.dismiss) private var dismiss
    @State private var selected: BadgeID?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: ClepsySpacing.sm), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ClepsySpacing.md) {
                    Text("\(badges.count) of \(BadgeID.allCases.count) earned")
                        .font(.clepsySubheadline)
                        .foregroundColor(.clepsyTextSecondary)

                    LazyVGrid(columns: columns, spacing: ClepsySpacing.md) {
                        ForEach(BadgeID.allCases) { badge in
                            Button {
                                HapticsService.shared.selection()
                                selected = badge
                            } label: {
                                VStack(spacing: 8) {
                                    BadgeMedallion(badge: badge, earned: badges[badge] != nil, size: 80)
                                    Text(badge.title)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(badges[badge] != nil ? .clepsyTextPrimary : .clepsyTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(ClepsySpacing.md)
            }
            .background(Color.clepsyMidnight.ignoresSafeArea())
            .navigationTitle("Badges")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selected) { badge in
                BadgeDetailView(badge: badge, earnedOn: badges[badge])
                    .presentationDetents([.medium])
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct BadgeDetailView: View {
    let badge: BadgeID
    let earnedOn: Date?

    var body: some View {
        VStack(spacing: ClepsySpacing.sm) {
            BadgeMedallion(badge: badge, earned: earnedOn != nil, size: 140, shines: true)
                .padding(.top, ClepsySpacing.lg)
            Text(badge.title)
                .font(.clepsyTitle)
                .foregroundColor(.clepsyTextPrimary)
            Text(badge.rule)
                .font(.clepsySubheadline)
                .foregroundColor(.clepsyTextSecondary)
                .multilineTextAlignment(.center)
            if let earnedOn {
                Text("Earned \(earnedOn.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.clepsyGold)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .padding(.horizontal, ClepsySpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.clepsyMidnight.ignoresSafeArea())
    }
}
