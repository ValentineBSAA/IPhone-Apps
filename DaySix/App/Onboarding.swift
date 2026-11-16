import SwiftUI

struct DaySixOnboardingView: View {
    let completed: () -> Void
    @State private var step = 0

    private let pages: [(symbol: String, title: String, message: String)] = [
        ("checkmark.shield.fill", "Welcome to DaySix",
         "DaySix monitors its own signature as well as your other apps. It checks for day-six renewal and never mistakes an attempt for a successful refresh."),
        ("iphone.gen3.radiowaves.left.and.right", "Connect your signer",
         "SideStore handles signing. To renew DaySix itself, install or reinstall DaySix through SideStore so it appears under SideStore's My Apps. DaySix never requests your Apple password."),
        ("clock.arrow.2.circlepath", "Build the automation",
         "In Shortcuts, create a daily Run Immediately automation. Check DaySix's due flag, then run SideStore's Refresh All Apps only when needed."),
        ("square.stack.3d.up.fill", "Add and verify",
         "DaySix reads its own provisioning expiration automatically. Add other apps manually, and confirm those apps' renewed dates after SideStore succeeds.")
    ]

    var body: some View {
        ZStack {
            DS.ink.ignoresSafeArea()
            RadialGradient(colors: [DS.violet.opacity(0.22), .clear],
                           center: .top, startRadius: 20, endRadius: 480).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 7) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index <= step ? DS.mint : .white.opacity(0.16))
                            .frame(height: 5)
                    }
                }
                .padding(.top, 28)

                Spacer()
                Image(systemName: pages[step].symbol)
                    .font(.system(size: 66, weight: .light))
                    .foregroundStyle(DS.gradient)
                    .frame(width: 112, height: 112)
                    .background(DS.card, in: RoundedRectangle(cornerRadius: 30))

                Text("DAY SIX  ·  \(step + 1) / \(pages.count)")
                    .tracking(2.3).font(.caption.bold()).foregroundStyle(DS.mint)

                Text(pages[step].title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)

                Text(pages[step].message)
                    .font(.body).foregroundStyle(DS.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if step == 1 {
                    Link("Read SideStore setup guide",
                         destination: URL(string: "https://docs.sidestore.io/docs/installation/install.html")!)
                        .font(.subheadline.bold()).foregroundStyle(DS.mint)
                }

                if step == 2 {
                    Text("More → Copy Setup Steps has the full Shortcuts recipe.")
                        .font(.footnote).foregroundStyle(DS.amber)
                }

                Spacer()
                GlowButton(title: step == pages.count - 1 ? "Open DaySix" : "Continue",
                           symbol: step == pages.count - 1 ? "checkmark" : "arrow.right") {
                    if step == pages.count - 1 {
                        completed()
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) { step += 1 }
                    }
                }
                if step < pages.count - 1 {
                    Button("Skip setup guide") { completed() }
                        .font(.subheadline).foregroundStyle(DS.muted)
                        .frame(maxWidth: .infinity).padding(.bottom, 8)
                }
            }
            .padding(25)
        }
        .preferredColorScheme(.dark)
    }
}
