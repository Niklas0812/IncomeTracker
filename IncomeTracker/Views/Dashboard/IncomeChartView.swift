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
        let paddedMin = calendar.date(byAdding: chartUnit, value: -1, to: minDate) ?? minDate
        let paddedMax = calendar.date(byAdding: chartUnit, value: 1, to: maxDate) ?? maxDate
        return paddedMin...paddedMax
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
                        y: .value("Amount", point.paysafeAmount.doubleValue)
                    )
                    .foregroundStyle(AppTheme.Colors.paysafe.gradient)
                    .cornerRadius(4)

                    BarMark(
                        x: .value("Date", point.date, unit: chartUnit),
                        y: .value("Amount", point.paypalAmount.doubleValue)
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
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: xAxisDateFormat)
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
                plot.padding(.trailing, 8)
            }
            .frame(height: 200)
            .padding(.horizontal, AppTheme.Spacing.xs)
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    private var chartUnit: Calendar.Component {
        switch period {
        case .daily: return .hour
        case .weekly: return .day
        case .monthly: return .day
        case .threeMonths: return .weekOfYear
        case .sixMonths: return .weekOfYear
        case .oneYear: return .month
        }
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
            return .dateTime.day().month(.abbreviated)
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
