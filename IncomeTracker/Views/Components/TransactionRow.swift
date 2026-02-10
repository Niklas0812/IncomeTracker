import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Avatar
            AvatarView(
                initials: initials(for: transaction.workerName),
                color: Color.fromString(transaction.workerName),
                size: 44
            )

            // Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(transaction.workerName)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                SourceBadge(source: transaction.paymentSource, style: .pill)
            }

            Spacer()

            // Amount & status
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xxs) {
                Text(transaction.amount.eurFormatted)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(transaction.status.color)

                Text("\(transaction.date.shortDateString) \u{00B7} \(transaction.date.timeString)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.workerName), \(transaction.amount.eurFormatted), \(transaction.status.rawValue)")
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct TransactionRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TransactionRow(transaction: Transaction(
                id: "preview-1", workerId: 1, workerName: "Test Worker",
                paymentSource: .paysafe, amount: 150, date: Date(), reference: "TXN-001"
            ))
        }
    }
}
