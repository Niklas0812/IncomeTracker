import Foundation

extension Decimal {

    /// Format as currency: "€1,234.56"
    var eurFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.currencySymbol = "€"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "€0.00"
    }

    /// Compact format for large numbers: "€12.5K"
    var eurCompact: String {
        let doubleValue = NSDecimalNumber(decimal: self).doubleValue
        if abs(doubleValue) >= 1_000_000 {
            return String(format: "€%.1fM", doubleValue / 1_000_000)
        } else if abs(doubleValue) >= 1_000 {
            return String(format: "€%.1fK", doubleValue / 1_000)
        }
        return eurFormatted
    }

    /// Plain number string without currency: "1,234.56"
    var plainFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "0.00"
    }

    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
