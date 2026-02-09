import SwiftUI
import Charts

struct SourceBreakdownCard: View {
    let source: PaymentSource
    let amount: Decimal
    let changeValue: PercentChangeValue
    let sparklineData: [Double]
    let status: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header
            HStack {
                Text(source == .paysafe ? "PaySafe" : "PayPal")
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(source.color)
                Spacer()
                changeLabel
            }

            // Amount
            Text(amount.eurFormatted)
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            // Mini sparkline
            if status == "no_activity" {
                Text("No activity")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                sparklineChart
                    .frame(height: 40)
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(source.rawValue) income, \(amount.eurFormatted)")
    }

    @ViewBuilder
    private var changeLabel: some View {
        switch changeValue {
        case .number(let value):
            PercentChangeLabel(value: value)
        case .noActivity:
            Text("No activity")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, 3)
                .background(AppTheme.Colors.textTertiary.opacity(0.1))
                .clipShape(Capsule())
        case .none:
            EmptyView()
        }
    }

    private var sparklineChart: some View {
        let indexed = sparklineData.enumerated().map { (index: $0.offset, amount: $0.element) }

        return Chart(indexed, id: \.index) { item in
            AreaMark(
                x: .value("Day", item.index),
                y: .value("Amount", item.amount)
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
                x: .value("Day", item.index),
                y: .value("Amount", item.amount)
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
        HStack(spacing: 12) {
            SourceBreakdownCard(
                source: .paysafe,
                amount: 5000,
                changeValue: .number(12.5),
                sparklineData: [10, 20, 15, 30, 25, 40, 35],
                status: "active"
            )
            SourceBreakdownCard(
                source: .paypal,
                amount: 3000,
                changeValue: .noActivity,
                sparklineData: [],
                status: "no_activity"
            )
        }
        .padding()
    }
}
