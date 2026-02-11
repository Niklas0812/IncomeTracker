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
        var seen = Set<String>()
        var dates: [Date] = []
        for point in chartData {
            let y = calendar.component(.year, from: point.date)
            let m = calendar.component(.month, from: point.date)
            let key = "\(y)-\(m)"
            if !seen.contains(key) {
                seen.insert(key)
                if let d = calendar.date(from: DateComponents(year: y, month: m, day: 15)) {
                    dates.append(d)
                }
            }
        }
        return dates.sorted()
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
            return .dateTime.month(.abbreviated)
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
        switch period {
        case .threeMonths, .sixMonths, .oneYear:
            let startOfFirstMonth = calendar.dateInterval(of: .month, for: minDate)?.start ?? minDate
            let startOfLastMonth = calendar.dateInterval(of: .month, for: maxDate)?.start ?? maxDate
            let endDomain = calendar.date(byAdding: .month, value: 1, to: startOfLastMonth) ?? maxDate
            return startOfFirstMonth...endDomain
        case .weekly:
            let paddedMin = calendar.date(byAdding: .hour, value: -12, to: minDate) ?? minDate
            let paddedMax = calendar.date(byAdding: .hour, value: 12, to: maxDate) ?? maxDate
            return paddedMin...paddedMax
        default:
            let paddedMin = calendar.date(byAdding: chartUnit, value: -1, to: minDate) ?? minDate
            let paddedMax = calendar.date(byAdding: chartUnit, value: 1, to: maxDate) ?? maxDate
            return paddedMin...paddedMax
        }
    }

    var body: some View {
        Chart(chartData) { point in
            BarMark(
                x: .value("Date", point.date, unit: chartUnit),
                y: .value("Amount", point.amount.doubleValue),
                width: barWidth
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
            if period == .threeMonths || period == .sixMonths || period == .oneYear {
                AxisMarks(values: monthlyAxisDates) { _ in
                    AxisValueLabel(format: xAxisFormat)
                        .font(AppTheme.Typography.micro)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            } else {
                AxisMarks(values: .automatic(desiredCount: xAxisLabelCount)) { _ in
                    AxisValueLabel(format: xAxisFormat)
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
        .chartPlotStyle { plot in
            plot.padding(.leading, 4).padding(.trailing, 24)
        }
        .frame(height: 180)
        .id(period)
        .padding(AppTheme.Spacing.md)
        .chartCardStyle()
        .animation(.easeInOut(duration: 0.2), value: period)
        .onChange(of: period) { _ in
            selectedPoint = nil
        }
    }
}
