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


/// Shared, couch-readable two-column navigation card. Keeping this in one
/// place makes Collection, Village, modes, and Boutique feel like one app.
struct BerryGridNavigationTile: View {
    let title: String
    let detail: String
    let art: String
    var caption: String? = nil
    var selected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                BerryIcon(name: art, size: 68)
                    .frame(width: 72, height: 72)
                    .background(BerryStyle.softPink.opacity(0.65),
                                in: RoundedRectangle(cornerRadius: 18))
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Text(detail)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if let caption {
                    Text(caption)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(selected ? BerryStyle.leaf : BerryStyle.strawberry)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding(.horizontal, 7)
            .padding(.vertical, 10)
            .background(selected ? BerryStyle.softPink : .white,
                        in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(BerryStyle.strawberry.opacity(selected ? 0.65 : 0.28),
                                  lineWidth: selected ? 2 : 1.3)
            }
            .shadow(color: BerryStyle.strawberry.opacity(0.08), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title + ". " + detail + (caption.map { ". " + $0 } ?? ""))
    }
}

/// Compact stat card for records, personal milestones and inventories.
/// Data remains real SwiftUI content; no fake text embedded into art.
struct BerryGridInfoTile: View {
    let title: String
    let detail: String
    let art: String
    var value: String? = nil
    var complete: Bool = false

    var body: some View {
        VStack(spacing: 7) {
            BerryIcon(name: art, size: 55)
                .frame(height: 60)
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            if let value {
                Text(value)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(BerryStyle.candyNumberGradient)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            Text(detail)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(BerryStyle.chocolate.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 151)
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19)
            .strokeBorder(BerryStyle.strawberry.opacity(0.25), lineWidth: 1.2))
    }
}
