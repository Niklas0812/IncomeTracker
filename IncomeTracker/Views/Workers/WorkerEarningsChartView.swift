import SwiftUI
import Charts

struct WorkerEarningsChartView: View {
    let chartData: [WorkerChartPoint]
    let period: TimePeriod

    @State private var selectedIndex: Int?
    @State private var barRevealProgress: Double = 1

    private var maxY: Double {
        let maxVal = indexedPoints.map { $0.point.amount.doubleValue }.max() ?? 0
        return max(maxVal * 1.15, 1)
    }

    var body: some View {
        Chart(indexedPoints) { item in
            BarMark(
                x: .value("Bucket", item.xValue),
                y: .value("Amount", item.point.amount.doubleValue * barRevealProgress),
                width: barWidth
            )
            .foregroundStyle(AppTheme.Colors.primaryFallback.gradient)
            .cornerRadius(4)

            if let selected = selectedPoint {
                RuleMark(x: .value("Selected", selected.xValue))
                    .foregroundStyle(AppTheme.Colors.textTertiary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, spacing: 4) {
                        VStack(spacing: 2) {
                            Text(selected.point.amount.eurFormatted)
                                .font(AppTheme.Typography.captionBold)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text(selected.point.label)
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
                        Text(period.chartAxisLabel(for: indexedPoints[index].point.date))
                            .font(AppTheme.Typography.micro)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
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
                    if let d = value.as(Double.self) {
                        Text(Decimal(d).eurCompact)
                            .font(AppTheme.Typography.micro)
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
        .frame(height: 180)
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
        let expectedPlotWidth: CGFloat = 300
        let bucketCount = max(CGFloat(indexedPoints.count), 1)
        let estimatedBucketWidth = expectedPlotWidth / bucketCount
        let width = min(max(estimatedBucketWidth * 0.62, 3), 22)
        return .fixed(width)
    }

    private var xDomain: ClosedRange<Double> {
        guard !indexedPoints.isEmpty else { return -0.5...0.5 }
        return -0.5...(Double(indexedPoints.count) - 0.5)
    }

    private var xScalePadding: CGFloat {
        period == .oneYear ? 16 : 12
    }

    private var selectedPoint: IndexedWorkerPoint? {
        guard let selectedIndex, indexedPoints.indices.contains(selectedIndex) else { return nil }
        return indexedPoints[selectedIndex]
    }

    private var dataSignature: String {
        indexedPoints.map {
            let amount = NSDecimalNumber(decimal: $0.point.amount).stringValue
            return "\($0.id)-\(amount)"
        }
        .joined(separator: "|")
    }

    private var indexedPoints: [IndexedWorkerPoint] {
        chartData
            .sorted { $0.date < $1.date }
            .enumerated()
            .map { index, point in
                IndexedWorkerPoint(index: index, point: point)
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
}

private struct IndexedWorkerPoint: Identifiable {
    let index: Int
    let point: WorkerChartPoint

    var id: String { point.id }
    var xValue: Double { Double(index) }
}
