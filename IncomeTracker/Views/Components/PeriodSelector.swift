import SwiftUI

struct PeriodSelector: View {
    @Binding var selected: TimePeriod
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            ForEach(TimePeriod.allCases) { period in
                periodButton(for: period)
            }
        }
        .padding(AppTheme.Spacing.xxs)
        .background(AppTheme.Colors.backgroundSecondary)
        .clipShape(Capsule())
    }

    private func periodButton(for period: TimePeriod) -> some View {
        Button {
            var t = Transaction()
            t.animation = nil
            withTransaction(t) {
                selected = period
            }
        } label: {
            periodLabel(for: period)
        }
        .buttonStyle(.plain)
        .animation(AppTheme.Animation.spring, value: selected)
        .accessibilityLabel(period.displayName)
        .accessibilityAddTraits(selected == period ? .isSelected : [])
    }

    private func periodLabel(for period: TimePeriod) -> some View {
        let isSelected = selected == period
        return Text(period.rawValue)
            .font(AppTheme.Typography.captionBold)
            .foregroundStyle(isSelected ? .white : AppTheme.Colors.textSecondary)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background {
                if isSelected {
                    Capsule()
                        .fill(AppTheme.Colors.primaryFallback)
                        .matchedGeometryEffect(id: "period_pill", in: namespace)
                }
            }
    }
}

struct PeriodSelector_Previews: PreviewProvider {
    struct Preview: View {
        @State private var period: TimePeriod = .monthly
        var body: some View {
            PeriodSelector(selected: $period)
                .padding()
        }
    }
    static var previews: some View {
        Preview()
    }
}
