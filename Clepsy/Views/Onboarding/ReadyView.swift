import SwiftUI

struct ReadyView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Clepsy is ready to help you build healthier scrolling habits")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 16) {
                InfoRow(icon: "lock.fill", text: "Vice apps are now blocked")
                InfoRow(icon: "book.fill", text: "Start earning time with productive apps")
                InfoRow(icon: "clock.fill", text: "Watch your balance on the dashboard")
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onComplete) {
                Text("Go to Dashboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    ReadyView(onComplete: {})
}
