import SwiftUI

struct Worker: Identifiable, Hashable {
    let id: UUID
    let name: String
    let paymentSource: PaymentSource
    var totalEarnings: Decimal
    var isActive: Bool
    let joinedDate: Date

    // Generate a consistent color from the name hash for avatar backgrounds
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
}
