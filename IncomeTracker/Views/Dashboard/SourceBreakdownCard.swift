import SwiftUI
import Charts

struct SourceBreakdownCard: View {
    let source: PaymentSource
    let amount: Decimal
    let percentChange: Double?
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header
            HStack {
                SourceBadge(source: source, style: .compact)
                Spacer()
                if let percentChange = percentChange {
                    PercentChangeLabel(value: percentChange)
                }
            }

            // Amount
            Text(amount.eurFormatted)
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            // Mini sparkline
            sparklineChart
                .frame(height: 40)
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(source.rawValue) income, \(amount.eurFormatted)")
    }

    private var sparklineChart: some View {
        let dailyAmounts = Dictionary(grouping: transactions.filter { $0.paymentSource == source }) {
            $0.date.dayKey
        }
        .map { (key: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
        .sorted { $0.key < $1.key }

        return Chart(dailyAmounts, id: \.key) { item in
            AreaMark(
                x: .value("Date", item.key),
                y: .value("Amount", item.amount.doubleValue)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [source.color.opacity(0.3), source.color.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Date", item.key),
                y: .value("Amount", item.amount.doubleValue)
            )
            .foregroundStyle(source.color)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

struct PercentChangeLabel: View {
    let value: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .bold))
            Text(String(format: "%.1f%%", abs(value)))
                .font(AppTheme.Typography.captionBold)
        }
        .foregroundStyle(value >= 0 ? AppTheme.Colors.positive : AppTheme.Colors.negative)
        .padding(.horizontal, AppTheme.Spacing.xs)
        .padding(.vertical, 3)
        .background((value >= 0 ? AppTheme.Colors.positive : AppTheme.Colors.negative).opacity(0.1))
        .clipShape(Capsule())
    }
}

struct SourceBreakdownCard_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DashboardViewModel()
        HStack(spacing: 12) {
            SourceBreakdownCard(
                source: .paysafe,
                amount: vm.paysafeIncome,
                percentChange: 12.5,
                transactions: vm.filteredTransactions
            )
            SourceBreakdownCard(
                source: .paypal,
                amount: vm.paypalIncome,
                percentChange: -3.2,
                transactions: vm.filteredTransactions
            )
        }
        .padding()
    }
}
