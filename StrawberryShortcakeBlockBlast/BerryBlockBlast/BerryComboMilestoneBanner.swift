import SwiftUI
import UIKit

/// View-only celebration: never changes combo state, rewards or placement.
/// Artwork is optional until the approved Build 4 PNG bundle is committed.
struct BerryComboMilestoneBanner: View {
    let milestone: Int

    var body: some View {
        VStack(spacing: 3) {
            if let art = UIImage(named: "Combo_\(milestone)") {
                Image(uiImage: art)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 87)
            } else {
                Text("🍓 ✨ COMBO ×\(milestone)! ✨ 🍓")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .shadow(color: Color(red: 0.64, green: 0.04, blue: 0.30),
                            radius: 2, y: 2)
            }
            Text("Berry Bonanza!")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [
                Color(red: 1, green: 0.34, blue: 0.52),
                Color(red: 0.68, green: 0.09, blue: 0.44)
            ], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(RoundedRectangle(cornerRadius: 22)
            .strokeBorder(.white.opacity(0.96), lineWidth: 2))
        .shadow(color: BerryStyle.strawberry.opacity(0.36), radius: 10, y: 5)
        .accessibilityLabel("Combo \(milestone)! Berry Bonanza!")
    }
}
