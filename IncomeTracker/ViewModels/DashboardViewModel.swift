import SwiftUI

final class DashboardViewModel: ObservableObject {

    @Published var selectedPeriod: TimePeriod = .monthly {
        didSet {
            loadCachedData(for: selectedPeriod)
            fetchData()
        }
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
    private var fetchTask: Task<Void, Never>?

    init() {
        loadCachedData(for: selectedPeriod)
        fetchData()
    }

    deinit {
        fetchTask?.cancel()
    }

    func fetchData() {
        let requestedPeriod = selectedPeriod
        isLoading = true
        error = nil

        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            guard let self else { return }

            do {
                let response: DashboardResponse = try await self.client.request(
                    .dashboard(period: requestedPeriod.rawValue)
                )
                if Task.isCancelled { return }
                await MainActor.run {
                    guard self.selectedPeriod == requestedPeriod else { return }
                    self.apply(response: response, for: requestedPeriod, saveToCache: true)
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    guard self.selectedPeriod == requestedPeriod else { return }
                    self.error = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func loadCachedData(for period: TimePeriod) {
        guard let cached: DashboardResponse = cache.load(forKey: cacheKey(for: period)) else {
            chartDataPoints = []
            return
        }
        apply(response: cached, for: period, saveToCache: false)
    }

    private func apply(response: DashboardResponse, for period: TimePeriod, saveToCache: Bool) {
        totalIncome = Decimal(response.totalIncome)
        paysafeIncome = Decimal(response.paysafeIncome)
        paypalIncome = Decimal(response.paypalIncome)
        paysafeChange = response.paysafeChange
        paypalChange = response.paypalChange
        chartDataPoints = response.chartData.map { dto in
            ChartDataPoint(
                label: dto.label,
                date: Self.parseDate(dto.date),
                paysafeAmount: Decimal(dto.paysafe),
                paypalAmount: Decimal(dto.paypal)
            )
        }
        recentTransactions = response.recentTransactions.map { Transaction(from: $0) }
        topWorkers = response.topWorkers.map { tw in
            Worker(id: tw.workerId, name: tw.workerName, totalEarnings: Decimal(tw.total))
        }
        paysafeSparkline = response.paysafeSparkline
        paypalSparkline = response.paypalSparkline
        paysafeStatus = response.paysafeStatus
        paypalStatus = response.paypalStatus
        isLoading = false
        if saveToCache {
            cache.save(response, forKey: cacheKey(for: period))
        }
    }

    private func cacheKey(for period: TimePeriod) -> String {
        "dashboard_\(period.rawValue)"
    }

    private static func parseDate(_ str: String) -> Date {
        Date.fromAPIString(str) ?? Date()
    }
}

// MARK: - Chart Data

struct ChartDataPoint: Identifiable {
    var id: String { "\(label)-\(date.timeIntervalSince1970)" }
    let label: String
    let date: Date
    let paysafeAmount: Decimal
    let paypalAmount: Decimal

    var total: Decimal { paysafeAmount + paypalAmount }
}
