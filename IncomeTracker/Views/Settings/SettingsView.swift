import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                // Server
                Section {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.Colors.primaryFallback)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.Colors.primaryFallback.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Server URL")
                                .font(AppTheme.Typography.callout)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            TextField("https://your-server.com", text: $viewModel.serverURL)
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .textContentType(.URL)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        Spacer()

                        if viewModel.isCheckingServer {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Circle()
                                .fill(viewModel.isServerReachable ? AppTheme.Colors.positive : AppTheme.Colors.negative)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .listRowBackground(AppTheme.Colors.cardBackground)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.Colors.warning)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.Colors.warning.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("API Token")
                                .font(AppTheme.Typography.callout)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            SecureField("Bearer token", text: $viewModel.apiToken)
                                .font(AppTheme.Typography.caption)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                    }
                    .listRowBackground(AppTheme.Colors.cardBackground)

                    Button {
                        viewModel.checkServerHealth()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Test Connection")
                                .font(AppTheme.Typography.callout)
                                .foregroundStyle(AppTheme.Colors.primaryFallback)
                            Spacer()
                        }
                    }
                    .listRowBackground(AppTheme.Colors.cardBackground)
                } header: {
                    sectionHeader("Server")
                }

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

                // Analytics
                Section {
                    NavigationLink {
                        TelegramResponseTimeView()
                    } label: {
                        aboutRow(icon: "paperplane.fill", title: "Telegram Response Times", detail: nil)
                    }
                    .listRowBackground(AppTheme.Colors.cardBackground)

                    NavigationLink {
                        BreakTrackingView()
                    } label: {
                        aboutRow(icon: "clock.badge.checkmark", title: "Break Tracking", detail: nil)
                    }
                    .listRowBackground(AppTheme.Colors.cardBackground)
                } header: {
                    sectionHeader("Analytics")
                }

                // About
                Section {
                    aboutRow(icon: "info.circle.fill", title: "Version", detail: viewModel.appVersion)
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
    }

    private func aboutRow(icon: String, title: String, detail: String?) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .frame(width: 28, height: 28)

            Text(title)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Spacer()

            if let detail = detail {
                Text(detail)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
