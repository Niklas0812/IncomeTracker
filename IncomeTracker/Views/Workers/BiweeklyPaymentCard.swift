import SwiftUI

struct BiweeklyPaymentCard: View {
    let payment: BiweeklyPaymentDTO
    let onToggle: () -> Void

    @State private var isExpanded = false

    private var isPaid: Bool { payment.paymentStatus == "paid" }

    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let displayFmt = DateFormatter()
        displayFmt.dateFormat = "d MMM"

        let startStr: String
        let endStr: String

        if let s = formatter.date(from: payment.weekStart) {
            startStr = displayFmt.string(from: s)
        } else {
            startStr = payment.weekStart
        }

        if let e = formatter.date(from: payment.weekEnd) {
            displayFmt.dateFormat = "d MMM yyyy"
            endStr = displayFmt.string(from: e)
        } else {
            endStr = payment.weekEnd
        }

        return "\(startStr) – \(endStr)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(dateRange)
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

            // Summary line
            HStack(spacing: AppTheme.Spacing.md) {
                summaryPill(String(format: "$%.2f", payment.totalPayment), "total")
                summaryPill(String(format: "%.0f hrs", payment.totalHours), "hours")
                summaryPill(String(format: "\u{20AC}%.2f", payment.earningsGenerated), "earned")
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.sm)

            Divider().padding(.horizontal, AppTheme.Spacing.md)

            // Detail rows
            VStack(spacing: 0) {
                detailRow("Base Pay", String(format: "$%.2f", payment.basePayment))
                Divider().padding(.leading, AppTheme.Spacing.md)
                detailRow("Bonus", String(format: "$%.2f", payment.bonusAmount))
                Divider().padding(.leading, AppTheme.Spacing.md)
                detailRow("Rate", String(format: "$%.2f/hr", payment.hourlyRate))
            }

            // Expand/collapse breakdown
            if !payment.dailyBreakdown.isEmpty {
                Divider().padding(.horizontal, AppTheme.Spacing.md)

                Button {
                    withAnimation(AppTheme.Animation.quick) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(AppTheme.Typography.caption)
                        Text(isExpanded ? "Hide Breakdown" : "Show Breakdown")
                            .font(AppTheme.Typography.captionBold)
                        Spacer()
                        Text("\(payment.dailyBreakdown.count) days")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                    .foregroundStyle(AppTheme.Colors.primaryFallback)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider().padding(.horizontal, AppTheme.Spacing.md)

                    VStack(spacing: 0) {
                        ForEach(payment.dailyBreakdown) { day in
                            HStack {
                                Text(shortDate(day.shiftDate))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                                    .frame(width: 80, alignment: .leading)

                                Text(String(format: "$%.2f", day.totalPayment))
                                    .font(AppTheme.Typography.callout)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)

                                Spacer()

                                Image(systemName: day.paymentStatus == "paid" ? "checkmark.circle.fill" : "circle")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(
                                        day.paymentStatus == "paid"
                                            ? AppTheme.Colors.positive
                                            : AppTheme.Colors.textTertiary
                                    )
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xxs)

                            if day.id != payment.dailyBreakdown.last?.id {
                                Divider().padding(.leading, AppTheme.Spacing.md)
                            }
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.xxs)
                }
            }
        }
        .cardStyle()
        .opacity(isPaid ? 0.7 : 1.0)
    }

    private func summaryPill(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTheme.Typography.captionBold)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(label)
                .font(AppTheme.Typography.micro)
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
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

    private func shortDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date)
    }
}
