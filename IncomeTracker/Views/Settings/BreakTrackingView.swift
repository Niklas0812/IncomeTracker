import SwiftUI

struct BreakTrackingView: View {
    @State private var isLoading = true
    @State private var users: [BreakUser] = []

    struct BreakUser: Identifiable {
        let id: String
        let username: String
        let createdAt: String
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if users.isEmpty {
                EmptyStateView(
                    iconName: "clock.badge.checkmark",
                    title: "No Data",
                    message: "No break tracking data available yet."
                )
            } else {
                List(users) { user in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(AppTheme.Colors.paypal)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                            Text(user.username)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text("Since \(user.createdAt)")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Break Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fetchData() }
    }

    private func fetchData() {
        struct BreaksResponse: Codable {
            let users: [BreakUserDTO]
            let breakData: [String]

            enum CodingKeys: String, CodingKey {
                case users
                case breakData = "break_data"
            }
        }

        struct BreakUserDTO: Codable {
            let userId: String
            let username: String
            let createdAt: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case username
                case createdAt = "created_at"
            }
        }

        Task {
            do {
                let response: BreaksResponse = try await APIClient.shared.request(.breaks(userId: nil))
                await MainActor.run {
                    self.users = response.users.map {
                        BreakUser(id: $0.userId, username: $0.username, createdAt: $0.createdAt)
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
