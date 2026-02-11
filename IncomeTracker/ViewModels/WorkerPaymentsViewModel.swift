import SwiftUI

final class WorkerPaymentsViewModel: ObservableObject {
    let userId: Int

    @Published var isLoading = false
    @Published var error: String?

    @Published var dailyPayments: [DailyPaymentDTO] = []
    @Published var dailySummary: DailyPaymentSummary?

    @Published var biweeklyPayments: [BiweeklyPaymentDTO] = []
    @Published var biweeklySummary: BiweeklySummary?

    private let client = APIClient.shared

    init(userId: Int) {
        self.userId = userId
    }

    func fetchDailyPayments(days: Int = 30) {
        isLoading = true
        error = nil

        Task {
            do {
                let response: DailyPaymentsResponse = try await client.request(
                    .workerDailyPayments(userId: userId, days: days)
                )
                await MainActor.run {
                    self.dailyPayments = response.payments
                    self.dailySummary = response.summary
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

    func fetchBiweeklyPayments(count: Int = 6) {
        isLoading = true
        error = nil

        Task {
            do {
                let response: BiweeklyPaymentsResponse = try await client.request(
                    .workerBiweeklyPayments(userId: userId, count: count)
                )
                await MainActor.run {
                    self.biweeklyPayments = response.periods
                    self.biweeklySummary = response.summary
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

    func toggleDailyPaymentStatus(_ payment: DailyPaymentDTO) {
        let newStatus = payment.paymentStatus == "paid" ? "outstanding" : "paid"

        // Optimistic update
        if let index = dailyPayments.firstIndex(where: { $0.id == payment.id }) {
            dailyPayments[index].paymentStatus = newStatus
            recalcDailySummary()
        }

        let body: [String: Any] = [
            "payment_type": "daily",
            "payment_id": payment.id,
            "status": newStatus,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }

        Task {
            do {
                let _: MarkPaidResponse = try await client.request(.markPaymentPaid(userId: userId), body: data)
            } catch {
                // Revert on failure
                await MainActor.run {
                    if let index = self.dailyPayments.firstIndex(where: { $0.id == payment.id }) {
                        self.dailyPayments[index].paymentStatus = payment.paymentStatus
                        self.recalcDailySummary()
                    }
                }
            }
        }
    }

    func toggleBiweeklyPaymentStatus(_ payment: BiweeklyPaymentDTO, cascade: Bool = true) {
        let newStatus = payment.paymentStatus == "paid" ? "outstanding" : "paid"

        // Optimistic update
        if let index = biweeklyPayments.firstIndex(where: { $0.id == payment.id }) {
            biweeklyPayments[index].paymentStatus = newStatus
            recalcBiweeklySummary()
        }

        let body: [String: Any] = [
            "payment_type": "biweekly",
            "payment_id": payment.id,
            "status": newStatus,
            "cascade": cascade,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }

        Task {
            do {
                let _: MarkPaidResponse = try await client.request(.markPaymentPaid(userId: userId), body: data)
                if cascade {
                    // Refresh daily to reflect cascaded changes
                    await MainActor.run { self.fetchDailyPayments() }
                }
            } catch {
                // Revert on failure
                await MainActor.run {
                    if let index = self.biweeklyPayments.firstIndex(where: { $0.id == payment.id }) {
                        self.biweeklyPayments[index].paymentStatus = payment.paymentStatus
                        self.recalcBiweeklySummary()
                    }
                }
            }
        }
    }

    private func recalcDailySummary() {
        let outstanding = dailyPayments.filter { $0.paymentStatus != "paid" }.reduce(0.0) { $0 + $1.totalPayment }
        let paid = dailyPayments.filter { $0.paymentStatus == "paid" }.reduce(0.0) { $0 + $1.totalPayment }
        let active = dailyPayments.filter { $0.transactionCount > 0 }.count
        dailySummary = DailyPaymentSummary(totalOutstanding: outstanding, totalPaid: paid, daysWithActivity: active)
    }

    private func recalcBiweeklySummary() {
        let outstanding = biweeklyPayments.filter { $0.paymentStatus != "paid" }.reduce(0.0) { $0 + $1.totalPayment }
        let paid = biweeklyPayments.filter { $0.paymentStatus == "paid" }.reduce(0.0) { $0 + $1.totalPayment }
        biweeklySummary = BiweeklySummary(totalOutstanding: outstanding, totalPaid: paid)
    }
}
