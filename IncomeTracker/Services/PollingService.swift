import Foundation
import Combine

final class PollingService: ObservableObject {
    static let shared = PollingService()

    @Published var isPolling = false

    private var timer: Timer?
    private let interval: TimeInterval = 7
    private let client = APIClient.shared

    private var lastPollTimestamp: String {
        get { UserDefaults.standard.string(forKey: "lastPollTimestamp") ?? ISO8601DateFormatter().string(from: Date()) }
        set { UserDefaults.standard.set(newValue, forKey: "lastPollTimestamp") }
    }

    private init() {}

    func start() {
        guard timer == nil, !client.baseURL.isEmpty else { return }
        isPolling = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isPolling = false
    }

    private func poll() {
        let since = lastPollTimestamp
        Task {
            do {
                let response: NewTransactionsResponse = try await client.request(.newTransactions(since: since))
                if response.count > 0 {
                    for txn in response.transactions {
                        NotificationService.shared.sendTransactionNotification(
                            workerName: txn.workerName,
                            amount: txn.amount,
                            source: txn.source
                        )
                    }
                }
                await MainActor.run {
                    self.lastPollTimestamp = response.polledAt
                }
            } catch {
                // Silently fail on poll errors
            }
        }
    }
}
