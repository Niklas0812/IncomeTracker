import SwiftUI

struct TransactionDetailSheet: View {
    let transaction: Transaction
    @Environment(\.dismiss) private var dismiss
    @State private var showScreenshot = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Amount hero
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text(transaction.amount.eurFormatted)
                            .font(AppTheme.Typography.heroNumber)
                            .foregroundStyle(transaction.status.color)

                        statusBadge
                    }
                    .padding(.top, AppTheme.Spacing.lg)

                    // Details card
                    VStack(spacing: 0) {
                        detailRow(label: "Worker", value: transaction.workerName)
                        Divider().padding(.leading, AppTheme.Spacing.md)
                        detailRow(label: "Payment Source") {
                            SourceBadge(source: transaction.paymentSource, style: .pill)
                        }
                        Divider().padding(.leading, AppTheme.Spacing.md)
                        detailRow(label: "Date", value: transaction.date.mediumDateString)
                        Divider().padding(.leading, AppTheme.Spacing.md)
                        detailRow(label: "Time", value: transaction.date.timeString)
                        Divider().padding(.leading, AppTheme.Spacing.md)
                        referenceRow
                    }
                    .cardStyle()

                    // Screenshot button
                    if transaction.hasScreenshot {
                        Button {
                            showScreenshot = true
                        } label: {
                            HStack {
                                Image(systemName: "photo")
                                Text("View Screenshot")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(AppTheme.Colors.primaryFallback)
                            .padding(AppTheme.Spacing.md)
                            .cardStyle()
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.Colors.backgroundPrimary)
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppTheme.Typography.callout)
                }
            }
            .sheet(isPresented: $showScreenshot) {
                if let filename = transaction.screenshotFilename {
                    ScreenshotViewer(filename: filename)
                }
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: transaction.status.iconName)
                .font(.system(size: 12))
            Text(transaction.status.rawValue)
                .font(AppTheme.Typography.captionBold)
        }
        .foregroundStyle(transaction.status.color)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(transaction.status.color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .padding(AppTheme.Spacing.md)
    }

    private func detailRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            content()
        }
        .padding(AppTheme.Spacing.md)
    }

    private var referenceRow: some View {
        HStack {
            Text("Reference")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            Text(transaction.reference)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Button {
                UIPasteboard.general.string = transaction.reference
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.Colors.primaryFallback)
            }
            .accessibilityLabel("Copy reference")
        }
        .padding(AppTheme.Spacing.md)
    }
}

struct TransactionDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        TransactionDetailSheet(transaction: Transaction(
            id: "test-1",
            workerId: 123,
            workerName: "Test Worker",
            paymentSource: .paysafe,
            amount: 100,
            date: Date(),
            reference: "TXN-001"
        ))
    }
}
