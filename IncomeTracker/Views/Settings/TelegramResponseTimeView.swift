import SwiftUI

struct TelegramResponseTimeView: View {
    @State private var isLoading = true
    @State private var users: [[String: Any]] = []

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if users.isEmpty {
                EmptyStateView(
                    iconName: "paperplane",
                    title: "No Data",
                    message: "No Telegram response time data available."
                )
            } else {
                List {
                    ForEach(0..<users.count, id: \.self) { index in
                        let user = users[index]
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(AppTheme.Colors.paysafe)

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text(user["username"] as? String ?? "Unknown")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Text("ID: \(user["user_id"] as? String ?? "")")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                            }

                            Spacer()

                            Text(user["auth_status"] as? String ?? "")
                                .font(AppTheme.Typography.micro)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.Colors.positive)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.positive.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Telegram Stats")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fetchData() }
    }

    private func fetchData() {
        struct TelegramResponse: Codable {
            let users: [[String: String]]
        }

        Task {
            do {
                let response: TelegramResponse = try await APIClient.shared.request(.telegramStats)
                await MainActor.run {
                    self.users = response.users.map { dict in
                        dict as [String: Any]
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
