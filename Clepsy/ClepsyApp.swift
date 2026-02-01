import SwiftUI

@main
struct ClepsyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "hourglass")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Clepsy")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("MVP Setup Complete")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
