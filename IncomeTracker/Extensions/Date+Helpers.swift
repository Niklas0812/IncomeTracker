import Foundation

extension Date {

    /// "Good morning" / "Good afternoon" / "Good evening" based on hour
    static var greetingPrefix: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    /// e.g. "Saturday, 8 Feb 2025"
    var fullDateString: String {
        formatted(.dateTime.weekday(.wide).day().month(.abbreviated).year())
    }

    /// e.g. "8 Feb 2025"
    var mediumDateString: String {
        formatted(.dateTime.day().month(.abbreviated).year())
    }

    /// e.g. "8 Feb"
    var shortDateString: String {
        formatted(.dateTime.day().month(.abbreviated))
    }

    /// e.g. "14:32"
    var timeString: String {
        formatted(.dateTime.hour(.twoDigits(amPM: .abbreviated)).minute())
    }

    /// Section header: "Today", "Yesterday", or "Mon, 14 Jan 2025"
    var sectionHeader: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            return formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
        }
    }

    /// Group key — calendar day string for grouping transactions
    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    /// "Member since Jan 2024"
    var memberSinceString: String {
        "Member since \(formatted(.dateTime.month(.abbreviated).year()))"
    }
}
