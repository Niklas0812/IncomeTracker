import SwiftUI

struct AddWorkerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedSource: PaymentSource = .paysafe
    @State private var isLoading = false
    @State private var showValidation = false

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Name field
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        TextField("Full Name", text: $name)
                            .font(AppTheme.Typography.body)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .onChange(of: name) { showValidation = false }

                        if showValidation && !isValid {
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
                    Picker("Payment Source", selection: $selectedSource) {
                        ForEach(PaymentSource.allCases) { source in
                            HStack {
                                Image(systemName: source.iconName)
                                    .foregroundStyle(source.color)
                                Text(source.rawValue)
                            }
                            .tag(source)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Payment Source")
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
                                SourceBadge(source: selectedSource, style: .pill)
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.xxs)
                    } header: {
                        Text("Preview")
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
        // Simulate network delay then dismiss (UI-only demo)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    AddWorkerSheet()
}
