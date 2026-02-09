import SwiftUI

final class SettingsViewModel: ObservableObject {

    @Published var appearanceMode: AppearanceMode = .system
    @Published var transactionAlerts: Bool = true
    @Published var weeklySummary: Bool = true
    @Published var monthlyReport: Bool = false

    @Published var serverURL: String {
        didSet { APIClient.shared.baseURL = serverURL }
    }
    @Published var isServerReachable: Bool = false
    @Published var isCheckingServer: Bool = false

    let appVersion: String

    init() {
        self.serverURL = APIClient.shared.baseURL
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        checkServerHealth()
    }

    func checkServerHealth() {
        isCheckingServer = true
        Task {
            let reachable = await APIClient.shared.checkHealth()
            await MainActor.run {
                self.isServerReachable = reachable
                self.isCheckingServer = false
            }
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
