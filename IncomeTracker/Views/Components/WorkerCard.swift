import SwiftUI

struct WorkerCard: View {
    let worker: Worker

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            AvatarView(
                initials: worker.initials,
                color: worker.avatarColor,
                size: 52
            )

            VStack(spacing: AppTheme.Spacing.xxs) {
                Text(worker.name)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(worker.totalEarnings.eurFormatted)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
        }
        .frame(width: 130)
        .padding(AppTheme.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(worker.name), \(worker.totalEarnings.eurFormatted)")
    }
}

struct WorkerCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                WorkerCard(worker: Worker(id: 1, name: "Test Worker", totalEarnings: 1500))
            }
            .padding()
        }
    }
}
