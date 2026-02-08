import SwiftUI
import Charts

struct WorkerDetailView: View {
    let worker: Worker
    let viewModel: WorkersViewModel

    @State private var selectedPeriod: TimePeriod = .monthly

    private var periodEarnings: Decimal { viewModel.earnings(for: worker, in: selectedPeriod) }
    private var chartData: [WorkerChartPoint] { viewModel.chartData(for: worker, in: selectedPeriod) }
    private var stats: WorkerStats { viewModel.stats(for: worker) }
    private var transactions: [Transaction] { viewModel.transactions(for: worker) }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                headerCard
                earningsSummary
                earningsChart
                statsGrid
                transactionHistory
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .background(AppTheme.Colors.backgroundPrimary)
        .navigationTitle(worker.name)
        .navigationBarTitleDisplayMode(.inline)
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
                    SourceBadge(source: worker.paymentSource, style: .pill)
                    statusPill
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
                    .contentTransition(.numericText())
                    .animation(AppTheme.Animation.spring, value: selectedPeriod)
            }
        }
    }

    // MARK: - Earnings Chart

    private var earningsChart: some View {
        Chart(chartData) { point in
            BarMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Amount", point.amount.doubleValue)
            )
            .foregroundStyle(worker.paymentSource.color.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .font(AppTheme.Typography.micro)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(AppTheme.Colors.separator.opacity(0.5))
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(Decimal(d).eurCompact)
                            .font(AppTheme.Typography.micro)
                    }
                }
            }
        }
        .frame(height: 180)
        .padding(AppTheme.Spacing.md)
        .cardStyle()
        .animation(AppTheme.Animation.spring, value: selectedPeriod)
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
                value: stats.lastTransactionDate?.shortDateString ?? "N/A",
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

            VStack(spacing: 0) {
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

#Preview {
    NavigationStack {
        WorkerDetailView(
            worker: SampleData.workers[0],
            viewModel: WorkersViewModel()
        )
    }
}
