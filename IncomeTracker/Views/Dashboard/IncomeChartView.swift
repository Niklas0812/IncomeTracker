import SwiftUI
import Charts

struct IncomeChartView: View {
    let dataPoints: [ChartDataPoint]
    let period: TimePeriod

    @State private var selectedPoint: ChartDataPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Legend
            HStack(spacing: AppTheme.Spacing.md) {
                legendItem(color: AppTheme.Colors.paysafe, label: "PaySafe")
                legendItem(color: AppTheme.Colors.paypal, label: "PayPal")
            }
            .padding(.horizontal, AppTheme.Spacing.md)

            // Chart
            Chart {
                ForEach(dataPoints) { point in
                    BarMark(
                        x: .value("Date", point.label),
                        y: .value("Amount", point.paysafeAmount.doubleValue)
                    )
                    .foregroundStyle(AppTheme.Colors.paysafe.gradient)
                    .cornerRadius(4)

                    BarMark(
                        x: .value("Date", point.label),
                        y: .value("Amount", point.paypalAmount.doubleValue)
                    )
                    .foregroundStyle(AppTheme.Colors.paypal.gradient)
                    .cornerRadius(4)
                }

                if let selectedPoint = selectedPoint {
                    RuleMark(x: .value("Selected", selectedPoint.label))
                        .foregroundStyle(AppTheme.Colors.textTertiary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, spacing: 4) {
                            tooltipView(for: selectedPoint)
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                    AxisValueLabel()
                        .font(AppTheme.Typography.micro)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(AppTheme.Colors.separator.opacity(0.5))
                    AxisValueLabel {
                        if let doubleVal = value.as(Double.self) {
                            Text(Decimal(doubleVal).eurCompact)
                                .font(AppTheme.Typography.micro)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
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
                                    if let label: String = proxy.value(atX: xPosition) {
                                        selectedPoint = dataPoints.first { $0.label == label }
                                    }
                                }
                                .onEnded { _ in
                                    selectedPoint = nil
                                }
                        )
                }
            }
            .frame(height: 200)
            .padding(.horizontal, AppTheme.Spacing.xs)
            .animation(AppTheme.Animation.spring, value: dataPoints.map(\.id))
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    private func tooltipView(for point: ChartDataPoint) -> some View {
        VStack(spacing: 2) {
            Text(point.total.eurFormatted)
                .font(AppTheme.Typography.captionBold)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(point.label)
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

struct IncomeChartView_Previews: PreviewProvider {
    static var previews: some View {
        IncomeChartView(
            dataPoints: [],
            period: .monthly
        )
        .padding()
    }
}
