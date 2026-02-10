import SwiftUI

struct WorkersListView: View {
    @Binding var navigateToWorkerId: Int?
    @StateObject private var viewModel = WorkersViewModel()
    @State private var showAddSheet = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                // Filter bar
                VStack(spacing: AppTheme.Spacing.sm) {
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
                if viewModel.filteredWorkers.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        iconName: "person.2",
                        title: "No Workers Found",
                        message: "No workers match your current filters.",
                        actionTitle: "Add Worker"
                    ) {
                        showAddSheet = true
                    }
                } else if viewModel.filteredWorkers.isEmpty && viewModel.isLoading {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonView()
                                .frame(height: 60)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                } else {
                    List {
                        ForEach(viewModel.filteredWorkers) { worker in
                            NavigationLink(value: worker.id) {
                                workerRow(worker)
                            }
                            .listRowInsets(EdgeInsets(
                                top: AppTheme.Spacing.xs,
                                leading: AppTheme.Spacing.md,
                                bottom: AppTheme.Spacing.xs,
                                trailing: AppTheme.Spacing.md
                            ))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteWorker(userId: worker.id) { _ in }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { viewModel.fetchWorkers() }
                }
            }
            .background(AppTheme.Colors.backgroundPrimary)
            .navigationTitle("Workers")
            .navigationDestination(for: Int.self) { workerId in
                if let worker = viewModel.workers.first(where: { $0.id == workerId }) {
                    WorkerDetailView(worker: worker, viewModel: viewModel)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showAddSheet = true
                        } label: {
                            Label("Add Worker", systemImage: "plus")
                        }
                        Divider()
                        Menu("Sort by") {
                            ForEach(WorkerSortOption.allCases) { option in
                                Button {
                                    viewModel.sortOption = option
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        if viewModel.sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(AppTheme.Colors.primaryFallback)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddWorkerSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: navigateToWorkerId) { workerId in
                if let workerId {
                    attemptNavigateToWorker(workerId)
                }
            }
            .onChange(of: viewModel.isLoading) { isLoading in
                if !isLoading, let workerId = navigateToWorkerId {
                    attemptNavigateToWorker(workerId)
                }
            }
        }
    }

    // MARK: - Navigation

    private func attemptNavigateToWorker(_ workerId: Int) {
        guard viewModel.workers.contains(where: { $0.id == workerId }) else { return }
        path = NavigationPath()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            path.append(workerId)
            navigateToWorkerId = nil
        }
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

                    if let rate = worker.hourlyRate {
                        Text("$\(String(format: "%.2f", rate))/hr")
                            .font(AppTheme.Typography.micro)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
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

struct WorkersListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkersListView(navigateToWorkerId: .constant(nil))
    }
}
