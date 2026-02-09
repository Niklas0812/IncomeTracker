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
    @Published var paysafeChange: PercentChangeValue = .none
    @Published var paypalChange: PercentChangeValue = .none
    @Published var chartDataPoints: [ChartDataPoint] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var topWorkers: [Worker] = []
    @Published var paysafeSparkline: [Double] = []
    @Published var paypalSparkline: [Double] = []
    @Published var paysafeStatus: String = "active"
    @Published var paypalStatus: String = "active"

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
                    self.paysafeChange = response.paysafeChange
                    self.paypalChange = response.paypalChange

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

                    self.paysafeSparkline = response.paysafeSparkline
                    self.paypalSparkline = response.paypalSparkline
                    self.paysafeStatus = response.paysafeStatus
                    self.paypalStatus = response.paypalStatus

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
        paysafeChange = cached.paysafeChange
        paypalChange = cached.paypalChange
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
        paysafeSparkline = cached.paysafeSparkline
        paypalSparkline = cached.paypalSparkline
        paysafeStatus = cached.paysafeStatus
        paypalStatus = cached.paypalStatus
    }

    private static func parseDate(_ str: String) -> Date {
        Date.fromAPIString(str) ?? Date()
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
