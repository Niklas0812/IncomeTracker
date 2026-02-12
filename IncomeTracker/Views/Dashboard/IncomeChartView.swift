import SwiftUI
import Charts

struct IncomeChartView: View {
    let dataPoints: [ChartDataPoint]
    let period: TimePeriod

    @State private var renderedPoints: [IndexedIncomePoint] = []
    @State private var selectedIndex: Int?
    @State private var chartOpacity: Double = 1
    @State private var chartScaleY: CGFloat = 1
    @State private var transitionToken: Int = 0

    private var selectedPoint: IndexedIncomePoint? {
        guard let selectedIndex, renderedPoints.indices.contains(selectedIndex) else { return nil }
        return renderedPoints[selectedIndex]
    }

    private var maxY: Double {
        let maxValue = renderedPoints.map { ($0.paysafeAmount + $0.paypalAmount).doubleValue }.max() ?? 0
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
        .ratio(period.chartBarRatioGroupedSeries)
    }

    private var dataRevision: [String] {
        dataPoints.map { "\($0.id)-\($0.paysafeAmount)-\($0.paypalAmount)" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.md) {
                legendItem(color: AppTheme.Colors.paysafe, label: "PaySafe")
                legendItem(color: AppTheme.Colors.paypal, label: "PayPal")
            }
            .padding(.horizontal, AppTheme.Spacing.md)

            Chart {
                ForEach(renderedPoints) { point in
                    BarMark(
                        x: .value("Bucket", point.x),
                        y: .value("Amount", point.paysafeAmount.doubleValue),
                        width: barWidth
                    )
                    .position(by: .value("Source", "PaySafe"))
                    .foregroundStyle(AppTheme.Colors.paysafe.gradient)
                    .cornerRadius(4)

                    BarMark(
                        x: .value("Bucket", point.x),
                        y: .value("Amount", point.paypalAmount.doubleValue),
                        width: barWidth
                    )
                    .position(by: .value("Source", "PayPal"))
                    .foregroundStyle(AppTheme.Colors.paypal.gradient)
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
            .frame(height: 200)
            .opacity(chartOpacity)
            .scaleEffect(x: 1, y: chartScaleY, anchor: .bottom)
        }
        .padding(AppTheme.Spacing.md)
        .chartCardStyle()
        .onAppear {
            if renderedPoints.isEmpty {
                renderedPoints = indexData(dataPoints)
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

    private func indexData(_ points: [ChartDataPoint]) -> [IndexedIncomePoint] {
        points
            .sorted { $0.date < $1.date }
            .enumerated()
            .map { idx, point in
                IndexedIncomePoint(
                    index: idx,
                    date: point.date,
                    label: point.label,
                    paysafeAmount: point.paysafeAmount,
                    paypalAmount: point.paypalAmount
                )
            }
    }

    private func updateRenderedData(animated: Bool) {
        let next = indexData(dataPoints)
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

    private func tooltipView(for point: IndexedIncomePoint) -> some View {
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

private struct IndexedIncomePoint: Identifiable, Equatable {
    let index: Int
    let date: Date
    let label: String
    let paysafeAmount: Decimal
    let paypalAmount: Decimal

    var id: Int { index }
    var x: Double { Double(index) }
    var total: Decimal { paysafeAmount + paypalAmount }
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
