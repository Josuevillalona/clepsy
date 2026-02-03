import Foundation
import FamilyControls

class ScreenTimeService: ObservableObject {
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined

    private let center = AuthorizationCenter.shared

    init() {
        updateAuthorizationStatus()
    }

    func requestAuthorization() async throws -> Bool {
        do {
            try await center.requestAuthorization(for: .individual)
            updateAuthorizationStatus()
            return authorizationStatus == .approved
        } catch {
            updateAuthorizationStatus()
            throw error
        }
    }

    private func updateAuthorizationStatus() {
        authorizationStatus = center.authorizationStatus
    }
}
