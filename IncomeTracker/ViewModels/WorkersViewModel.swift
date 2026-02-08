import SwiftUI

final class WorkersViewModel: ObservableObject {

    @Published var selectedSource: PaymentSource? = nil
    @Published var sortOption: WorkerSortOption = .earnings
    @Published var searchText: String = ""

    private let allWorkers = SampleData.workers
    let allTransactions = SampleData.transactions

    var filteredWorkers: [Worker] {
        var result = allWorkers

        if let source = selectedSource {
            result = result.filter { $0.paymentSource == source }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }

        switch sortOption {
        case .earnings:
            result.sort { $0.totalEarnings > $1.totalEarnings }
        case .name:
            result.sort { $0.name < $1.name }
        case .dateJoined:
            result.sort { $0.joinedDate > $1.joinedDate }
        }

        return result
    }

    func transactions(for worker: Worker) -> [Transaction] {
        allTransactions
            .filter { $0.workerId == worker.id }
            .sorted { $0.date > $1.date }
    }

    func earnings(for worker: Worker, in period: TimePeriod) -> Decimal {
        allTransactions
            .filter { $0.workerId == worker.id && $0.date >= period.startDate && $0.status == .completed }
            .reduce(0) { $0 + $1.amount }
    }

    func chartData(for worker: Worker, in period: TimePeriod) -> [WorkerChartPoint] {
        let txns = allTransactions
            .filter { $0.workerId == worker.id && $0.date >= period.startDate && $0.status == .completed }

        let grouped = Dictionary(grouping: txns) { $0.date.dayKey }
        return grouped.map { key, transactions in
            WorkerChartPoint(
                date: transactions.first?.date ?? .now,
                label: key,
                amount: transactions.reduce(0) { $0 + $1.amount }
            )
        }
        .sorted { $0.date < $1.date }
    }

    func stats(for worker: Worker) -> WorkerStats {
        let txns = allTransactions.filter { $0.workerId == worker.id && $0.status == .completed }
        let amounts = txns.map { $0.amount }
        let total = amounts.reduce(0, +)
        let average = amounts.isEmpty ? Decimal.zero : total / Decimal(amounts.count)
        let highest = amounts.max() ?? 0
        let lastDate = txns.first?.date

        return WorkerStats(
            averagePerTransaction: average,
            highestTransaction: highest,
            totalCount: txns.count,
            lastTransactionDate: lastDate
        )
    }
}

struct WorkerChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let amount: Decimal
}

struct WorkerStats {
    let averagePerTransaction: Decimal
    let highestTransaction: Decimal
    let totalCount: Int
    let lastTransactionDate: Date?
}
