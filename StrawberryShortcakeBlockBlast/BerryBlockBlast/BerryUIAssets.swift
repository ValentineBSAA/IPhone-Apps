import SwiftUI

/// Every Berry icon is bundled in Assets.xcassets for offline use.
struct BerryIcon: View {
    let name: String
    var size: CGFloat = 38
    var body: some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

enum BerryNumbers {
    /// Keep small values exact; compact only when the available UI needs it.
    static func compact(_ value: Int) -> String {
        let amount = Double(value)
        for (threshold, suffix) in [(1e12, "T"), (1e9, "B"), (1e6, "M"), (1e3, "K")] {
            if amount >= threshold {
                let scaled = amount / threshold
                return String(format: scaled >= 100 ? "%.0f%@" : scaled >= 10 ? "%.1f%@" : "%.2f%@", scaled, suffix)
                    .replacingOccurrences(of: ".00", with: "")
                    .replacingOccurrences(of: ".0", with: "")
            }
        }
        return value.formatted()
    }
}

struct BerryWalletPill: View {
    let berries: Int
    var body: some View {
        HStack(spacing: 5) {
            Text("🍓")
            Text(BerryNumbers.compact(berries))
                .font(.system(size: 14, weight: .black, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(BerryStyle.chocolate)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.white.opacity(0.94), in: Capsule())
        .accessibilityLabel("Berry wallet: \(berries) strawberries")
    }
}
