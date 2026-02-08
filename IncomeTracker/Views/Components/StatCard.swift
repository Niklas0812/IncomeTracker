import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var iconName: String? = nil
    var iconColor: Color = AppTheme.Colors.primaryFallback

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Text(value)
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        StatCard(title: "Average", value: "€245.30", subtitle: "Per transaction", iconName: "chart.bar.fill")
        StatCard(title: "Highest", value: "€2,100.00", iconName: "arrow.up.circle.fill", iconColor: .green)
    }
    .padding()
}
