import SwiftUI

// Shimmer loading placeholder for future async data loading states

struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.15),
                        Color.gray.opacity(0.25),
                        Color.gray.opacity(0.15)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .mask {
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .fill(.white)
                    .overlay {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.5), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * 0.4)
                                .offset(x: isAnimating ? geo.size.width : -geo.size.width * 0.4)
                        }
                    }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// Pre-built skeleton layouts
struct SkeletonTransactionRow: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            SkeletonView(width: 44, height: 44)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                SkeletonView(width: 120, height: 14)
                SkeletonView(width: 80, height: 10)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                SkeletonView(width: 70, height: 14)
                SkeletonView(width: 50, height: 10)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SkeletonView(width: 80, height: 12)
            SkeletonView(width: 130, height: 28)
            SkeletonView(width: 60, height: 10)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct SkeletonView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SkeletonCard()
            SkeletonTransactionRow()
            SkeletonTransactionRow()
            SkeletonTransactionRow()
        }
        .padding()
    }
}
