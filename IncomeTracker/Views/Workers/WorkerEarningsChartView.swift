import SwiftUI
import Charts

struct WorkerEarningsChartView: View {
    let chartData: [WorkerChartPoint]
    let period: TimePeriod

    @State private var renderedPoints: [IndexedWorkerPoint] = []
    @State private var selectedIndex: Int?
    @State private var chartOpacity: Double = 1
    @State private var chartScaleY: CGFloat = 1
    @State private var transitionToken: Int = 0

    private var selectedPoint: IndexedWorkerPoint? {
        guard let selectedIndex, renderedPoints.indices.contains(selectedIndex) else { return nil }
        return renderedPoints[selectedIndex]
    }

    private var maxY: Double {
        let maxValue = renderedPoints.map { $0.amount.doubleValue }.max() ?? 0
        return max(maxValue * 1.15, 1)
    }

    private var xDomain: ClosedRange<Double> {
        let upper = max(Double(renderedPoints.count) - 0.5, 0.5)
        return -0.5...upper
    }

    private var majorTickValues: [Double] {
        period.majorTickIndices(pointCount: renderedPoints.count).map(Double.init)
    }

    private var minorTickValues: [Double] {
        period.minorTickIndices(pointCount: renderedPoints.count).map(Double.init)
    }

    private var barWidth: MarkDimension {
        .ratio(period.chartBarRatioSingleSeries)
    }

    private var dataRevision: [String] {
        chartData.map { "\($0.id)-\($0.amount)" }
    }

    var body: some View {
        Chart {
            ForEach(renderedPoints) { point in
                BarMark(
                    x: .value("Bucket", point.x),
                    y: .value("Amount", point.amount.doubleValue),
                    width: barWidth
                )
                .foregroundStyle(AppTheme.Colors.primaryFallback.gradient)
                .cornerRadius(4)
            }

            if let selectedPoint {
                RuleMark(x: .value("Selected", selectedPoint.x))
                    .foregroundStyle(AppTheme.Colors.textTertiary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, spacing: 6) {
                        tooltipView(for: selectedPoint)
                    }
            }
        }
        .chartXAxis {
            if period == .oneYear && !minorTickValues.isEmpty {
                AxisMarks(values: minorTickValues) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.4))
                        .foregroundStyle(AppTheme.Colors.separator.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(AppTheme.Colors.separator.opacity(0.35))
                }
            }

            AxisMarks(values: majorTickValues) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6))
                    .foregroundStyle(AppTheme.Colors.separator.opacity(period == .oneYear ? 0.35 : 0.25))
                AxisTick()
                    .foregroundStyle(AppTheme.Colors.separator.opacity(0.4))
                AxisValueLabel {
                    if let label = axisLabel(for: value) {
                        Text(label)
                            .font(AppTheme.Typography.micro)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(AppTheme.Colors.separator.opacity(0.45))
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(Decimal(d).eurCompact)
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
                                guard !renderedPoints.isEmpty else {
                                    selectedIndex = nil
                                    return
                                }
                                let plotFrame = geo[proxy.plotAreaFrame]
                                let xPosition = value.location.x - plotFrame.origin.x
                                guard xPosition >= 0, xPosition <= plotFrame.width else {
                                    selectedIndex = nil
                                    return
                                }
                                guard let rawX: Double = proxy.value(atX: xPosition) else {
                                    selectedIndex = nil
                                    return
                                }
                                let clamped = min(max(Int(round(rawX)), 0), renderedPoints.count - 1)
                                selectedIndex = clamped
                            }
                            .onEnded { _ in
                                selectedIndex = nil
                            }
                    )
            }
        }
        .chartYScale(domain: 0...maxY)
        .chartXScale(domain: xDomain)
        .chartPlotStyle { plot in
            plot
                .padding(.leading, AppTheme.Spacing.xs)
                .padding(.trailing, AppTheme.Spacing.xs)
        }
        .frame(height: 180)
        .opacity(chartOpacity)
        .scaleEffect(x: 1, y: chartScaleY, anchor: .bottom)
        .padding(AppTheme.Spacing.md)
        .chartCardStyle()
        .onAppear {
            if renderedPoints.isEmpty {
                renderedPoints = indexData(chartData)
            } else {
                updateRenderedData(animated: false)
            }
        }
        .onChange(of: period) { _ in
            selectedIndex = nil
            updateRenderedData(animated: true)
        }
        .onChange(of: dataRevision) { _ in
            updateRenderedData(animated: true)
        }
    }

    private func indexData(_ points: [WorkerChartPoint]) -> [IndexedWorkerPoint] {
        points
            .sorted { $0.date < $1.date }
            .enumerated()
            .map { idx, point in
                IndexedWorkerPoint(index: idx, date: point.date, label: point.label, amount: point.amount)
            }
    }

    private func updateRenderedData(animated: Bool) {
        let next = indexData(chartData)
        guard next != renderedPoints else { return }

        selectedIndex = nil

        guard animated, !renderedPoints.isEmpty else {
            renderedPoints = next
            chartOpacity = 1
            chartScaleY = 1
            return
        }

        transitionToken += 1
        let token = transitionToken

        withAnimation(.easeOut(duration: 0.12)) {
            chartOpacity = 0.2
            chartScaleY = 0.96
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            guard token == transitionToken else { return }
            renderedPoints = next
            withAnimation(.easeInOut(duration: 0.28)) {
                chartOpacity = 1
                chartScaleY = 1
            }
        }
    }

    private func axisLabel(for value: AxisValue) -> String? {
        guard let x = value.as(Double.self) else { return nil }
        let index = Int(round(x))
        guard renderedPoints.indices.contains(index) else { return nil }
        return period.chartAxisLabel(for: renderedPoints[index].date)
    }

    private func tooltipView(for point: IndexedWorkerPoint) -> some View {
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

private struct IndexedWorkerPoint: Identifiable, Equatable {
    let index: Int
    let date: Date
    let label: String
    let amount: Decimal

    var id: Int { index }
    var x: Double { Double(index) }
}
