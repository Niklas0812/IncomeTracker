import SwiftUI

final class TransactionsViewModel: ObservableObject {

    @Published var selectedPeriod: TimePeriod = .monthly
    @Published var selectedSource: PaymentSource? = nil
    @Published var selectedStatus: TransactionStatus? = nil
    @Published var searchText: String = ""
    @Published var isLoading = false

    // All transactions from mock data
    private let allTransactions = SampleData.transactions

    var filteredTransactions: [Transaction] {
        var result = allTransactions.filter { $0.date >= selectedPeriod.startDate }

        if let source = selectedSource {
            result = result.filter { $0.paymentSource == source }
        }

        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.workerName.lowercased().contains(query) ||
                $0.reference.lowercased().contains(query)
            }
        }

        return result.sorted { $0.date > $1.date }
    }

    var totalFilteredAmount: Decimal {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    var filteredCount: Int {
        filteredTransactions.count
    }

    // Group transactions by day for section headers
    var groupedTransactions: [(key: String, header: String, transactions: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.date.dayKey }
        return grouped
            .sorted { $0.key > $1.key }
            .map { key, txns in
                let header = txns.first?.date.sectionHeader ?? key
                return (key: key, header: header, transactions: txns.sorted { $0.date > $1.date })
            }
    }

    func clearFilters() {
        selectedSource = nil
        selectedStatus = nil
        searchText = ""
    }
}
