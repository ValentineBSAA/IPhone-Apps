import SwiftUI

/// First-launch acknowledgement, not an iOS permission substitute.
/// Camera and device authentication are requested only when their tools are used.
struct WelcomeAndPrivacyView: View {
    @Binding var acknowledged: Bool
    @State private var understands = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    Image("00_App_Icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 82, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Welcome to")
                            .font(.subheadline)
                            .foregroundStyle(Color.potsSecondary)
                        Text("POTS & Posies")
                            .font(.title.bold())
                            .foregroundStyle(Color.potsTeal)
                        Text("A gentle place for your daily notes")
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 12)

                Text("Before we begin")
                    .font(.title2.bold())

                GlassCard {
                    VStack(alignment: .leading, spacing: 15) {
                        information("Your information stays on this iPhone",
                                    icon: "lock.shield",
                                    detail: "No account, cloud upload or Apple Watch is needed. Entries are kept in local device storage. Backup and export are not available yet, so don't store irreplaceable records during this test.")
                        Divider()
                        information("This is a personal wellness journal",
                                    icon: "heart.text.square",
                                    detail: "POTS & Posies does not diagnose POTS, replace professional care or provide emergency monitoring. Dates without records are unknown, not symptom-free.")
                        Divider()
                        information("You control optional permissions",
                                    icon: "hand.raised",
                                    detail: "Manual tracking works without camera or Face ID. Camera access is requested only if you start Camera Pulse Beta; Face ID or passcode is used only if you enable private Journal Lock.")
                        Divider()
                        information("Camera Pulse is experimental",
                                    icon: "camera",
                                    detail: "A flashlight and fingertip may estimate a resting pulse. The result is not medically validated for POTS. No camera images are stored, and estimates enter the journal only when you choose Save.")
                    }
                }

                Toggle(isOn: $understands) {
                    Text("I understand how my records and optional features work.")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(.potsTeal)
                .padding(15)
                .background(Color.potsSurfaceMuted,
                            in: RoundedRectangle(cornerRadius: 18))

                Button {
                    guard understands else { return }
                    acknowledged = true
                } label: {
                    Label("Continue to POTS & Posies", systemImage: "heart.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.potsButtonFill)
                .disabled(!understands)
                .accessibilityHint("Opens the app. You can revisit privacy information in More.")

                Text("Permissions are never required for basic logging. You can review privacy information again from More.")
                    .font(.footnote)
                    .foregroundStyle(Color.potsSecondary)
            }
            .padding(20)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(Color.potsBackground.ignoresSafeArea())
    }

    private func information(_ title: String, icon: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.potsTeal)
                .frame(width: 31)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.potsSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
