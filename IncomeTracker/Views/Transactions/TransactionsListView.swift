import SwiftUI

struct TransactionsListView: View {
    @State private var viewModel = TransactionsViewModel()
    @State private var selectedTransaction: Transaction?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sticky filter bar
                VStack(spacing: AppTheme.Spacing.sm) {
                    PeriodSelector(selected: $viewModel.selectedPeriod)
                    TransactionFilterBar(
                        selectedSource: $viewModel.selectedSource,
                        selectedStatus: $viewModel.selectedStatus,
                        searchText: $viewModel.searchText
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.backgroundPrimary)

                // Transaction list
                if viewModel.filteredTransactions.isEmpty {
                    EmptyStateView(
                        iconName: "magnifyingglass",
                        title: "No Results",
                        message: "No transactions match your current filters. Try adjusting your search or filters.",
                        actionTitle: "Clear Filters"
                    ) {
                        viewModel.clearFilters()
                    }
                } else {
                    List {
                        ForEach(viewModel.groupedTransactions, id: \.key) { group in
                            Section {
                                ForEach(group.transactions) { transaction in
                                    TransactionRow(transaction: transaction)
                                        .listRowInsets(EdgeInsets(
                                            top: AppTheme.Spacing.xxs,
                                            leading: AppTheme.Spacing.md,
                                            bottom: AppTheme.Spacing.xxs,
                                            trailing: AppTheme.Spacing.md
                                        ))
                                        .listRowSeparator(.hidden)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedTransaction = transaction
                                        }
                                }
                            } header: {
                                Text(group.header)
                                    .font(AppTheme.Typography.captionBold)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .animation(AppTheme.Animation.standard, value: viewModel.selectedSource)
                    .animation(AppTheme.Animation.standard, value: viewModel.selectedStatus)
                }

                // Summary footer
                if !viewModel.filteredTransactions.isEmpty {
                    summaryFooter
                }
            }
            .background(AppTheme.Colors.backgroundPrimary)
            .navigationTitle("Transactions")
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailSheet(transaction: transaction)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var summaryFooter: some View {
        HStack {
            Text("Showing \(viewModel.filteredCount) transactions")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            Text(viewModel.totalFilteredAmount.eurFormatted)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text("total")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

#Preview {
    TransactionsListView()
}
