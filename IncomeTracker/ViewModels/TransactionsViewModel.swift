import SwiftUI
import Combine

final class TransactionsViewModel: ObservableObject {

    @Published var selectedPeriod: TimePeriod = .monthly
    @Published var selectedSource: PaymentSource? = nil
    @Published var selectedStatus: TransactionStatus? = nil
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var error: String?

    @Published var transactions: [Transaction] = []
    @Published var page: Int = 1
    @Published var totalPages: Int = 1
    @Published var totalCount: Int = 0
    @Published var totalFilteredAmount: Decimal = 0

    private let client = APIClient.shared
    private var searchDebounce: AnyCancellable?

    init() {
        searchDebounce = $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.page = 1
                self?.fetchData()
            }

        // Refetch when filters change
        Publishers.CombineLatest3($selectedPeriod, $selectedSource, $selectedStatus)
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.page = 1
                self?.fetchData()
            }
            .store(in: &cancellables)

        fetchData()
    }

    private var cancellables = Set<AnyCancellable>()

    var filteredCount: Int { totalCount }

    var groupedTransactions: [(key: String, header: String, transactions: [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { $0.date.dayKey }
        return grouped
            .sorted { $0.key > $1.key }
            .map { key, txns in
                let header = txns.first?.date.sectionHeader ?? key
                return (key: key, header: header, transactions: txns.sorted { $0.date > $1.date })
            }
    }

    func fetchData() {
        isLoading = true
        error = nil

        Task {
            do {
                let response: TransactionsResponse = try await client.request(
                    .transactions(
                        period: selectedPeriod.rawValue,
                        source: selectedSource?.apiValue,
                        status: selectedStatus?.apiValue,
                        search: searchText.isEmpty ? nil : searchText,
                        page: page
                    )
                )
                await MainActor.run {
                    if self.page == 1 {
                        self.transactions = response.transactions.map { Transaction(from: $0) }
                    } else {
                        self.transactions.append(contentsOf: response.transactions.map { Transaction(from: $0) })
                    }
                    self.totalPages = response.totalPages
                    self.totalCount = response.totalCount
                    self.totalFilteredAmount = Decimal(response.totalAmount)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func loadMore() {
        guard page < totalPages, !isLoading else { return }
        page += 1
        fetchData()
    }

    func clearFilters() {
        selectedSource = nil
        selectedStatus = nil
        searchText = ""
    }
}
