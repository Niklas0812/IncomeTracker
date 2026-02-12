import SwiftUI
import Charts

/// Shared chart configuration that eliminates duplicated logic between
/// IncomeChartView and WorkerEarningsChartView.
struct ChartConfiguration {
    let period: TimePeriod
    let dates: [Date]

    private let calendar = Calendar.current

    // MARK: - Chart Unit

    var chartUnit: Calendar.Component {
        switch period {
        case .daily: return .hour
        case .weekly: return .day
        case .monthly: return .day
        case .threeMonths, .sixMonths, .oneYear: return .month
        }
    }

    // MARK: - Bar Width

    var barWidth: MarkDimension {
        switch period {
        case .daily: return .ratio(0.45)
        case .weekly: return .ratio(0.6)
        case .monthly: return .ratio(0.7)
        case .threeMonths: return .ratio(0.5)
        case .sixMonths: return .ratio(0.55)
        case .oneYear: return .ratio(0.65)
        }
    }

    // MARK: - X Domain

    var xDomain: ClosedRange<Date> {
        guard let minDate = dates.min(),
              let maxDate = dates.max() else {
            return Date()...Date()
        }
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
        case .monthly:
            let paddedMin = calendar.date(byAdding: .hour, value: -12, to: minDate) ?? minDate
            let paddedMax = calendar.date(byAdding: .hour, value: 12, to: maxDate) ?? maxDate
            return paddedMin...paddedMax
        default:
            let paddedMin = calendar.date(byAdding: chartUnit, value: -1, to: minDate) ?? minDate
            let paddedMax = calendar.date(byAdding: chartUnit, value: 1, to: maxDate) ?? maxDate
            return paddedMin...paddedMax
        }
    }

    // MARK: - Monthly Axis Dates (deduplicated by unique month)

    var monthlyAxisDates: [Date] {
        var seen = Set<Int>()
        var uniqueDates: [Date] = []

        let sorted = dates.sorted()
        for date in sorted {
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let key = year * 100 + month

            if !seen.contains(key) {
                seen.insert(key)
                if let interval = calendar.dateInterval(of: .month, for: date) {
                    let midpoint = interval.start.addingTimeInterval(interval.duration / 2)
                    uniqueDates.append(midpoint)
                }
            }
        }

        return uniqueDates
    }

    // MARK: - 1M Evenly-Spaced Day Axis Dates

    var monthlyDayAxisDates: [Date] {
        guard let minDate = dates.min(),
              let maxDate = dates.max() else { return [] }

        let startDay = calendar.startOfDay(for: minDate)
        let endDay = calendar.startOfDay(for: maxDate)
        let totalDays = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 28

        let desiredCount = 5
        let stride = max(totalDays / desiredCount, 1)

        var result: [Date] = []
        var current = startDay

        while current <= endDay {
            result.append(current)
            guard let next = calendar.date(byAdding: .day, value: stride, to: current) else { break }
            current = next
        }

        if result.count > desiredCount + 1 {
            result = Array(result.prefix(desiredCount + 1))
        }

        return result
    }

    // MARK: - X Axis Date Format

    var xAxisDateFormat: Date.FormatStyle {
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
            return .dateTime.month(.narrow)
        }
    }
}
