import SwiftUI

struct TransactionFilterBar: View {
    @Binding var selectedSource: PaymentSource?
    @Binding var searchText: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Search
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                TextField("Search worker...", text: $searchText)
                    .font(AppTheme.Typography.body)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
            }
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))

            // Source chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    FilterChip(
                        title: "All Sources",
                        isSelected: selectedSource == nil,
                        color: AppTheme.Colors.primaryFallback
                    ) {
                        withAnimation(AppTheme.Animation.quick) { selectedSource = nil }
                    }

                    ForEach(PaymentSource.allCases) { source in
                        FilterChip(
                            title: source.rawValue,
                            isSelected: selectedSource == source,
                            color: source.color
                        ) {
                            withAnimation(AppTheme.Animation.quick) {
                                selectedSource = selectedSource == source ? nil : source
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.captionBold)
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(isSelected ? color : AppTheme.Colors.backgroundSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct TransactionFilterBar_Previews: PreviewProvider {
    struct Preview: View {
        @State private var source: PaymentSource?
        @State private var search = ""
        var body: some View {
            TransactionFilterBar(
                selectedSource: $source,
                searchText: $search
            )
            .padding()
        }
    }
    static var previews: some View {
        Preview()
    }
}
