import SwiftUI
import Observation

@Observable
final class SettingsViewModel {

    // Persisted via @AppStorage in the view layer
    var appearanceMode: AppearanceMode = .system
    var selectedCurrency: String = "EUR"
    var transactionAlerts: Bool = true
    var weeklySummary: Bool = true
    var monthlyReport: Bool = false

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
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}
