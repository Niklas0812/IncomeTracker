import SwiftUI
import Observation

@Observable
final class DashboardViewModel {

    var selectedPeriod: TimePeriod = .monthly
    var isLoading = false

    // Filtered data
    var totalIncome: Decimal { filteredTransactions.reduce(0) { $0 + $1.amount } }
    var paysafeIncome: Decimal { filteredTransactions.filter { $0.paymentSource == .paysafe }.reduce(0) { $0 + $1.amount } }
    var paypalIncome: Decimal { filteredTransactions.filter { $0.paymentSource == .paypal }.reduce(0) { $0 + $1.amount } }

    var filteredTransactions: [Transaction] {
        let start = selectedPeriod.startDate
        return allTransactions
            .filter { $0.date >= start && $0.status == .completed }
    }

    // Previous period for % change calculation
    var previousPeriodPaysafeIncome: Decimal {
        transactionsInPreviousPeriod.filter { $0.paymentSource == .paysafe }.reduce(0) { $0 + $1.amount }
    }

    var previousPeriodPaypalIncome: Decimal {
        transactionsInPreviousPeriod.filter { $0.paymentSource == .paypal }.reduce(0) { $0 + $1.amount }
    }

    var paysafePercentChange: Double? {
        percentChange(current: paysafeIncome, previous: previousPeriodPaysafeIncome)
    }

    var paypalPercentChange: Double? {
        percentChange(current: paypalIncome, previous: previousPeriodPaypalIncome)
    }

    var recentTransactions: [Transaction] {
        Array(allTransactions.prefix(5))
    }

    var topWorkers: [Worker] {
        let workerEarnings = Dictionary(grouping: filteredTransactions, by: \.workerId)
        return allWorkers
            .map { worker in
                var w = worker
                w.totalEarnings = workerEarnings[worker.id]?.reduce(0) { $0 + $1.amount } ?? 0
                return w
            }
            .filter { $0.totalEarnings > 0 }
            .sorted { $0.totalEarnings > $1.totalEarnings }
            .prefix(5)
            .map { $0 }
    }

    // Chart data points grouped by date
    var chartDataPoints: [ChartDataPoint] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction -> String in
            chartGroupKey(for: transaction.date)
        }

        return grouped.map { key, txns in
            let paysafe = txns.filter { $0.paymentSource == .paysafe }.reduce(0) { $0 + $1.amount }
            let paypal = txns.filter { $0.paymentSource == .paypal }.reduce(0) { $0 + $1.amount }
            let date = txns.first?.date ?? .now
            return ChartDataPoint(label: key, date: date, paysafeAmount: paysafe, paypalAmount: paypal)
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Data source

    private let allTransactions = SampleData.transactions
    private let allWorkers = SampleData.workers

    // MARK: - Helpers

    private var transactionsInPreviousPeriod: [Transaction] {
        let periodStart = selectedPeriod.startDate
        let previousStart = selectedPeriod.previousPeriodStartDate
        return allTransactions.filter {
            $0.date >= previousStart && $0.date < periodStart && $0.status == .completed
        }
    }

    private func percentChange(current: Decimal, previous: Decimal) -> Double? {
        guard previous > 0 else { return nil }
        let change = ((current - previous) / previous) * 100
        return NSDecimalNumber(decimal: change).doubleValue
    }

    private func chartGroupKey(for date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .daily:
            formatter.dateFormat = "HH:00"
        case .weekly:
            formatter.dateFormat = "EEE"
        case .monthly:
            formatter.dateFormat = "d MMM"
        case .threeMonths, .sixMonths:
            formatter.dateFormat = "MMM d"
        case .oneYear:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Chart Data

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let date: Date
    let paysafeAmount: Decimal
    let paypalAmount: Decimal

    var total: Decimal { paysafeAmount + paypalAmount }
}
