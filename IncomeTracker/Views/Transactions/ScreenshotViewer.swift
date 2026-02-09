import SwiftUI

struct ScreenshotViewer: View {
    let filename: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0

    private var imageURL: URL? {
        guard var url = APIClient.shared.screenshotURL(filename: filename) else { return nil }
        return url
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView([.horizontal, .vertical]) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: geo.size.width, height: geo.size.height)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: geo.size.width)
                                .scaleEffect(scale)
                                .gesture(
                                    MagnifyGesture()
                                        .onChanged { value in
                                            scale = value.magnification
                                        }
                                        .onEnded { _ in
                                            withAnimation { scale = max(1, scale) }
                                        }
                                )
                        case .failure:
                            VStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: 48))
                                    .foregroundStyle(AppTheme.Colors.textTertiary)
                                Text("Failed to load screenshot")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("Screenshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
