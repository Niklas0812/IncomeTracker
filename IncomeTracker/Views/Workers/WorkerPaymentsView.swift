import SwiftUI

struct WorkerPaymentsView: View {
    let userId: Int
    @StateObject private var vm: WorkerPaymentsViewModel

    @State private var selectedTab: PaymentTab = .daily

    enum PaymentTab: String, CaseIterable {
        case daily = "Daily"
        case biweekly = "Biweekly"
    }

    init(userId: Int) {
        self.userId = userId
        _vm = StateObject(wrappedValue: WorkerPaymentsViewModel(userId: userId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segmented picker
            Picker("View", selection: $selectedTab) {
                ForEach(PaymentTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)

            // Summary card
            summaryCard
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.sm)

            // Content
            if vm.isLoading {
                VStack(spacing: AppTheme.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading payments...")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.error {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.Colors.warning)
                    Text(error)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") { refresh() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.sm) {
                        switch selectedTab {
                        case .daily:
                            dailyContent
                        case .biweekly:
                            biweeklyContent
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .refreshable { refresh() }
            }
        }
        .background(AppTheme.Colors.backgroundPrimary)
        .navigationTitle("Payment Records")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refresh() }
        .onChange(of: selectedTab) { _ in refresh() }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            let outstanding: Double
            let paid: Double

            switch selectedTab {
            case .daily:
                outstanding = vm.dailySummary?.totalOutstanding ?? 0
                paid = vm.dailySummary?.totalPaid ?? 0
            case .biweekly:
                outstanding = vm.biweeklySummary?.totalOutstanding ?? 0
                paid = vm.biweeklySummary?.totalPaid ?? 0
            }

            summaryItem(
                title: "Outstanding",
                amount: outstanding,
                color: AppTheme.Colors.warning
            )

            summaryItem(
                title: "Paid",
                amount: paid,
                color: AppTheme.Colors.positive
            )
        }
    }

    private func summaryItem(title: String, amount: Double, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Text(title)
                .font(AppTheme.Typography.captionBold)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(String(format: "$%.2f", amount))
                .font(AppTheme.Typography.title3)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    // MARK: - Daily Content

    @ViewBuilder
    private var dailyContent: some View {
        if vm.dailyPayments.isEmpty {
            emptyState("No daily payment records")
        } else {
            ForEach(vm.dailyPayments) { payment in
                DailyPaymentRow(payment: payment) {
                    vm.toggleDailyPaymentStatus(payment)
                }
            }
        }
    }

    // MARK: - Biweekly Content

    @ViewBuilder
    private var biweeklyContent: some View {
        if vm.biweeklyPayments.isEmpty {
            emptyState("No biweekly payment records")
        } else {
            ForEach(vm.biweeklyPayments) { payment in
                BiweeklyPaymentCard(payment: payment) {
                    vm.toggleBiweeklyPaymentStatus(payment)
                }
            }
        }
    }

    // MARK: - Empty State

    private func emptyState(_ message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            Text(message)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.xxl)
    }

    // MARK: - Helpers

    private func refresh() {
        switch selectedTab {
        case .daily:
            vm.fetchDailyPayments()
        case .biweekly:
            vm.fetchBiweeklyPayments()
        }
    }
}
