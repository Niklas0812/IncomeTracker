import SwiftUI

// MARK: - Payment Source

enum PaymentSource: String, CaseIterable, Codable, Identifiable {
    case paysafe = "PaySafe"
    case paypal = "PayPal"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .paysafe: return AppTheme.Colors.paysafe
        case .paypal: return AppTheme.Colors.paypal
        }
    }

    var iconName: String {
        switch self {
        case .paysafe: return "creditcard.fill"
        case .paypal: return "paperplane.fill"
        }
    }
}

// MARK: - Transaction Status

enum TransactionStatus: String, CaseIterable, Codable, Identifiable {
    case completed = "Completed"
    case pending = "Pending"
    case failed = "Failed"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .completed: return AppTheme.Colors.positive
        case .pending: return AppTheme.Colors.warning
        case .failed: return AppTheme.Colors.negative
        }
    }

    var iconName: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

// MARK: - Time Period

enum TimePeriod: String, CaseIterable, Identifiable {
    case daily = "1D"
    case weekly = "1W"
    case monthly = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        }
    }

    /// Calendar component and value for date range calculation
    var dateRange: (component: Calendar.Component, value: Int) {
        switch self {
        case .daily: return (.day, 1)
        case .weekly: return (.weekOfYear, 1)
        case .monthly: return (.month, 1)
        case .threeMonths: return (.month, 3)
        case .sixMonths: return (.month, 6)
        case .oneYear: return (.year, 1)
        }
    }

    var startDate: Date {
        let cal = Calendar.current
        let (component, value) = dateRange
        return cal.date(byAdding: component, value: -value, to: .now) ?? .now
    }

    /// The start date for the previous equivalent period (for % change calculation)
    var previousPeriodStartDate: Date {
        let cal = Calendar.current
        let (component, value) = dateRange
        return cal.date(byAdding: component, value: -(value * 2), to: .now) ?? .now
    }
}

// MARK: - Sort Option for Workers

enum WorkerSortOption: String, CaseIterable, Identifiable {
    case earnings = "Earnings"
    case name = "Name"
    case dateJoined = "Date Joined"

    var id: String { rawValue }
}
