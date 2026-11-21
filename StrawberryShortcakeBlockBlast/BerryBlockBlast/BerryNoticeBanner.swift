import SwiftUI

/// Reusable in-game notice, not a replacement for iOS permission prompts,
/// confirmation dialogs, or notifications outside the app.
enum BerryNoticeKind: String, CaseIterable, Identifiable {
    case success = "Success"
    case information = "Information"
    case caution = "Attention"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .information: return "sparkles"
        case .caution: return "exclamationmark.circle.fill"
        }
    }

    var accent: Color {
        switch self {
        case .success: return BerryStyle.leaf
        case .information: return BerryStyle.strawberry
        case .caution: return Color(red: 0.67, green: 0.31, blue: 0.19)
        }
    }
}

/// Uses the actual approved Strawberry currency artwork and the game's own
/// colors. Presentation-only: never modifies a user's wallet or save.
struct BerryNoticeBanner: View {
    let message: String
    var kind: BerryNoticeKind = .information

    var body: some View {
        HStack(spacing: 10) {
            Image("Strawberry_Currency")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Label(kind.rawValue, systemImage: kind.icon)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(kind.accent)
                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(BerryStyle.chocolate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [.white, BerryStyle.cream],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(BerryStyle.strawberry.opacity(0.62), lineWidth: 1.5)
        }
        .shadow(color: BerryStyle.strawberry.opacity(0.16), radius: 7, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.rawValue): \(message)")
        .accessibilityIdentifier("berry.notice.\(kind.id.lowercased())")
    }
}
