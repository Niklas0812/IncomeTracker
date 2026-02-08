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

            SourceBadge(source: worker.paymentSource, style: .pill)
        }
        .frame(width: 130)
        .padding(AppTheme.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(worker.name), \(worker.totalEarnings.eurFormatted), \(worker.paymentSource.rawValue)")
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 12) {
            ForEach(SampleData.workers.prefix(4)) { worker in
                WorkerCard(worker: worker)
            }
        }
        .padding()
    }
}
