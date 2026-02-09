import SwiftUI

struct AddWorkerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: WorkersViewModel

    @State private var userId = ""
    @State private var name = ""
    @State private var hourlyRate = ""
    @State private var dailyHours = "12"
    @State private var isLoading = false
    @State private var showValidation = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(userId) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        TextField("Telegram User ID", text: $userId)
                            .font(AppTheme.Typography.body)
                            .keyboardType(.numberPad)
                            .onChange(of: userId) { _ in showValidation = false }

                        if showValidation && Int(userId) == nil {
                            Text("Valid numeric User ID is required")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.negative)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        TextField("Username", text: $name)
                            .font(AppTheme.Typography.body)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .onChange(of: name) { _ in showValidation = false }

                        if showValidation && name.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("Name is required")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.negative)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                } header: {
                    Text("Worker Information")
                }

                Section {
                    HStack {
                        Text("Hourly Rate ($)")
                            .font(AppTheme.Typography.body)
                        Spacer()
                        TextField("1.66", text: $hourlyRate)
                            .font(AppTheme.Typography.body)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    HStack {
                        Text("Daily Hours")
                            .font(AppTheme.Typography.body)
                        Spacer()
                        TextField("12", text: $dailyHours)
                            .font(AppTheme.Typography.body)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                } header: {
                    Text("Pay Configuration")
                }

                // Preview
                if isValid {
                    Section {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            AvatarView(
                                initials: previewInitials,
                                color: Color.fromString(name),
                                size: 44
                            )
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text(name.trimmingCharacters(in: .whitespaces))
                                    .font(AppTheme.Typography.headline)
                                Text("ID: \(userId)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.xxs)
                    } header: {
                        Text("Preview")
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.negative)
                    }
                }
            }
            .navigationTitle("Add Worker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        save()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(AppTheme.Colors.primaryFallback)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading)
                }
            }
        }
    }

    private var previewInitials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(trimmed.prefix(2)).uppercased()
    }

    private func save() {
        withAnimation(AppTheme.Animation.quick) { showValidation = true }
        guard isValid else { return }

        isLoading = true
        errorMessage = nil

        viewModel.createWorker(
            userId: Int(userId)!,
            username: name.trimmingCharacters(in: .whitespaces),
            hourlyRate: Double(hourlyRate) ?? 1.0,
            dailyHours: Double(dailyHours) ?? 12.0
        ) { success in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = "Failed to create worker. Check server connection."
            }
        }
    }
}

struct AddWorkerSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddWorkerSheet(viewModel: WorkersViewModel())
    }
}
