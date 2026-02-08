import SwiftUI

struct WorkersListView: View {
    @State private var viewModel = WorkersViewModel()
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter bar
                VStack(spacing: AppTheme.Spacing.sm) {
                    // Source segmented control
                    sourceSegment

                    // Search
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                        TextField("Search workers...", text: $viewModel.searchText)
                            .font(AppTheme.Typography.body)

                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.backgroundPrimary)

                // Worker list
                if viewModel.filteredWorkers.isEmpty {
                    EmptyStateView(
                        iconName: "person.2",
                        title: "No Workers Found",
                        message: "No workers match your current filters.",
                        actionTitle: "Add Worker"
                    ) {
                        showAddSheet = true
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredWorkers) { worker in
                            NavigationLink {
                                WorkerDetailView(worker: worker, viewModel: viewModel)
                            } label: {
                                workerRow(worker)
                            }
                            .listRowInsets(EdgeInsets(
                                top: AppTheme.Spacing.xs,
                                leading: AppTheme.Spacing.md,
                                bottom: AppTheme.Spacing.xs,
                                trailing: AppTheme.Spacing.md
                            ))
                        }
                    }
                    .listStyle(.plain)
                    .animation(AppTheme.Animation.standard, value: viewModel.selectedSource)
                    .animation(AppTheme.Animation.standard, value: viewModel.sortOption)
                }
            }
            .background(AppTheme.Colors.backgroundPrimary)
            .navigationTitle("Workers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $viewModel.sortOption) {
                            ForEach(WorkerSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .foregroundStyle(AppTheme.Colors.primaryFallback)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppTheme.Colors.primaryFallback)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddWorkerSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Source Segment

    private var sourceSegment: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            segmentButton(title: "All", isSelected: viewModel.selectedSource == nil) {
                viewModel.selectedSource = nil
            }
            ForEach(PaymentSource.allCases) { source in
                segmentButton(title: source.rawValue, isSelected: viewModel.selectedSource == source) {
                    viewModel.selectedSource = viewModel.selectedSource == source ? nil : source
                }
            }
        }
        .padding(AppTheme.Spacing.xxs)
        .background(AppTheme.Colors.backgroundSecondary)
        .clipShape(Capsule())
    }

    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(AppTheme.Animation.spring) { action() }
        }) {
            Text(title)
                .font(AppTheme.Typography.captionBold)
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(isSelected ? AppTheme.Colors.primaryFallback : .clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Worker Row

    private func workerRow(_ worker: Worker) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            AvatarView(
                initials: worker.initials,
                color: worker.avatarColor,
                size: 48
            )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(worker.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                HStack(spacing: AppTheme.Spacing.xs) {
                    SourceBadge(source: worker.paymentSource, style: .pill)

                    Text(worker.isActive ? "Active" : "Inactive")
                        .font(AppTheme.Typography.micro)
                        .fontWeight(.semibold)
                        .foregroundStyle(worker.isActive ? AppTheme.Colors.positive : AppTheme.Colors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (worker.isActive ? AppTheme.Colors.positive : AppTheme.Colors.textTertiary).opacity(0.12)
                        )
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Text(worker.totalEarnings.eurFormatted)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WorkersListView()
}
