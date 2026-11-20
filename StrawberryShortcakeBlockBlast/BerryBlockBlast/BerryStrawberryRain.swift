import SwiftUI

/// Board-confined, input-transparent strawberry burst. Tiny particles tumble
/// outward, drift down and fade smoothly. This is visual-only: never touches
/// combo, game scores, rewards, or the move engine.
struct BerryStrawberryRain: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var firstBurst = false
    @State private var secondBurst = false

    private let count = 44

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    let secondary = index >= 30
                    let active = secondary ? secondBurst : firstBurst
                    let particleIndex = secondary ? index - 30 : index
                    let angle = Double((particleIndex * 137 + (secondary ? 35 : 0)) % 360)
                        * .pi / 180
                    let radius = CGFloat(0.25 + Double((index * 23) % 71) / 100)
                        * min(geo.size.width, geo.size.height)
                    let travel = active ? CGFloat(1) : CGFloat(0)
                    let arcX = CGFloat(cos(angle)) * radius * travel
                    let arcY = CGFloat(sin(angle)) * radius * travel * 0.70 +
                               (active ? radius * 0.24 : 0)
                    Text("🍓")
                        .font(.system(size: CGFloat(11 + (index * 7) % 12)))
                        .scaleEffect(active ? 0.72 : 0.35)
                        .rotationEffect(.degrees(active ? angle * 1.4 : 0))
                        .opacity(active ? 0 : 0.96)
                        .position(x: geo.size.width / 2 + arcX,
                                  y: geo.size.height * 0.46 + arcY)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.28)) {
                    firstBurst = true
                    secondBurst = true
                }
            } else {
                withAnimation(.easeOut(duration: 2.55)) {
                    firstBurst = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
                    withAnimation(.easeOut(duration: 2.08)) {
                        secondBurst = true
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
