import SwiftUI

// MARK: - App Theme
// Central design system inspired by Stripe/Shopify aesthetics.
// All spacing follows a 4pt base grid; colors adapt to light/dark mode.

struct AppTheme {

    // MARK: - Colors

    struct Colors {
        // Primary brand — Stripe-inspired indigo-purple
        static let primary = Color("AccentColor", bundle: nil)
        static let primaryFallback = Color(red: 99/255, green: 91/255, blue: 255/255) // #635BFF

        // Source-specific
        static let paysafe = Color(red: 0/255, green: 156/255, blue: 222/255)    // PaySafe brand blue
        static let paypal = Color(red: 0/255, green: 48/255, blue: 135/255)      // PayPal brand navy
        static let paypalLight = Color(red: 0/255, green: 112/255, blue: 201/255) // PayPal secondary

        // Semantic
        static let positive = Color(red: 16/255, green: 185/255, blue: 129/255)  // Green for income/success
        static let negative = Color(red: 239/255, green: 68/255, blue: 68/255)   // Red for failed/loss
        static let warning = Color(red: 245/255, green: 158/255, blue: 11/255)   // Orange for pending

        // Neutrals
        static let backgroundPrimary = Color(.systemBackground)
        static let backgroundSecondary = Color(.secondarySystemBackground)
        static let backgroundTertiary = Color(.tertiarySystemBackground)
        static let cardBackground = Color(.secondarySystemBackground)

        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)

        static let separator = Color(.separator)
        static let border = Color(.systemGray4)
    }

    // MARK: - Typography

    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let heroNumber = Font.system(size: 42, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .medium)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionBold = Font.system(size: 12, weight: .semibold)
        static let micro = Font.system(size: 10, weight: .medium)
    }

    // MARK: - Corner Radius

    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let pill: CGFloat = 100
    }

    // MARK: - Spacing (4pt grid)

    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Shadows

    struct Shadow {
        static let small = ShadowStyle(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        static let large = ShadowStyle(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Animation

    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
    }
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .stroke(AppTheme.Colors.border.opacity(0.3), lineWidth: 0.5)
                }
            }
            .shadow(
                color: colorScheme == .light ? .black.opacity(0.04) : .clear,
                radius: 8, x: 0, y: 4
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Chart Card Style (non-clipping for axis labels)

struct ChartCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(.bottom, AppTheme.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .stroke(AppTheme.Colors.border.opacity(0.3), lineWidth: 0.5)
                }
            }
            .shadow(
                color: colorScheme == .light ? .black.opacity(0.04) : .clear,
                radius: 8, x: 0, y: 4
            )
    }
}

extension View {
    func chartCardStyle() -> some View {
        modifier(ChartCardStyle())
    }
}

// MARK: - Preview

struct AppTheme_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("App Theme Preview")
                    .font(AppTheme.Typography.largeTitle)

                HStack(spacing: AppTheme.Spacing.xs) {
                    colorSwatch("Primary", AppTheme.Colors.primaryFallback)
                    colorSwatch("PaySafe", AppTheme.Colors.paysafe)
                    colorSwatch("PayPal", AppTheme.Colors.paypal)
                }

                HStack(spacing: AppTheme.Spacing.xs) {
                    colorSwatch("Positive", AppTheme.Colors.positive)
                    colorSwatch("Warning", AppTheme.Colors.warning)
                    colorSwatch("Negative", AppTheme.Colors.negative)
                }

                Text("€12,345.67")
                    .font(AppTheme.Typography.heroNumber)

                Text("Sample Card")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .cardStyle()
            }
            .padding(AppTheme.Spacing.md)
        }
    }
}

private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: AppTheme.Spacing.xxs) {
        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
            .fill(color)
            .frame(width: 60, height: 40)
        Text(name)
            .font(AppTheme.Typography.caption)
    }
}
