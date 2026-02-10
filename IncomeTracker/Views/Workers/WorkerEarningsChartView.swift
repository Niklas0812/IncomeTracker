import SwiftUI
import Charts

struct WorkerEarningsChartView: View {
    let chartData: [WorkerChartPoint]
    let period: TimePeriod

    @State private var selectedPoint: WorkerChartPoint?

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

    private var xAxisFormat: Date.FormatStyle {
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

    private var maxY: Double {
        let maxVal = chartData.map { $0.amount.doubleValue }.max() ?? 0
        return maxVal * 1.15
    }

    private var xDomain: ClosedRange<Date> {
        guard let minDate = chartData.map(\.date).min(),
              let maxDate = chartData.map(\.date).max() else {
            return Date()...Date()
        }
        let calendar = Calendar.current
        let paddedMin = calendar.date(byAdding: chartUnit, value: -1, to: minDate) ?? minDate
        let paddedMax = calendar.date(byAdding: chartUnit, value: 1, to: maxDate) ?? maxDate
        return paddedMin...paddedMax
    }

    var body: some View {
        Chart(chartData) { point in
            BarMark(
                x: .value("Date", point.date, unit: chartUnit),
                y: .value("Amount", point.amount.doubleValue)
            )
            .foregroundStyle(AppTheme.Colors.primaryFallback.gradient)
            .cornerRadius(4)

            if let selected = selectedPoint,
               Calendar.current.isDate(selected.date, equalTo: point.date, toGranularity: chartUnit) {
                RuleMark(x: .value("Selected", selected.date, unit: chartUnit))
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
                AxisValueLabel(format: xAxisFormat)
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
            GeometryReader { _ in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x
                                if let date: Date = proxy.value(atX: xPosition) {
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
        .chartYScale(domain: 0...max(maxY, 1))
        .chartXScale(domain: xDomain)
        .frame(height: 180)
        .padding(.top, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.md)
        .padding(.leading, AppTheme.Spacing.md)
        .padding(.trailing, 28)
        .cardStyle()
    }
}
