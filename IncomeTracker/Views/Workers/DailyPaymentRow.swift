import SwiftUI

struct DailyPaymentRow: View {
    let payment: DailyPaymentDTO
    let onToggle: () -> Void

    private var isPaid: Bool { payment.paymentStatus == "paid" }
    private var hasActivity: Bool { payment.transactionCount > 0 }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: payment.shiftDate) else { return payment.shiftDate }
        formatter.dateFormat = "EEE, d MMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                Text(formattedDate)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Spacer()

                Button {
                    onToggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isPaid ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isPaid ? AppTheme.Colors.positive : AppTheme.Colors.textTertiary)
                        Text(isPaid ? "Paid" : "Mark Paid")
                            .font(AppTheme.Typography.captionBold)
                            .foregroundStyle(isPaid ? AppTheme.Colors.positive : AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        (isPaid ? AppTheme.Colors.positive : AppTheme.Colors.textTertiary).opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(AppTheme.Spacing.md)

            Divider().padding(.horizontal, AppTheme.Spacing.md)

            // Detail rows
            VStack(spacing: 0) {
                detailRow("Shift Pay", String(format: "$%.2f", payment.basePayment))
                Divider().padding(.leading, AppTheme.Spacing.md)
                detailRow("EUR Earned", String(format: "\u{20AC}%.2f", payment.earningsGenerated))
                Divider().padding(.leading, AppTheme.Spacing.md)
                detailRow("Bonus", String(format: "$%.2f", payment.bonusAmount))
                Divider().padding(.leading, AppTheme.Spacing.md)
                detailRow("Transactions", "\(payment.transactionCount)")
            }

            Divider().padding(.horizontal, AppTheme.Spacing.md)

            // Total
            HStack {
                Text("Total Payment")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Spacer()
                Text(String(format: "$%.2f", payment.totalPayment))
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(payment.totalPayment > 0 ? AppTheme.Colors.positive : AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.md)
        }
        .cardStyle()
        .opacity(isPaid ? 0.7 : 1.0)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}
