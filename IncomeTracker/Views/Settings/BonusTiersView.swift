import SwiftUI

struct BonusTiersView: View {
    @State private var tiers: [EditableTier] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var error: String?
    @State private var showSaved = false

    private let client = APIClient.shared

    var body: some View {
        List {
            Section {
                ForEach($tiers) { $tier in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        HStack(spacing: 4) {
                            Text("€")
                                .font(AppTheme.Typography.callout)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                            TextField("0", text: $tier.thresholdText)
                                .font(AppTheme.Typography.callout)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                        }

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.Colors.textTertiary)

                        HStack(spacing: 4) {
                            Text("$")
                                .font(AppTheme.Typography.callout)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                            TextField("0.00", text: $tier.bonusText)
                                .font(AppTheme.Typography.callout)
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                        }

                        Spacer()
                    }
                    .listRowBackground(AppTheme.Colors.cardBackground)
                }
                .onDelete(perform: deleteTier)

                Button {
                    withAnimation {
                        let next = (tiers.last.flatMap { Int($0.thresholdText) } ?? 0) + 100
                        tiers.append(EditableTier(threshold: next, bonus: 3.0))
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppTheme.Colors.primaryFallback)
                        Text("Add Tier")
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(AppTheme.Colors.primaryFallback)
                    }
                }
                .listRowBackground(AppTheme.Colors.cardBackground)
            } header: {
                Text("Cumulative Bonus Tiers")
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            } footer: {
                Text("Each threshold adds its bonus on top of previous tiers. E.g. €100→$3 + €200→$3 = $6 total at €200+.")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }

            if let error {
                Section {
                    Text(error)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.negative)
                }
            }
        }
        .navigationTitle("Bonus Tiers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button("Save") {
                        saveTiers()
                    }
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.primaryFallback)
                }
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
            if showSaved {
                savedToast
            }
        }
        .task {
            await fetchTiers()
        }
    }

    private var savedToast: some View {
        VStack {
            Spacer()
            Text("Saved")
                .font(AppTheme.Typography.callout)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppTheme.Colors.positive)
                .clipShape(Capsule())
                .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func fetchTiers() async {
        do {
            let response: BonusTiersResponse = try await client.request(.bonusTiers)
            tiers = response.tiers.map { EditableTier(threshold: $0.threshold, bonus: $0.bonus) }
        } catch {
            self.error = "Failed to load tiers"
        }
        isLoading = false
    }

    private func saveTiers() {
        let payload: [[String: Any]] = tiers.compactMap { tier in
            guard let threshold = Int(tier.thresholdText),
                  let bonus = Double(tier.bonusText) else { return nil }
            return ["threshold": threshold, "bonus": bonus]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: ["tiers": payload]) else { return }

        isSaving = true
        error = nil
        Task {
            do {
                struct SaveResponse: Codable { let status: String }
                let _: SaveResponse = try await client.request(.updateBonusTiers, body: data)
                await MainActor.run {
                    isSaving = false
                    withAnimation { showSaved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showSaved = false }
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to save"
                    isSaving = false
                }
            }
        }
    }

    private func deleteTier(at offsets: IndexSet) {
        tiers.remove(atOffsets: offsets)
    }
}

struct EditableTier: Identifiable {
    let id = UUID()
    var thresholdText: String
    var bonusText: String

    init(threshold: Int, bonus: Double) {
        self.thresholdText = "\(threshold)"
        self.bonusText = String(format: "%.2f", bonus)
    }
}
