import SwiftUI

struct AddWorkerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: WorkersViewModel

    @State private var selectedWorker: AvailableWorkerDTO?
    @State private var manualUserId = ""
    @State private var name = ""
    @State private var hourlyRate = ""
    @State private var dailyHours = "12"
    @State private var isLoading = false
    @State private var showValidation = false
    @State private var errorMessage: String?
    @State private var useManualEntry = false

    private var resolvedUserId: Int? {
        if let selected = selectedWorker {
            return selected.userId
        }
        return Int(manualUserId)
    }

    private var resolvedName: String {
        if let selected = selectedWorker {
            return name.isEmpty ? selected.displayName : name
        }
        return name.trimmingCharacters(in: .whitespaces)
    }

    private var isValid: Bool {
        resolvedUserId != nil && !resolvedName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if viewModel.availableWorkers.isEmpty && !useManualEntry {
                        // No available workers, show manual entry
                        manualEntryFields
                    } else if useManualEntry {
                        manualEntryFields

                        if !viewModel.availableWorkers.isEmpty {
                            Button("Select from existing workers") {
                                useManualEntry = false
                            }
                            .font(AppTheme.Typography.caption)
                        }
                    } else {
                        Picker("Worker", selection: $selectedWorker) {
                            Text("Select a worker...").tag(nil as AvailableWorkerDTO?)
                            ForEach(viewModel.availableWorkers) { worker in
                                Text("\(worker.displayName) (\(worker.userId))")
                                    .tag(worker as AvailableWorkerDTO?)
                            }
                        }

                        if selectedWorker != nil {
                            TextField("Display Name (optional override)", text: $name)
                                .font(AppTheme.Typography.body)
                                .textContentType(.name)
                                .autocorrectionDisabled()
                        }

                        Button("Enter ID manually") {
                            useManualEntry = true
                            selectedWorker = nil
                        }
                        .font(AppTheme.Typography.caption)
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
                                color: Color.fromString(resolvedName),
                                size: 44
                            )
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text(resolvedName)
                                    .font(AppTheme.Typography.headline)
                                Text("ID: \(resolvedUserId ?? 0)")
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
            .onAppear {
                viewModel.fetchAvailableWorkers()
            }
        }
    }

    private var manualEntryFields: some View {
        Group {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                TextField("Telegram User ID", text: $manualUserId)
                    .font(AppTheme.Typography.body)
                    .keyboardType(.numberPad)
                    .onChange(of: manualUserId) { _ in showValidation = false }

                if showValidation && Int(manualUserId) == nil {
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
        }
    }

    private var previewInitials: String {
        let n = resolvedName
        let parts = n.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(n.prefix(2)).uppercased()
    }

    private func save() {
        withAnimation(AppTheme.Animation.quick) { showValidation = true }
        guard isValid, let uid = resolvedUserId else { return }

        isLoading = true
        errorMessage = nil

        viewModel.createWorker(
            userId: uid,
            username: resolvedName,
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
