import SwiftUI

// MARK: - Payment Source

enum PaymentSource: String, CaseIterable, Codable, Identifiable {
    case paysafe = "PaySafe"
    case paypal = "PayPal"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .paysafe: AppTheme.Colors.paysafe
        case .paypal: AppTheme.Colors.paypal
        }
    }

    var iconName: String {
        switch self {
        case .paysafe: "creditcard.fill"
        case .paypal: "paperplane.fill"
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
        case .completed: AppTheme.Colors.positive
        case .pending: AppTheme.Colors.warning
        case .failed: AppTheme.Colors.negative
        }
    }

    var iconName: String {
        switch self {
        case .completed: "checkmark.circle.fill"
        case .pending: "clock.fill"
        case .failed: "xmark.circle.fill"
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
        case .daily: "Today"
        case .weekly: "This Week"
        case .monthly: "This Month"
        case .threeMonths: "3 Months"
        case .sixMonths: "6 Months"
        case .oneYear: "1 Year"
        }
    }

    /// Calendar component and value for date range calculation
    var dateRange: (component: Calendar.Component, value: Int) {
        switch self {
        case .daily: (.day, 1)
        case .weekly: (.weekOfYear, 1)
        case .monthly: (.month, 1)
        case .threeMonths: (.month, 3)
        case .sixMonths: (.month, 6)
        case .oneYear: (.year, 1)
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
