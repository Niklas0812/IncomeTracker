import SwiftUI
import Charts

struct IncomeChartView: View {
    let dataPoints: [ChartDataPoint]
    let period: TimePeriod

    @State private var selectedPoint: ChartDataPoint?

    private var config: ChartConfiguration {
        ChartConfiguration(period: period, dates: dataPoints.map(\.date))
    }

    private var maxY: Double {
        let maxVal = dataPoints.map { ($0.paysafeAmount + $0.paypalAmount).doubleValue }.max() ?? 0
        return max(maxVal * 1.15, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.md) {
                legendItem(color: AppTheme.Colors.paysafe, label: "PaySafe")
                legendItem(color: AppTheme.Colors.paypal, label: "PayPal")
            }
            .padding(.horizontal, AppTheme.Spacing.md)

            chartContent
        }
        .padding(AppTheme.Spacing.md)
        .chartCardStyle()
        .onChange(of: period) { _ in
            selectedPoint = nil
        }
    }

    private var chartContent: some View {
        Chart {
            ForEach(dataPoints) { point in
                BarMark(
                    x: .value("Date", point.date, unit: config.chartUnit),
                    y: .value("PaySafe", point.paysafeAmount.doubleValue),
                    width: config.barWidth
                )
                .foregroundStyle(AppTheme.Colors.paysafe.gradient)

                BarMark(
                    x: .value("Date", point.date, unit: config.chartUnit),
                    y: .value("PayPal", point.paypalAmount.doubleValue),
                    width: config.barWidth
                )
                .foregroundStyle(AppTheme.Colors.paypal.gradient)
            }

            if let selectedPoint {
                RuleMark(x: .value("Selected", selectedPoint.date, unit: config.chartUnit))
                    .foregroundStyle(AppTheme.Colors.textTertiary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, spacing: 4) {
                        tooltipView(for: selectedPoint)
                    }
            }
        }
        .chartXAxis { xAxisMarks }
        .chartYAxis { yAxisMarks }
        .chartYScale(domain: 0...maxY)
        .chartXScale(domain: config.xDomain)
        .chartPlotStyle { plot in
            plot.padding(.leading, 4).padding(.trailing, 4)
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let origin = geo[proxy.plotAreaFrame].origin
                                let xPos = value.location.x - origin.x
                                if let date: Date = proxy.value(atX: xPos) {
                                    selectedPoint = dataPoints.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                }
                            }
                            .onEnded { _ in
                                selectedPoint = nil
                            }
                    )
            }
        }
        .frame(height: 200)
    }

    @AxisContentBuilder
    private var xAxisMarks: some AxisContent {
        if period == .threeMonths || period == .sixMonths || period == .oneYear {
            AxisMarks(values: config.monthlyAxisDates) { _ in
                AxisValueLabel(format: config.xAxisDateFormat)
                    .font(AppTheme.Typography.micro)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        } else if period == .weekly {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: config.xAxisDateFormat)
                    .font(AppTheme.Typography.micro)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        } else if period == .monthly {
            AxisMarks(values: config.monthlyDayAxisDates) { _ in
                AxisValueLabel(format: config.xAxisDateFormat)
                    .font(AppTheme.Typography.micro)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        } else {
            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                AxisValueLabel(format: config.xAxisDateFormat)
                    .font(AppTheme.Typography.micro)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
    }

    @AxisContentBuilder
    private var yAxisMarks: some AxisContent {
        AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                .foregroundStyle(AppTheme.Colors.separator.opacity(0.5))
            AxisValueLabel {
                if let d = value.as(Double.self) {
                    Text(Decimal(d).eurCompact)
                        .font(AppTheme.Typography.micro)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
        }
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
        IncomeChartView(dataPoints: [], period: .monthly)
            .padding()
    }
}
