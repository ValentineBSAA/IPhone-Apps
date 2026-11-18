import SwiftUI

/// Bold, readable timer and score for all four Blitz durations.
struct BerryBlitzHUD: View {
    let timeLeft: Int
    let score: Int
    let best: Int
    let variant: BerryBlitzVariant
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 13) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text(variant.rawValue.uppercased())
                }
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(BerryStyle.chocolate.opacity(0.76))
                Text(String(format: "%01d:%02d", timeLeft / 60, timeLeft % 60))
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(timeLeft <= 10 ? BerryStyle.strawberry :
                        Color(red: 0.70, green: 0.28, blue: 0.48))
                    .shadow(color: BerryStyle.strawberry.opacity(timeLeft <= 10 ? 0.42 : 0.16), radius: 5)
                    .animation(reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled ? nil : .easeInOut(duration: 0.18), value: timeLeft)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 4) {
                Text("⚡ SCORE")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(BerryStyle.strawberry)
                BerryCandyNumber(value: score.formatted(), size: 30, label: "Blitz Score")
                    .contentTransition(.numericText())
                BerryCandyNumber(value: "🏆 BEST \(best.formatted())", size: 11,
                                 label: "Blitz Best")
            }
        }
        .padding(.horizontal, 17)
        .frame(height: 87)
        .background(
            LinearGradient(colors: [Color(red: 1, green: 0.91, blue: 0.86), .white,
                                    Color(red: 1, green: 0.86, blue: 0.93)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(RoundedRectangle(cornerRadius: 22)
            .strokeBorder(timeLeft <= 10 ? BerryStyle.strawberry : .white, lineWidth: 2))
        .shadow(color: BerryStyle.strawberry.opacity(0.12), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(variant.rawValue), \(timeLeft) seconds remaining, \(score) points, personal best \(best)")
    }
}
