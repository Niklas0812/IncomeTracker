import SwiftUI

final class SettingsViewModel: ObservableObject {

    // Persisted via @AppStorage in the view layer
    @Published var appearanceMode: AppearanceMode = .system
    @Published var selectedCurrency: String = "EUR"
    @Published var transactionAlerts: Bool = true
    @Published var weeklySummary: Bool = true
    @Published var monthlyReport: Bool = false

    let currencies = ["EUR", "USD", "GBP", "CHF"]
    let appVersion = "1.0.0"
    let buildNumber = "42"
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
