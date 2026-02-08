import SwiftUI

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: iconName)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .padding(.bottom, AppTheme.Spacing.xs)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(message)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.primaryFallback)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppTheme.Spacing.xl)
    }
}

#Preview {
    EmptyStateView(
        iconName: "tray",
        title: "No Transactions",
        message: "There are no transactions matching your current filters. Try adjusting your search.",
        actionTitle: "Clear Filters"
    ) {
        print("Clear")
    }
}
