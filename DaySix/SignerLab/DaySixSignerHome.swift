// DaySix Signer Lab simplified entry UI.
// Embedded into the pinned SideStore TabBarController.swift at build time.
// This view uses the REAL SideStore install and refresh actions from the
// controller that embeds it. No separate installer or credentials are needed.
private struct DaySixSignerHomeView: View {
    let importIPA: () -> Void
    let showApps: () -> Void
    let refreshApps: () -> Void
    let openSettings: () -> Void
    let openSources: () -> Void

    private let ink = Color(red: 0.026, green: 0.035, blue: 0.08)
    private let surface = Color(red: 0.074, green: 0.092, blue: 0.16)
    private let mint = Color(red: 0.26, green: 0.95, blue: 0.79)
    private let violet = Color(red: 0.62, green: 0.52, blue: 0.99)
    private let subdued = Color(red: 0.67, green: 0.75, blue: 0.84)

    private var accent: LinearGradient {
        LinearGradient(colors: [mint, violet],
                       startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        ZStack {
            ink.ignoresSafeArea()
            RadialGradient(colors: [violet.opacity(0.16), .clear],
                           center: .topTrailing,
                           startRadius: 0, endRadius: 420)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DAY SIX")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(mint)

                        Text("Your apps.\nOne place.")
                            .font(.system(size: 35, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Install and manage your apps in one place.")
                            .font(.subheadline)
                            .foregroundStyle(subdued)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.down.on.square.fill")
                                .font(.system(size: 25))
                                .foregroundStyle(mint)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Install an IPA")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("Pick an .ipa file. Review the install before signing.")
                                    .font(.caption)
                                    .foregroundStyle(subdued)
                            }
                        }
                        SwiftUI.Button(action: importIPA) {
                            HStack {
                                Image(systemName: "plus.app.fill")
                                Text("Choose IPA File")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(ink)
                            .padding(.vertical, 17)
                            .padding(.horizontal, 19)
                            .background(accent,
                                        in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens Files, then a signing and installation confirmation for the selected IPA")
                    }
                    .padding(20)
                    .background(surface, in: RoundedRectangle(cornerRadius: 24))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.08))
                    }

                    VStack(spacing: 11) {
                        quickAction(
                            title: "My Apps",
                            detail: "See installed apps and signing dates.",
                            symbol: "square.stack.3d.up.fill",
                            accent: mint,
                            action: showApps)

                        quickAction(
                            title: "Refresh My Apps",
                            detail: "Request a real renewal.",
                            symbol: "arrow.clockwise.circle.fill",
                            accent: violet,
                            action: refreshApps)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("First install?", systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(mint)
                        Text("Signing may ask for your Apple account and pairing setup the first time. Once configured, manage apps here without a separate SideStore app.")
                            .font(.footnote)
                            .foregroundStyle(subdued)

                        HStack(spacing: 18) {
                            SwiftUI.Button("Settings", action: openSettings)
                            SwiftUI.Button("App Sources", action: openSources)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(mint)
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(surface.opacity(0.8),
                                in: RoundedRectangle(cornerRadius: 22))
                    .padding(.bottom, 30)
                }
                .frame(maxWidth: 640, alignment: .leading)
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func quickAction(title: String, detail: String,
                             symbol: String, accent: Color,
                             action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(accent)
                    .frame(width: 43, height: 43)
                    .background(accent.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(subdued)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(subdued)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(surface, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
