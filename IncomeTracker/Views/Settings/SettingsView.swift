import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                // Appearance
                Section {
                    Picker("Theme", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(AppTheme.Colors.cardBackground)
                } header: {
                    sectionHeader("Appearance")
                } footer: {
                    Text("Choose how the app looks. System follows your device settings.")
                }

                // Currency
                Section {
                    Picker("Currency", selection: $viewModel.selectedCurrency) {
                        ForEach(viewModel.currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .listRowBackground(AppTheme.Colors.cardBackground)
                } header: {
                    sectionHeader("Display")
                }

                // Notifications
                Section {
                    toggleRow(
                        icon: "bell.badge.fill",
                        iconColor: AppTheme.Colors.primaryFallback,
                        title: "Transaction Alerts",
                        subtitle: "Get notified for each transaction",
                        isOn: $viewModel.transactionAlerts
                    )
                    toggleRow(
                        icon: "calendar.badge.clock",
                        iconColor: AppTheme.Colors.paysafe,
                        title: "Weekly Summary",
                        subtitle: "Receive a weekly earnings report",
                        isOn: $viewModel.weeklySummary
                    )
                    toggleRow(
                        icon: "chart.bar.doc.horizontal.fill",
                        iconColor: AppTheme.Colors.positive,
                        title: "Monthly Report",
                        subtitle: "Detailed monthly analytics email",
                        isOn: $viewModel.monthlyReport
                    )
                } header: {
                    sectionHeader("Notifications")
                }

                // About
                Section {
                    aboutRow(icon: "info.circle.fill", title: "Version", detail: "\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    aboutRow(icon: "star.fill", title: "Rate This App", detail: nil, isLink: true)
                    aboutRow(icon: "envelope.fill", title: "Contact Support", detail: nil, isLink: true)
                    aboutRow(icon: "doc.text.fill", title: "Privacy Policy", detail: nil, isLink: true)
                    aboutRow(icon: "doc.text.fill", title: "Terms of Service", detail: nil, isLink: true)
                } header: {
                    sectionHeader("About")
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Components

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppTheme.Typography.captionBold)
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func toggleRow(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppTheme.Colors.primaryFallback)
        }
        .listRowBackground(AppTheme.Colors.cardBackground)
        .sensoryFeedback(.selection, trigger: isOn.wrappedValue)
    }

    private func aboutRow(icon: String, title: String, detail: String?, isLink: Bool = false) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .frame(width: 28, height: 28)

            Text(title)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            if let detail {
                Text(detail)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }

            if isLink {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
        .listRowBackground(AppTheme.Colors.cardBackground)
    }
}

#Preview {
    SettingsView()
}
