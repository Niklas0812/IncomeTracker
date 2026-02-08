import SwiftUI

extension Color {

    /// Generate a deterministic color from a string (for worker avatars)
    static func fromString(_ string: String) -> Color {
        let hash = abs(string.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.5, brightness: 0.8)
    }

    /// Slightly lighter version of the color for backgrounds
    func lightened(by amount: Double = 0.3) -> Color {
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: max(Double(s) - amount, 0.1), brightness: min(Double(b) + amount, 1.0))
    }
}
