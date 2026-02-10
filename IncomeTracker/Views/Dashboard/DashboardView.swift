import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = DashboardViewModel()
    @State private var animatedTotal: Decimal = 0
    @State private var hasAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                headerSection
                periodSelector

                if viewModel.isLoading && viewModel.totalIncome == 0 {
                    loadingPlaceholder
                } else {
                    heroIncome
                    incomeChart
                    sourceBreakdown
                    recentTransactionsSection
                    topWorkersSection
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .refreshable { viewModel.fetchData() }
        .background(AppTheme.Colors.backgroundPrimary)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if let error = viewModel.error {
                errorBanner(error)
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                animateCountUp()
            }
        }
        .onChange(of: viewModel.totalIncome) { _ in
            animateCountUp()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(Date.greetingPrefix)
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(Date.now.fullDateString)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppTheme.Spacing.md)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        PeriodSelector(selected: $viewModel.selectedPeriod)
    }

    // MARK: - Hero Income

    private var heroIncome: some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Text("Total Income")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            Text(animatedTotal.eurFormatted)
                .font(AppTheme.Typography.heroNumber)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .animation(AppTheme.Animation.spring, value: animatedTotal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
    }

    // MARK: - Income Chart

    private var incomeChart: some View {
        IncomeChartView(
            dataPoints: viewModel.chartDataPoints,
            period: viewModel.selectedPeriod
        )
    }

    // MARK: - Source Breakdown

    private var sourceBreakdown: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            SourceBreakdownCard(
                source: .paysafe,
                amount: viewModel.paysafeIncome,
                changeValue: viewModel.paysafeChange,
                sparklineData: viewModel.paysafeSparkline,
                status: viewModel.paysafeStatus
            )
            SourceBreakdownCard(
                source: .paypal,
                amount: viewModel.paypalIncome,
                changeValue: viewModel.paypalChange,
                sparklineData: viewModel.paypalSparkline,
                status: viewModel.paypalStatus
            )
        }
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Recent Transactions")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Button {
                    selectedTab = 1
                } label: {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Text("View All")
                            .font(AppTheme.Typography.callout)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.Colors.primaryFallback)
                }
            }

            if viewModel.recentTransactions.isEmpty {
                EmptyStateView(
                    iconName: "tray",
                    title: "No Transactions",
                    message: "Transactions will appear here once recorded."
                )
                .frame(height: 120)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                        if transaction.id != viewModel.recentTransactions.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(AppTheme.Spacing.sm)
                .cardStyle()
            }
        }
    }

    // MARK: - Top Workers

    private var topWorkersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Top Workers")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(viewModel.topWorkers) { worker in
                        WorkerCard(worker: worker)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }

    // MARK: - Loading / Error

    private var loadingPlaceholder: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonView()
                    .frame(height: 80)
                    .cardStyle()
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.Colors.warning)
            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            Button("Retry") { viewModel.fetchData() }
                .font(AppTheme.Typography.captionBold)
                .foregroundStyle(AppTheme.Colors.primaryFallback)
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.warning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.xs)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Animation

    private func animateCountUp() {
        let target = viewModel.totalIncome
        withAnimation(AppTheme.Animation.spring) {
            animatedTotal = target
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(selectedTab: .constant(0))
    }
}
