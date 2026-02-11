import SwiftUI

struct TelegramResponseTimeView: View {
    @StateObject private var vm = TelegramViewModel()

    var body: some View {
        Group {
            switch vm.state {
            case .loading:
                ProgressView("Loading users...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .userList:
                userListView

            case .register:
                registerView

            case .sendCode:
                sendCodeView

            case .verify:
                verifyView

            case .analyzing:
                VStack(spacing: AppTheme.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Analyzing response times...")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Text("This may take a while")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .results:
                resultsView

            case .error(let msg):
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.Colors.warning)
                    Text(msg)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Back to Users") { vm.state = .userList }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Telegram Response Time")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.fetchUsers() }
    }

    // MARK: - User List

    private var userListView: some View {
        VStack(spacing: 0) {
            if vm.users.isEmpty {
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    Text("No Telegram accounts registered")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Text("Register an account to analyze response times")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    Button("Register Account") {
                        vm.state = .register
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(vm.users) { user in
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(AppTheme.Colors.paysafe)

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text(user.phoneNumber ?? user.userId)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Text("ID: \(user.userId)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                            }

                            Spacer()

                            let isAuthed = user.authStatus == "authorized"
                            Text(user.authStatus ?? "unknown")
                                .font(AppTheme.Typography.micro)
                                .fontWeight(.semibold)
                                .foregroundStyle(isAuthed ? AppTheme.Colors.positive : AppTheme.Colors.warning)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    (isAuthed ? AppTheme.Colors.positive : AppTheme.Colors.warning).opacity(0.12)
                                )
                                .clipShape(Capsule())
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let isAuthed = user.authStatus == "authorized"
                            if isAuthed {
                                vm.selectedUserId = user.userId
                                vm.analyze()
                            } else {
                                vm.selectedUserId = user.userId
                                vm.sendCode()
                            }
                        }
                    }
                    .onDelete { offsets in
                        guard let index = offsets.first else { return }
                        let user = vm.users[index]
                        vm.deleteUser(user.userId)
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm.state = .register
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.Colors.primaryFallback)
                }
            }
        }
    }

    // MARK: - Register

    private var registerView: some View {
        Form {
            Section {
                TextField("User ID (any identifier)", text: $vm.regUserId)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                TextField("Phone Number (+1234567890)", text: $vm.regPhone)
                    .keyboardType(.phonePad)
                TextField("API ID", text: $vm.regApiId)
                    .keyboardType(.numberPad)
                TextField("API Hash", text: $vm.regApiHash)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
            } header: {
                Text("Telegram Credentials")
            } footer: {
                Text("Get API ID and API Hash from my.telegram.org")
            }

            if let err = vm.errorMessage {
                Section {
                    Text(err)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.negative)
                }
            }

            Section {
                Button("Register & Send Code") {
                    vm.register()
                }
                .disabled(vm.regUserId.isEmpty || vm.regPhone.isEmpty || vm.regApiId.isEmpty || vm.regApiHash.isEmpty || vm.isProcessing)

                Button("Cancel") {
                    vm.state = .userList
                }
                .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
    }

    // MARK: - Send Code

    private var sendCodeView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.primaryFallback)

            Text("Verification code sent to Telegram")
                .font(AppTheme.Typography.headline)

            if let msg = vm.statusMessage {
                Text(msg)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Continue to Verification") {
                vm.state = .verify
            }
            .buttonStyle(.borderedProminent)

            if let err = vm.errorMessage {
                Text(err)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.negative)
            }

            Button("Back") { vm.state = .userList }
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .padding()
    }

    // MARK: - Verify

    private var verifyView: some View {
        Form {
            Section {
                TextField("Verification Code", text: $vm.verifyCode)
                    .keyboardType(.numberPad)
                SecureField("2FA Password (optional)", text: $vm.verifyPassword)
            } header: {
                Text("Enter Verification Code")
            } footer: {
                Text("Enter the code sent to your Telegram app. If 2FA is enabled, enter the password too.")
            }

            if let err = vm.errorMessage {
                Section {
                    Text(err)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.negative)
                }
            }

            Section {
                Button("Verify") {
                    vm.verify()
                }
                .disabled(vm.verifyCode.isEmpty || vm.isProcessing)

                Button("Cancel") { vm.state = .userList }
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                if let results = vm.analysisResults, !results.isEmpty {
                    ForEach(results) { result in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            if let tf = result.timeframe {
                                Text(tf)
                                    .font(AppTheme.Typography.title3)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                            }

                            VStack(spacing: 0) {
                                if let avgMin = result.avgResponseMinutes {
                                    resultRow("Avg Response", formatDuration(avgMin))
                                    Divider().padding(.leading, AppTheme.Spacing.md)
                                }
                                if let total = result.totalMessages {
                                    resultRow("Total Messages", "\(total)")
                                    Divider().padding(.leading, AppTheme.Spacing.md)
                                }
                                if let responses = result.totalResponses {
                                    resultRow("Responses", "\(responses)")
                                    Divider().padding(.leading, AppTheme.Spacing.md)
                                }
                                if let over10 = result.responsesOver10min {
                                    resultRow("Over 10min", "\(over10)")
                                    Divider().padding(.leading, AppTheme.Spacing.md)
                                }
                                if let pct = result.responsesOver10minPercent {
                                    resultRow("Over 10min %", String(format: "%.1f%%", pct))
                                }
                            }
                            .cardStyle()
                        }
                    }
                } else {
                    Text("No analysis results available")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Button("Back to Users") {
                    vm.state = .userList
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(AppTheme.Spacing.md)
        }
    }

    private func resultRow(_ label: String, _ value: String) -> some View {
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

    private func formatDuration(_ minutes: Double) -> String {
        if minutes < 60 {
            return String(format: "%.0f min", minutes)
        }
        let hours = minutes / 60
        if hours < 24 {
            return String(format: "%.1f hrs", hours)
        }
        let days = hours / 24
        return String(format: "%.1f days", days)
    }
}

// MARK: - ViewModel

final class TelegramViewModel: ObservableObject {
    enum ViewState {
        case loading, userList, register, sendCode, verify, analyzing, results
        case error(String)
    }

    @Published var state: ViewState = .loading
    @Published var users: [TelegramUserDTO] = []
    @Published var selectedUserId: String = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var statusMessage: String?
    @Published var analysisResults: [TelegramAnalysisResultDTO]?

    // Registration fields
    @Published var regUserId = ""
    @Published var regPhone = ""
    @Published var regApiId = ""
    @Published var regApiHash = ""

    // Verification fields
    @Published var verifyCode = ""
    @Published var verifyPassword = ""

    private let client = APIClient.shared

    func fetchUsers() {
        state = .loading
        Task {
            do {
                let response: TelegramUsersResponse = try await client.request(.telegramUsers)
                await MainActor.run {
                    self.users = response.data ?? []
                    self.state = .userList
                }
            } catch {
                await MainActor.run {
                    self.users = []
                    self.state = .userList
                }
            }
        }
    }

    func register() {
        isProcessing = true
        errorMessage = nil

        let body: [String: Any] = [
            "user_id": regUserId,
            "phone_number": regPhone,
            "api_id": regApiId,
            "api_hash": regApiHash,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            errorMessage = "Invalid input"
            isProcessing = false
            return
        }

        Task {
            do {
                let response: TelegramActionResponse = try await client.request(.telegramRegister, body: data)
                await MainActor.run {
                    self.isProcessing = false
                    if response.status == "success" || response.status == "ok" || response.status == "saved" {
                        self.selectedUserId = self.regUserId
                        self.sendCode()
                    } else {
                        self.errorMessage = response.message ?? response.error ?? "Registration failed"
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func sendCode() {
        isProcessing = true
        errorMessage = nil

        let body: [String: Any] = ["user_id": selectedUserId]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            isProcessing = false
            return
        }

        Task {
            do {
                let response: TelegramActionResponse = try await client.request(.telegramSendCode, body: data)
                await MainActor.run {
                    self.isProcessing = false
                    self.statusMessage = response.message
                    if response.status == "success" || response.status == "ok" || response.status == "code_sent" {
                        self.state = .sendCode
                    } else {
                        self.errorMessage = response.message ?? response.error ?? "Failed to send code"
                        self.state = .sendCode
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                    self.state = .sendCode
                }
            }
        }
    }

    func verify() {
        isProcessing = true
        errorMessage = nil

        var body: [String: Any] = [
            "user_id": selectedUserId,
            "code": verifyCode,
        ]
        if !verifyPassword.isEmpty {
            body["password"] = verifyPassword
        }
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            isProcessing = false
            return
        }

        Task {
            do {
                let response: TelegramActionResponse = try await client.request(.telegramVerify, body: data)
                await MainActor.run {
                    self.isProcessing = false
                    if response.status == "success" || response.status == "ok" || response.status == "authorized" {
                        self.fetchUsers()
                    } else {
                        self.errorMessage = response.message ?? response.error ?? "Verification failed"
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func deleteUser(_ userId: String) {
        Task {
            do {
                let _: TelegramActionResponse = try await client.request(.telegramDeleteUser(userId: userId))
                await MainActor.run {
                    self.users.removeAll { $0.userId == userId }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func analyze() {
        state = .analyzing
        errorMessage = nil

        let body: [String: Any] = ["user_id": selectedUserId]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            state = .error("Invalid input")
            return
        }

        Task {
            do {
                let response: TelegramAnalysisResponse = try await client.request(.telegramAnalyze, body: data, longTimeout: true)
                await MainActor.run {
                    if let err = response.error, !err.isEmpty {
                        self.state = .error(err)
                    } else {
                        self.analysisResults = response.results
                        self.state = .results
                    }
                }
            } catch {
                await MainActor.run {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
}
