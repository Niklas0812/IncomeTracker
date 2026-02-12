import SwiftUI
import Charts

struct WorkerEarningsChartView: View {
    let chartData: [WorkerChartPoint]
    let period: TimePeriod

    @State private var selectedPoint: WorkerChartPoint?

    private var config: ChartConfiguration {
        ChartConfiguration(period: period, dates: chartData.map(\.date))
    }

    private var maxY: Double {
        let maxVal = chartData.map { $0.amount.doubleValue }.max() ?? 0
        return max(maxVal * 1.15, 1)
    }

    var body: some View {
        chartContent
            .padding(AppTheme.Spacing.md)
            .chartCardStyle()
            .onChange(of: period) { _ in
                selectedPoint = nil
            }
    }

    private var chartContent: some View {
        Chart(chartData) { point in
            BarMark(
                x: .value("Date", point.date, unit: config.chartUnit),
                y: .value("Amount", point.amount.doubleValue),
                width: config.barWidth
            )
            .foregroundStyle(AppTheme.Colors.primaryFallback.gradient)

            if let selected = selectedPoint,
               Calendar.current.isDate(selected.date, equalTo: point.date, toGranularity: config.chartUnit) {
                RuleMark(x: .value("Selected", selected.date, unit: config.chartUnit))
                    .foregroundStyle(AppTheme.Colors.textTertiary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, spacing: 4) {
                        tooltipView(for: selected)
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
                                    selectedPoint = chartData.min(by: {
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
        .frame(height: 180)
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

    private func tooltipView(for point: WorkerChartPoint) -> some View {
        VStack(spacing: 2) {
            Text(point.amount.eurFormatted)
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
