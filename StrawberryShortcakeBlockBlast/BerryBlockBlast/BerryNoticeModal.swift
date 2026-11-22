import SwiftUI

/// A real top-layer, game-controlled modal dialog. Replaces the game's own
/// default system-looking alerts, not iOS Notification Center or lock-screen
/// notifications (whose appearance is controlled by iOS).
struct BerryNoticeModal: View {
    let title: String
    let message: String
    var kind: BerryNoticeKind = .information
    let primaryTitle: String
    let primaryAction: () -> Void
    var secondaryTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil
    var preview = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.43)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Image("Dev_Notification_Test_Berry_Bell")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 65, height: 65)
                        .accessibilityHidden(true)
                    Text(kind.rawValue.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(kind.accent)
                    Text(title)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate)
                        .multilineTextAlignment(.center)
                    Text(message)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(BerryStyle.chocolate)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if preview {
                        Text("SAFE PREVIEW • No game data changes")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(BerryStyle.leaf)
                    }

                    Button(action: primaryAction) {
                        Text(primaryTitle)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BerryStyle.strawberry)
                    .accessibilityIdentifier("berry.notice.modal.primary")

                    if let secondaryTitle, let secondaryAction {
                        Button(action: secondaryAction) {
                            Text(secondaryTitle)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .tint(BerryStyle.chocolate)
                        .accessibilityIdentifier("berry.notice.modal.cancel")
                    }
                }
                .padding(20)
                .frame(maxWidth: min(340, geometry.size.width - 38))
                .background(
                    LinearGradient(colors: [
                        .white, BerryStyle.cream, BerryStyle.softPink
                    ], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 25)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(BerryStyle.strawberry.opacity(0.76), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.2), radius: 18, y: 9)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("berry.notice.modal")
                .padding(.vertical, 18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(edges: .bottom)
        .zIndex(100)
    }
}
