import SwiftUI
import Charts

struct IncomeChartView: View {
    let dataPoints: [ChartDataPoint]
    let period: TimePeriod

    @State private var selectedPoint: ChartDataPoint?

    private var maxY: Double {
        let maxVal = dataPoints.map { ($0.paysafeAmount + $0.paypalAmount).doubleValue }.max() ?? 0
        return maxVal * 1.15
    }

    private var xDomain: ClosedRange<Date> {
        guard let minDate = dataPoints.map(\.date).min(),
              let maxDate = dataPoints.map(\.date).max() else {
            return Date()...Date()
        }
        let calendar = Calendar.current
        switch period {
        case .threeMonths, .sixMonths, .oneYear:
            let startOfFirstMonth = calendar.dateInterval(of: .month, for: minDate)?.start ?? minDate
            let startOfLastMonth = calendar.dateInterval(of: .month, for: maxDate)?.start ?? maxDate
            let endDomain = calendar.date(byAdding: .month, value: 1, to: startOfLastMonth) ?? maxDate
            return startOfFirstMonth...endDomain
        case .weekly:
            let paddedMin = calendar.date(byAdding: .hour, value: -12, to: minDate) ?? minDate
            let paddedMax = calendar.date(byAdding: .hour, value: 23, to: maxDate) ?? maxDate
            return paddedMin...paddedMax
        case .monthly:
            let paddedMin = calendar.date(byAdding: .hour, value: -12, to: minDate) ?? minDate
            let paddedMax = calendar.date(byAdding: .hour, value: 23, to: maxDate) ?? maxDate
            return paddedMin...paddedMax
        default:
            let paddedMin = calendar.date(byAdding: chartUnit, value: -1, to: minDate) ?? minDate
            let paddedMax = calendar.date(byAdding: chartUnit, value: 1, to: maxDate) ?? maxDate
            return paddedMin...paddedMax
        }
    }

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
                        x: .value("Date", point.date, unit: chartUnit),
                        y: .value("Amount", point.paysafeAmount.doubleValue),
                        width: barWidth
                    )
                    .foregroundStyle(AppTheme.Colors.paysafe.gradient)
                    .cornerRadius(4)

                    BarMark(
                        x: .value("Date", point.date, unit: chartUnit),
                        y: .value("Amount", point.paypalAmount.doubleValue),
                        width: barWidth
                    )
                    .foregroundStyle(AppTheme.Colors.paypal.gradient)
                    .cornerRadius(4)
                }

                if let selectedPoint = selectedPoint {
                    RuleMark(x: .value("Selected", selectedPoint.date, unit: chartUnit))
                        .foregroundStyle(AppTheme.Colors.textTertiary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, spacing: 4) {
                            tooltipView(for: selectedPoint)
                        }
                }
            }
            .chartXAxis {
                if period == .threeMonths || period == .sixMonths || period == .oneYear {
                    AxisMarks(values: monthlyAxisDates) { _ in
                        AxisValueLabel(format: xAxisDateFormat)
                            .font(AppTheme.Typography.micro)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                } else if period == .weekly {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: xAxisDateFormat)
                            .font(AppTheme.Typography.micro)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                } else {
                    AxisMarks(values: .automatic(desiredCount: xAxisLabelCount)) { _ in
                        AxisValueLabel(format: xAxisDateFormat)
                            .font(AppTheme.Typography.micro)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
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
                                    if let date: Date = proxy.value(atX: xPosition) {
                                        // Find closest data point by date
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
            .chartYScale(domain: 0...max(maxY, 1))
            .chartXScale(domain: xDomain)
            .chartPlotStyle { plot in
                plot.padding(.leading, 8).padding(.trailing, 28)
            }
            .frame(height: 200)
            .id(period)
        }
        .padding(AppTheme.Spacing.md)
        .chartCardStyle()
        .transaction { t in t.animation = nil }
        .onChange(of: period) { _ in
            selectedPoint = nil
        }
    }

    private var chartUnit: Calendar.Component {
        switch period {
        case .daily: return .hour
        case .weekly: return .day
        case .monthly: return .day
        case .threeMonths: return .month
        case .sixMonths: return .month
        case .oneYear: return .month
        }
    }

    private var xAxisLabelCount: Int {
        switch period {
        case .daily: return 6
        case .weekly: return 7
        case .monthly: return 6
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 12
        }
    }

    private var barWidth: MarkDimension {
        switch period {
        case .threeMonths: return .ratio(0.5)
        case .sixMonths: return .ratio(0.6)
        case .oneYear: return .ratio(0.7)
        default: return .automatic
        }
    }

    private var monthlyAxisDates: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        for point in dataPoints {
            if let interval = calendar.dateInterval(of: .month, for: point.date) {
                let midpoint = interval.start.addingTimeInterval(interval.duration / 2)
                dates.append(midpoint)
            }
        }
        // For 1Y (>6 months), show every other label to prevent crowding
        if dates.count > 6 {
            return dates.enumerated().compactMap { index, date in
                (dates.count - 1 - index).isMultiple(of: 2) ? date : nil
            }
        }
        return dates
    }

    private var xAxisDateFormat: Date.FormatStyle {
        switch period {
        case .daily:
            return .dateTime.hour()
        case .weekly:
            return .dateTime.weekday(.abbreviated)
        case .monthly:
            return .dateTime.day().month(.abbreviated)
        case .threeMonths, .sixMonths:
            return .dateTime.month(.abbreviated)
        case .oneYear:
            return .dateTime.month(.abbreviated)
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
        IncomeChartView(
            dataPoints: [],
            period: .monthly
        )
        .padding()
    }
}
