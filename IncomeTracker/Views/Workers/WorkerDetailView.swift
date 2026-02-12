import SwiftUI
import Charts

struct WorkerDetailView: View {
    let worker: Worker
    let viewModel: WorkersViewModel

    @State private var selectedPeriod: TimePeriod = .monthly
    @State private var showEditSheet = false
    @State private var isLoadingDetail = true

    private var periodEarnings: Decimal { viewModel.earnings(for: worker, in: selectedPeriod) }
    private var chartData: [WorkerChartPoint] { viewModel.chartData(for: worker, in: selectedPeriod) }
    private var stats: WorkerStats { viewModel.stats(for: worker, in: selectedPeriod) }
    private var transactions: [Transaction] { viewModel.transactions(for: worker, in: selectedPeriod) }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                headerCard
                earningsSummary
                if isLoadingDetail && chartData.isEmpty {
                    VStack(spacing: AppTheme.Spacing.md) {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .fill(AppTheme.Colors.textTertiary.opacity(0.1))
                            .frame(height: 180)
                        HStack(spacing: AppTheme.Spacing.sm) {
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .fill(AppTheme.Colors.textTertiary.opacity(0.1))
                                .frame(height: 80)
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .fill(AppTheme.Colors.textTertiary.opacity(0.1))
                                .frame(height: 80)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xs)
                } else {
                    earningsChart
                    paymentRecordsLink
                    statsGrid
                    transactionHistory
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .refreshable {
            do {
                let _ = try await viewModel.fetchWorkerDetail(worker, period: selectedPeriod)
            } catch {}
        }
        .background(AppTheme.Colors.backgroundPrimary)
        .navigationTitle(worker.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit")
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(AppTheme.Colors.primaryFallback)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditWorkerSheet(worker: worker, viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task(id: selectedPeriod) {
            isLoadingDetail = true
            do {
                let _ = try await viewModel.fetchWorkerDetail(worker, period: selectedPeriod)
            } catch {}
            isLoadingDetail = false
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            AvatarView(initials: worker.initials, color: worker.avatarColor, size: 72)

            VStack(spacing: AppTheme.Spacing.xxs) {
                Text(worker.name)
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                HStack(spacing: AppTheme.Spacing.xs) {
                    statusPill
                    if let rate = worker.hourlyRate {
                        Text("$\(String(format: "%.2f", rate))/hr")
                            .font(AppTheme.Typography.micro)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.Colors.textTertiary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            Text(worker.joinedDate.memberSinceString)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }

    private var statusPill: some View {
        Text(worker.isActive ? "Active" : "Inactive")
            .font(AppTheme.Typography.micro)
            .fontWeight(.semibold)
            .foregroundStyle(worker.isActive ? AppTheme.Colors.positive : AppTheme.Colors.textTertiary)
            .padding(.horizontal, AppTheme.Spacing.xs)
            .padding(.vertical, 3)
            .background((worker.isActive ? AppTheme.Colors.positive : AppTheme.Colors.textTertiary).opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Earnings Summary

    private var earningsSummary: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            PeriodSelector(selected: $selectedPeriod)

            VStack(spacing: AppTheme.Spacing.xxs) {
                Text("Period Earnings")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Text(periodEarnings.eurFormatted)
                    .font(AppTheme.Typography.heroNumber)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
        }
    }

    // MARK: - Earnings Chart

    private var earningsChart: some View {
        WorkerEarningsChartView(
            chartData: chartData,
            period: selectedPeriod
        )
    }

    // MARK: - Payment Records Link

    private var paymentRecordsLink: some View {
        NavigationLink {
            WorkerPaymentsView(userId: worker.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Payment Records")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("Daily & biweekly payment tracking")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AppTheme.Spacing.sm),
            GridItem(.flexible(), spacing: AppTheme.Spacing.sm)
        ], spacing: AppTheme.Spacing.sm) {
            StatCard(
                title: "Average",
                value: stats.averagePerTransaction.eurFormatted,
                subtitle: "Per transaction",
                iconName: "chart.bar.fill",
                iconColor: AppTheme.Colors.primaryFallback
            )
            StatCard(
                title: "Highest",
                value: stats.highestTransaction.eurFormatted,
                iconName: "arrow.up.circle.fill",
                iconColor: AppTheme.Colors.positive
            )
            StatCard(
                title: "Total Count",
                value: "\(stats.totalCount)",
                subtitle: "Transactions",
                iconName: "number.circle.fill",
                iconColor: AppTheme.Colors.warning
            )
            StatCard(
                title: "Last Transaction",
                value: stats.lastTransactionDate.map { "\($0.shortDateString) \($0.timeString)" } ?? "N/A",
                iconName: "calendar.circle.fill",
                iconColor: .purple
            )
        }
    }

    // MARK: - Transaction History

    private var transactionHistory: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Transaction History")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            let grouped = Dictionary(grouping: transactions) { $0.date.dayKey }
                .sorted { $0.key > $1.key }

            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(grouped, id: \.key) { key, txns in
                    let header = txns.first?.date.sectionHeader ?? key
                    VStack(alignment: .leading, spacing: 0) {
                        Text(header)
                            .font(AppTheme.Typography.captionBold)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.top, AppTheme.Spacing.sm)

                        ForEach(txns) { txn in
                            TransactionRow(transaction: txn)
                                .padding(.horizontal, AppTheme.Spacing.md)
                            if txn.id != txns.last?.id {
                                Divider().padding(.leading, 68)
                            }
                        }
                    }
                }
            }
            .cardStyle()
        }
    }

}

struct WorkerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkerDetailView(
                worker: Worker(id: 123, name: "Test Worker", totalEarnings: 1000),
                viewModel: WorkersViewModel()
            )
        }
    }
}
