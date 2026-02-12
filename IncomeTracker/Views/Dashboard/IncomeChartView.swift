import SwiftUI
import Charts

struct IncomeChartView: View {
    let dataPoints: [ChartDataPoint]
    let period: TimePeriod

    @State private var selectedIndex: Int?
    @State private var barRevealProgress: Double = 1

    private var maxY: Double {
        let maxVal = indexedPoints.map { ($0.point.paysafeAmount + $0.point.paypalAmount).doubleValue }.max() ?? 0
        return max(maxVal * 1.15, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.md) {
                legendItem(color: AppTheme.Colors.paysafe, label: "PaySafe")
                legendItem(color: AppTheme.Colors.paypal, label: "PayPal")
            }
            .padding(.horizontal, AppTheme.Spacing.md)

            Chart {
                ForEach(indexedPoints) { item in
                    BarMark(
                        x: .value("Bucket", item.xValue),
                        y: .value("Amount", item.point.paysafeAmount.doubleValue * barRevealProgress),
                        width: barWidth
                    )
                    .position(by: .value("Source", "PaySafe"))
                    .foregroundStyle(AppTheme.Colors.paysafe.gradient)
                    .cornerRadius(4)

                    BarMark(
                        x: .value("Bucket", item.xValue),
                        y: .value("Amount", item.point.paypalAmount.doubleValue * barRevealProgress),
                        width: barWidth
                    )
                    .position(by: .value("Source", "PayPal"))
                    .foregroundStyle(AppTheme.Colors.paypal.gradient)
                    .cornerRadius(4)
                }

                if let selectedPoint = selectedPoint {
                    RuleMark(x: .value("Selected", selectedPoint.xValue))
                        .foregroundStyle(AppTheme.Colors.textTertiary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, spacing: 4) {
                            tooltipView(for: selectedPoint.point)
                        }
                }
            }
            .chartXAxis {
                if !minorTickIndices.isEmpty {
                    AxisMarks(values: minorTickValues) { _ in
                        AxisTick(length: 3)
                            .foregroundStyle(AppTheme.Colors.separator.opacity(0.35))
                    }
                }
                AxisMarks(values: majorTickValues) { value in
                    AxisTick(length: 5)
                        .foregroundStyle(AppTheme.Colors.separator.opacity(0.5))
                    AxisValueLabel {
                        if let index = indexFromAxisValue(value), indexedPoints.indices.contains(index) {
                            axisLabel(for: index)
                        }
                    }
                    if period == .oneYear {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                            .foregroundStyle(AppTheme.Colors.separator.opacity(0.25))
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
                                    let originX = geo[proxy.plotAreaFrame].origin.x
                                    let relativeX = value.location.x - originX
                                    guard relativeX >= 0, relativeX <= proxy.plotAreaSize.width else { return }
                                    if let raw: Double = proxy.value(atX: relativeX) {
                                        let bucket = Int(raw.rounded())
                                        guard indexedPoints.indices.contains(bucket) else { return }
                                        selectedIndex = bucket
                                    }
                                }
                                .onEnded { _ in
                                    selectedIndex = nil
                                }
                        )
                }
            }
            .chartYScale(domain: 0...maxY)
            .chartXScale(domain: xDomain)
            .chartXScale(range: .plotDimension(startPadding: xScalePadding, endPadding: xScalePadding))
            .frame(height: 200)
        }
        .padding(AppTheme.Spacing.md)
        .chartCardStyle()
        .onAppear {
            restartBarAnimation()
        }
        .onChange(of: dataSignature) { _ in
            restartBarAnimation()
        }
        .onChange(of: period) { _ in
            selectedIndex = nil
        }
    }

    private var majorTickIndices: [Int] {
        period.majorTickIndices(pointCount: indexedPoints.count)
    }

    private var minorTickIndices: [Int] {
        period.minorTickIndices(pointCount: indexedPoints.count)
    }

    private var majorTickValues: [Double] {
        majorTickIndices.map(Double.init)
    }

    private var minorTickValues: [Double] {
        minorTickIndices.map(Double.init)
    }

    private var barWidth: MarkDimension {
        let width: CGFloat
        switch period {
        case .daily:
            width = 4
        case .weekly:
            width = 12
        case .monthly:
            width = 3
        case .threeMonths:
            width = 24
        case .sixMonths:
            width = 18
        case .oneYear:
            width = 10
        }
        return .fixed(width)
    }

    private var xDomain: ClosedRange<Double> {
        guard !indexedPoints.isEmpty else { return -0.5...0.5 }
        return -0.5...(Double(indexedPoints.count) - 0.5)
    }

    private var xScalePadding: CGFloat {
        switch period {
        case .weekly:
            return 24
        case .threeMonths, .sixMonths:
            return 18
        case .oneYear:
            return 16
        default:
            return 12
        }
    }

    private var selectedPoint: IndexedPoint? {
        guard let selectedIndex, indexedPoints.indices.contains(selectedIndex) else { return nil }
        return indexedPoints[selectedIndex]
    }

    private var dataSignature: String {
        indexedPoints.map {
            let total = NSDecimalNumber(decimal: $0.point.total).stringValue
            return "\($0.id)-\(total)"
        }
        .joined(separator: "|")
    }

    private var indexedPoints: [IndexedPoint] {
        dataPoints
            .sorted { $0.date < $1.date }
            .enumerated()
            .map { index, point in
                IndexedPoint(index: index, point: point)
            }
    }

    private func restartBarAnimation() {
        barRevealProgress = 0.15
        withAnimation(.easeOut(duration: 0.38)) {
            barRevealProgress = 1
        }
    }

    private func indexFromAxisValue(_ value: AxisValue) -> Int? {
        if let raw = value.as(Double.self) {
            return Int(raw.rounded())
        }
        if let raw = value.as(Int.self) {
            return raw
        }
        return nil
    }

    private func axisLabel(for index: Int) -> some View {
        Text(period.chartAxisLabel(for: indexedPoints[index].point.date))
            .font(AppTheme.Typography.micro)
            .foregroundStyle(AppTheme.Colors.textTertiary)
            .fixedSize(horizontal: true, vertical: false)
            .offset(x: axisLabelOffset(for: index))
    }

    private func axisLabelOffset(for index: Int) -> CGFloat {
        if index == 0 { return 6 }
        if index == indexedPoints.count - 1 { return -8 }
        return 0
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

private struct IndexedPoint: Identifiable {
    let index: Int
    let point: ChartDataPoint

    var id: String { point.id }
    var xValue: Double { Double(index) }
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
