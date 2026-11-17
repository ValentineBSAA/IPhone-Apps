import SwiftUI

/// A light, bounded decorative overlay. No physics, no interaction, no impact on the engine.
struct BerryStrawberryRain: View {
    @State private var falling = false
    private let offsets: [CGFloat] = [0.08, 0.22, 0.38, 0.51, 0.63, 0.78, 0.91,
                                     0.15, 0.32, 0.57, 0.72, 0.86]
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<offsets.count, id: \.self) { index in
                Text(index % 3 == 0 ? "🌸" : "🍓")
                    .font(.system(size: index % 2 == 0 ? 18 : 13))
                    .opacity(falling ? 0 : 0.85)
                    .position(x: geo.size.width * offsets[index],
                              y: falling ? geo.size.height + 20 : -12 - CGFloat(index % 4) * 28)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.05)) { falling = true }
        }
        .accessibilityHidden(true)
    }
}
