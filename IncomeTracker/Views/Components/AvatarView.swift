import SwiftUI

struct AvatarView: View {
    let initials: String
    let color: Color
    var size: CGFloat = 40

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient)
            .clipShape(Circle())
            .accessibilityLabel("Avatar for \(initials)")
    }
}

#Preview {
    HStack(spacing: 12) {
        AvatarView(initials: "EM", color: .blue)
        AvatarView(initials: "MR", color: .purple, size: 56)
        AvatarView(initials: "SL", color: .orange, size: 32)
    }
    .padding()
}
