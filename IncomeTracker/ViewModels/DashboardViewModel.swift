import SwiftUI

final class DashboardViewModel: ObservableObject {

    @Published var selectedPeriod: TimePeriod = .monthly {
        didSet { fetchData() }
    }
    @Published var isLoading = false
    @Published var error: String?

    @Published var totalIncome: Decimal = 0
    @Published var paysafeIncome: Decimal = 0
    @Published var paypalIncome: Decimal = 0
    @Published var paysafePercentChange: Double?
    @Published var paypalPercentChange: Double?
    @Published var chartDataPoints: [ChartDataPoint] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var topWorkers: [Worker] = []

    private let client = APIClient.shared
    private let cache = CacheService.shared

    init() {
        loadCachedData()
        fetchData()
    }

    func fetchData() {
        isLoading = true
        error = nil

        Task {
            do {
                let response: DashboardResponse = try await client.request(
                    .dashboard(period: selectedPeriod.rawValue)
                )
                await MainActor.run {
                    self.totalIncome = Decimal(response.totalIncome)
                    self.paysafeIncome = Decimal(response.paysafeIncome)
                    self.paypalIncome = Decimal(response.paypalIncome)
                    self.paysafePercentChange = response.paysafeChange
                    self.paypalPercentChange = response.paypalChange

                    self.chartDataPoints = response.chartData.map { dto in
                        ChartDataPoint(
                            label: dto.label,
                            date: Self.parseDate(dto.date),
                            paysafeAmount: Decimal(dto.paysafe),
                            paypalAmount: Decimal(dto.paypal)
                        )
                    }

                    self.recentTransactions = response.recentTransactions.map { Transaction(from: $0) }

                    self.topWorkers = response.topWorkers.map { tw in
                        Worker(
                            id: tw.workerId,
                            name: tw.workerName,
                            totalEarnings: Decimal(tw.total)
                        )
                    }

                    self.isLoading = false
                    self.cache.save(response, forKey: "dashboard_\(self.selectedPeriod.rawValue)")
                }
            } catch {
                await MainActor.run {
                    self.error = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func loadCachedData() {
        guard let cached: DashboardResponse = cache.load(forKey: "dashboard_\(selectedPeriod.rawValue)") else { return }
        totalIncome = Decimal(cached.totalIncome)
        paysafeIncome = Decimal(cached.paysafeIncome)
        paypalIncome = Decimal(cached.paypalIncome)
        paysafePercentChange = cached.paysafeChange
        paypalPercentChange = cached.paypalChange
        chartDataPoints = cached.chartData.map { dto in
            ChartDataPoint(
                label: dto.label,
                date: Self.parseDate(dto.date),
                paysafeAmount: Decimal(dto.paysafe),
                paypalAmount: Decimal(dto.paypal)
            )
        }
        recentTransactions = cached.recentTransactions.map { Transaction(from: $0) }
        topWorkers = cached.topWorkers.map { tw in
            Worker(id: tw.workerId, name: tw.workerName, totalEarnings: Decimal(tw.total))
        }
    }

    private static func parseDate(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: str) ?? Date()
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
