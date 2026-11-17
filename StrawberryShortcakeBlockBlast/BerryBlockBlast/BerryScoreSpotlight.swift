import SwiftUI

// Original Strawberry Village styling for a classic block-puzzle score chase.
// The gentle glow is continuous. Never use rapid flashing / stroboscopic effects.
struct BerryClassicScoreView: View {
    let score: Int
    let best: Int
    let combo: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowing = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text("🍓")
                    Text("BERRY CLASSIC SCORE")
                        .tracking(1.1)
                }
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate)

                Text(score.formatted())
                    .font(.system(size: 43, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.57)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BerryStyle.strawberry, Color(red: 1, green: 0.36, blue: 0.48),
                                     Color(red: 0.92, green: 0.50, blue: 0.14)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: BerryStyle.strawberry.opacity(glowing ? 0.53 : 0.25),
                            radius: glowing && !reduceMotion ? 13 : 4)
                    .scaleEffect(glowing && !reduceMotion ? 1.028 : 1.0, anchor: .leading)
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .spring(response: 0.32), value: score)
                    .accessibilityLabel("Score \(score)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Label("BEST", systemImage: "crown.fill")
                    .foregroundStyle(Color(red: 0.76, green: 0.43, blue: 0.08))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                Text(best.formatted())
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("COMBO ×\(max(1, combo))")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(BerryStyle.strawberry)
            }
            .frame(minWidth: 76, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: 79)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: [.white, Color(red: 1, green: 0.91, blue: 0.91),
                             Color(red: 1, green: 0.98, blue: 0.87)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(RoundedRectangle(cornerRadius: 20)
            .strokeBorder(BerryStyle.strawberry.opacity(0.29), lineWidth: 2))
        .shadow(color: BerryStyle.strawberry.opacity(0.17), radius: 9, y: 4)
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
        }
        .onDisappear { glowing = false }
    }
}

struct BerryNewBestBanner: View {
    let score: Int

    var body: some View {
        VStack(spacing: 6) {
            Text("✨ 🍓 👑 🍓 ✨")
                .font(.system(size: 24))
            Text("NEW BERRY BEST!")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(score.formatted())
                .font(.system(size: 42, weight: .black, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .foregroundStyle(
            LinearGradient(
                colors: [BerryStyle.strawberry, Color(red: 0.89, green: 0.51, blue: 0.13)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .frame(maxWidth: 285)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24)
            .strokeBorder(.white.opacity(0.95), lineWidth: 3))
        .shadow(color: BerryStyle.strawberry.opacity(0.38), radius: 20, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("New Berry best, \(score) points")
    }
}
