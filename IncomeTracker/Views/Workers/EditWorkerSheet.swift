import SwiftUI

struct EditWorkerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let worker: Worker
    let viewModel: WorkersViewModel

    @State private var name: String
    @State private var hourlyRate: String
    @State private var dailyHours: String
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(worker: Worker, viewModel: WorkersViewModel) {
        self.worker = worker
        self.viewModel = viewModel
        _name = State(initialValue: worker.name)
        _hourlyRate = State(initialValue: worker.hourlyRate.map { String(format: "%.2f", $0) } ?? "")
        _dailyHours = State(initialValue: worker.dailyHours.map { String(format: "%.1f", $0) } ?? "12")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("User ID")
                            .font(AppTheme.Typography.body)
                        Spacer()
                        Text("\(worker.id)")
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }

                    TextField("Username", text: $name)
                        .font(AppTheme.Typography.body)
                        .autocorrectionDisabled()
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

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.negative)
                    }
                }
            }
            .navigationTitle("Edit Worker")
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

    private func save() {
        isLoading = true
        errorMessage = nil

        viewModel.updateWorker(
            userId: worker.id,
            username: name.trimmingCharacters(in: .whitespaces),
            hourlyRate: Double(hourlyRate) ?? 1.0,
            dailyHours: Double(dailyHours) ?? 12.0
        ) { success in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = "Failed to update worker."
            }
        }
    }
}
