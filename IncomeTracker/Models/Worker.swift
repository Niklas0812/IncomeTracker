import SwiftUI

struct Worker: Identifiable, Hashable {
    let id: Int
    let name: String
    var totalEarnings: Decimal
    var isActive: Bool
    let joinedDate: Date
    var dailyHours: Double?
    var hourlyRate: Double?
    var username: String

    var avatarColor: Color {
        let hash = abs(name.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.85)
    }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    init(
        id: Int,
        name: String,
        totalEarnings: Decimal = 0,
        isActive: Bool = true,
        joinedDate: Date = Date(),
        dailyHours: Double? = nil,
        hourlyRate: Double? = nil,
        username: String = ""
    ) {
        self.id = id
        self.name = name
        self.totalEarnings = totalEarnings
        self.isActive = isActive
        self.joinedDate = joinedDate
        self.dailyHours = dailyHours
        self.hourlyRate = hourlyRate
        self.username = username
    }

    init(from dto: WorkerDTO) {
        self.id = dto.id
        self.name = dto.name
        self.totalEarnings = Decimal(dto.totalEarnings)
        self.isActive = dto.isActive
        self.dailyHours = dto.dailyHours
        self.hourlyRate = dto.hourlyRate
        self.username = dto.username

        if let dateStr = dto.joinedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            self.joinedDate = formatter.date(from: dateStr) ?? Date()
        } else {
            self.joinedDate = Date()
        }
    }
}
