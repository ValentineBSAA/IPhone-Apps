import SwiftUI

/// An exclusively OUTSIDE-the-grid frame. Its entire painted area is
/// contained by the 8pt decorative inset around BerryBoardWindowTrackingView.
/// Unlike the old floral PNG, no layer can reach the playable cells.
struct BerryBlossomEdgeFrame: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 23, style: .continuous)
            .fill(LinearGradient(
                colors: [
                    Color(red: 1, green: 0.92, blue: 0.97),
                    Color(red: 0.98, green: 0.53, blue: 0.75),
                    Color(red: 0.74, green: 0.45, blue: 0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            // The seven-point highlight is always within the outer 8pt
            // decorative gutter, never across the game's touch tracker.
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [
                            .white.opacity(0.96),
                            Color(red: 1, green: 0.67, blue: 0.89),
                            Color(red: 0.67, green: 0.34, blue: 0.63)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 7
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.65), lineWidth: 1)
                    .padding(1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
