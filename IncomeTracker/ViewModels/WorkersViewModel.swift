import SwiftUI

final class WorkersViewModel: ObservableObject {

    @Published var selectedSource: PaymentSource? = nil
    @Published var sortOption: WorkerSortOption = .earnings
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var error: String?

    @Published var workers: [Worker] = []
    @Published var workerTransactions: [Int: [Transaction]] = [:]
    @Published var workerEarnings: [Int: Decimal] = [:]
    @Published var workerChartData: [Int: [WorkerChartPoint]] = [:]
    @Published var availableWorkers: [AvailableWorkerDTO] = []

    private let client = APIClient.shared

    init() {
        fetchWorkers()
    }

    var filteredWorkers: [Worker] {
        var result = workers

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

    func fetchWorkers() {
        isLoading = true
        error = nil

        Task {
            do {
                let response: WorkersResponse = try await client.request(.workers)
                await MainActor.run {
                    self.workers = response.workers.map { Worker(from: $0) }
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

    @MainActor
    func fetchWorkerDetail(_ worker: Worker, period: TimePeriod = .monthly) async throws -> WorkerDetailResponse {
        let response: WorkerDetailResponse = try await client.request(
            .workerDetail(userId: worker.id, period: period.rawValue)
        )
        let txns = response.recentTransactions.map { Transaction(from: $0) }
        self.workerTransactions[worker.id] = txns
        self.workerEarnings[worker.id] = Decimal(response.worker.totalEarnings)

        if let chartDTOs = response.chartData {
            self.workerChartData[worker.id] = chartDTOs.map { dto in
                WorkerChartPoint(
                    date: Date.fromAPIString(dto.date) ?? .now,
                    label: dto.label,
                    amount: Decimal(dto.amount)
                )
            }
        }
        return response
    }

    func fetchAvailableWorkers() {
        Task {
            do {
                let response: AvailableWorkersResponse = try await client.request(.availableWorkers)
                await MainActor.run {
                    self.availableWorkers = response.workers
                }
            } catch {
                // silently fail
            }
        }
    }

    func transactions(for worker: Worker) -> [Transaction] {
        workerTransactions[worker.id] ?? []
    }

    func earnings(for worker: Worker, in period: TimePeriod) -> Decimal {
        workerEarnings[worker.id] ?? worker.totalEarnings
    }

    func chartData(for worker: Worker, in period: TimePeriod) -> [WorkerChartPoint] {
        workerChartData[worker.id] ?? []
    }

    func stats(for worker: Worker) -> WorkerStats {
        let txns = transactions(for: worker).filter { $0.status == .completed }
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

    func createWorker(userId: Int, username: String, hourlyRate: Double, dailyHours: Double, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = [
            "user_id": userId,
            "username": username,
            "hourly_rate": hourlyRate,
            "daily_hours": dailyHours,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }

        Task {
            do {
                struct CreateResponse: Codable { let status: String }
                let _: CreateResponse = try await client.request(.createWorker, body: data)
                await MainActor.run {
                    self.fetchWorkers()
                    completion(true)
                }
            } catch {
                await MainActor.run { completion(false) }
            }
        }
    }

    func updateWorker(userId: Int, username: String, hourlyRate: Double, dailyHours: Double, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = [
            "username": username,
            "hourly_rate": hourlyRate,
            "daily_hours": dailyHours,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }

        Task {
            do {
                struct UpdateResponse: Codable { let status: String }
                let _: UpdateResponse = try await client.request(.updateWorker(userId: userId), body: data)
                await MainActor.run {
                    self.fetchWorkers()
                    completion(true)
                }
            } catch {
                await MainActor.run { completion(false) }
            }
        }
    }

    func deleteWorker(userId: Int, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                struct DeleteResponse: Codable { let status: String }
                let _: DeleteResponse = try await client.request(.deleteWorker(userId: userId))
                await MainActor.run {
                    self.workers.removeAll { $0.id == userId }
                    completion(true)
                }
            } catch {
                await MainActor.run { completion(false) }
            }
        }
    }
}

struct WorkerChartPoint: Identifiable {
    var id: String { "\(label)-\(date.timeIntervalSince1970)" }
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
