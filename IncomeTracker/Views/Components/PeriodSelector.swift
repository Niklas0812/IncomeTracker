import SwiftUI

struct PeriodSelector: View {
    @Binding var selected: TimePeriod

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            ForEach(TimePeriod.allCases) { period in
                Button {
                    withAnimation(AppTheme.Animation.spring) {
                        selected = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(AppTheme.Typography.captionBold)
                        .foregroundStyle(selected == period ? .white : AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background {
                            if selected == period {
                                Capsule()
                                    .fill(AppTheme.Colors.primaryFallback)
                                    .matchedGeometryEffect(id: "period_pill", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selected)
                .accessibilityLabel(period.displayName)
                .accessibilityAddTraits(selected == period ? .isSelected : [])
            }
        }
        .padding(AppTheme.Spacing.xxs)
        .background(AppTheme.Colors.backgroundSecondary)
        .clipShape(Capsule())
    }

    @Namespace private var namespace
}

#Preview {
    struct Preview: View {
        @State private var period: TimePeriod = .monthly
        var body: some View {
            PeriodSelector(selected: $period)
                .padding()
        }
    }
    return Preview()
}
