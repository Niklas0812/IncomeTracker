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

    var apiValue: String {
        switch self {
        case .paysafe: return "paysafe"
        case .paypal: return "paypal"
        }
    }

    init?(apiString: String) {
        switch apiString.lowercased() {
        case "paysafe": self = .paysafe
        case "paypal": self = .paypal
        default: return nil
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

    var apiValue: String {
        switch self {
        case .completed: return "completed"
        case .pending: return "pending"
        case .failed: return "failed"
        }
    }

    init?(apiString: String) {
        switch apiString.lowercased() {
        case "completed": self = .completed
        case "pending": self = .pending
        case "failed": self = .failed
        default: return nil
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

// MARK: - Chart Display Strategy

extension TimePeriod {
    var chartBarRatioSingleSeries: CGFloat {
        switch self {
        case .daily: return 0.42
        case .weekly: return 0.6
        case .monthly: return 0.72
        case .threeMonths: return 0.64
        case .sixMonths: return 0.68
        case .oneYear: return 0.78
        }
    }

    var chartBarRatioGroupedSeries: CGFloat {
        switch self {
        case .daily: return 0.48
        case .weekly: return 0.62
        case .monthly: return 0.76
        case .threeMonths: return 0.66
        case .sixMonths: return 0.68
        case .oneYear: return 0.76
        }
    }

    func majorTickIndices(pointCount: Int) -> [Int] {
        guard pointCount > 0 else { return [] }

        switch self {
        case .daily:
            return evenlySpacedTickIndices(pointCount: pointCount, target: 6)
        case .weekly:
            return Array(0..<pointCount)
        case .monthly:
            return evenlySpacedTickIndices(pointCount: pointCount, target: 6)
        case .threeMonths, .sixMonths:
            return Array(0..<pointCount)
        case .oneYear:
            return Array(0..<pointCount)
        }
    }

    func minorTickIndices(pointCount: Int) -> [Int] {
        return []
    }

    func chartAxisLabel(for date: Date) -> String {
        switch self {
        case .daily:
            return date.formatted(.dateTime.hour())
        case .weekly:
            return date.formatted(.dateTime.weekday(.abbreviated))
        case .monthly:
            return date.formatted(.dateTime.day().month(.abbreviated))
        case .threeMonths, .sixMonths:
            return date.formatted(.dateTime.month(.abbreviated))
        case .oneYear:
            return date.formatted(.dateTime.month(.narrow))
        }
    }

    private func evenlySpacedTickIndices(pointCount: Int, target: Int) -> [Int] {
        guard pointCount > 0 else { return [] }
        let safeTarget = max(1, target)
        if pointCount <= safeTarget { return Array(0..<pointCount) }

        let denominator = Double(safeTarget - 1)
        var values: [Int] = []
        var seen: Set<Int> = []

        for step in 0..<safeTarget {
            let raw = (Double(step) * Double(pointCount - 1)) / denominator
            let index = Int(round(raw))
            if seen.insert(index).inserted {
                values.append(index)
            }
        }

        if values.last != pointCount - 1 {
            values.append(pointCount - 1)
        }

        return values
    }
}

// MARK: - Sort Option for Workers

enum WorkerSortOption: String, CaseIterable, Identifiable {
    case earnings = "Earnings"
    case name = "Name"
    case dateJoined = "Date Joined"

    var id: String { rawValue }
}
