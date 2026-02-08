import SwiftUI

struct SourceBadge: View {
    let source: PaymentSource
    var style: BadgeStyle = .pill

    enum BadgeStyle {
        case pill    // Full pill with text
        case compact // Small icon only
        case dot     // Tiny color dot
    }

    var body: some View {
        switch style {
        case .pill:
            HStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: source.iconName)
                    .font(.system(size: 10, weight: .semibold))
                Text(source.rawValue)
                    .font(AppTheme.Typography.micro)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(source.color)
            .padding(.horizontal, AppTheme.Spacing.xs)
            .padding(.vertical, 3)
            .background(source.color.opacity(0.12))
            .clipShape(Capsule())
            .accessibilityLabel("\(source.rawValue) payment source")

        case .compact:
            Image(systemName: source.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(source.color)
                .frame(width: 24, height: 24)
                .background(source.color.opacity(0.12))
                .clipShape(Circle())
                .accessibilityLabel(source.rawValue)

        case .dot:
            Circle()
                .fill(source.color)
                .frame(width: 8, height: 8)
                .accessibilityLabel(source.rawValue)
        }
    }
}

struct SourceBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                SourceBadge(source: .paysafe, style: .pill)
                SourceBadge(source: .paypal, style: .pill)
            }
            HStack(spacing: 12) {
                SourceBadge(source: .paysafe, style: .compact)
                SourceBadge(source: .paypal, style: .compact)
            }
            HStack(spacing: 12) {
                SourceBadge(source: .paysafe, style: .dot)
                SourceBadge(source: .paypal, style: .dot)
            }
        }
        .padding()
    }
}
