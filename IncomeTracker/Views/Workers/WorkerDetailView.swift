import SwiftUI
import Charts

struct WorkerDetailView: View {
    let worker: Worker
    let viewModel: WorkersViewModel

    @State private var selectedPeriod: TimePeriod = .monthly
    @State private var showEditSheet = false
    @State private var paymentBreakdown: PaymentBreakdownResponse?
    @State private var selectedChartPoint: WorkerChartPoint?

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
                paymentBreakdownSection
                statsGrid
                transactionHistory
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xxl)
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
        .onAppear {
            viewModel.fetchWorkerDetail(worker, period: selectedPeriod) { _ in }
            fetchPaymentBreakdown()
        }
        .onChange(of: selectedPeriod) { _ in
            viewModel.fetchWorkerDetail(worker, period: selectedPeriod) { _ in }
            fetchPaymentBreakdown()
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
                    .animation(AppTheme.Animation.spring, value: selectedPeriod)
            }
        }
    }

    // MARK: - Earnings Chart

    private var workerChartUnit: Calendar.Component {
        switch selectedPeriod {
        case .daily: return .hour
        case .weekly: return .day
        case .monthly: return .day
        case .threeMonths: return .weekOfYear
        case .sixMonths: return .weekOfYear
        case .oneYear: return .month
        }
    }

    private var workerXAxisFormat: Date.FormatStyle {
        switch selectedPeriod {
        case .daily:
            return .dateTime.hour()
        case .weekly:
            return .dateTime.weekday(.abbreviated)
        case .monthly:
            return .dateTime.day().month(.abbreviated)
        case .threeMonths, .sixMonths:
            return .dateTime.day().month(.abbreviated)
        case .oneYear:
            return .dateTime.month(.abbreviated)
        }
    }

    private var earningsChart: some View {
        Chart(chartData) { point in
            BarMark(
                x: .value("Date", point.date, unit: workerChartUnit),
                y: .value("Amount", point.amount.doubleValue)
            )
            .foregroundStyle(AppTheme.Colors.primaryFallback.gradient)
            .cornerRadius(4)

            if let selected = selectedChartPoint, Calendar.current.isDate(selected.date, equalTo: point.date, toGranularity: workerChartUnit) {
                RuleMark(x: .value("Selected", selected.date, unit: workerChartUnit))
                    .foregroundStyle(AppTheme.Colors.textTertiary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, spacing: 4) {
                        VStack(spacing: 2) {
                            Text(selected.amount.eurFormatted)
                                .font(AppTheme.Typography.captionBold)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text(selected.label)
                                .font(AppTheme.Typography.micro)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                        .padding(.horizontal, AppTheme.Spacing.xs)
                        .padding(.vertical, AppTheme.Spacing.xxs)
                        .background(AppTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: workerXAxisFormat)
                    .font(AppTheme.Typography.micro)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
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
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x
                                if let date: Date = proxy.value(atX: xPosition) {
                                    selectedChartPoint = chartData.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                }
                            }
                            .onEnded { _ in
                                selectedChartPoint = nil
                            }
                    )
            }
        }
        .frame(height: 180)
        .padding(AppTheme.Spacing.md)
        .cardStyle()
        .animation(AppTheme.Animation.spring, value: selectedPeriod)
    }

    // MARK: - Payment Breakdown

    private var paymentBreakdownSection: some View {
        Group {
            if let breakdown = paymentBreakdown {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Payment Breakdown")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    VStack(spacing: 0) {
                        breakdownRow(label: "Shift Pay", value: String(format: "$%.2f", breakdown.shiftPay))
                        Divider().padding(.leading, AppTheme.Spacing.md)
                        breakdownRow(label: "Bonus", value: String(format: "$%.2f", breakdown.bonus))
                        Divider().padding(.leading, AppTheme.Spacing.md)
                        breakdownRow(label: "Total Payment", value: String(format: "$%.2f", breakdown.totalPayment), bold: true)
                        Divider().padding(.leading, AppTheme.Spacing.md)
                        breakdownRow(label: "EUR Earned", value: String(format: "\u{20AC}%.2f", breakdown.totalEurEarned))
                        Divider().padding(.leading, AppTheme.Spacing.md)
                        breakdownRow(label: "Transactions", value: "\(breakdown.transactionCount)")
                    }
                    .cardStyle()
                }
            }
        }
    }

    private func breakdownRow(label: String, value: String, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? AppTheme.Typography.headline : AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(bold ? AppTheme.Typography.headline : AppTheme.Typography.callout)
                .foregroundStyle(bold ? AppTheme.Colors.positive : AppTheme.Colors.textPrimary)
        }
        .padding(AppTheme.Spacing.md)
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

    // MARK: - Helpers

    private func fetchPaymentBreakdown() {
        Task {
            do {
                let response: PaymentBreakdownResponse = try await APIClient.shared.request(
                    .workerPayment(userId: worker.id, period: selectedPeriod.rawValue)
                )
                await MainActor.run {
                    self.paymentBreakdown = response
                }
            } catch {
                // silently fail
            }
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
