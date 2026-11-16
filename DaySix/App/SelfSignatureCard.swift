import SwiftUI
import UIKit

/// The self card is always present. It is never added to the user-managed
/// app list, and it reads the renewed profile again after reinstall/refresh.
struct SelfSignatureCard: View {
    private var expiry: Date? { SelfProvisioning.expiresAt }
    private var isDue: Bool { SelfProvisioning.isDue }

    private var attempt: Date? {
        UserDefaults.standard.object(forKey: "daysix.lastSelfRenewalAttempt") as? Date
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title2).foregroundStyle(DS.gradient)
                        .frame(width: 48, height: 48)
                        .background(DS.cardBright,
                                    in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DaySix").font(.headline)
                        Text("This app · automatic monitoring")
                            .font(.caption).foregroundStyle(DS.muted)
                    }
                    Spacer()
                    Text(status)
                        .font(.caption.bold())
                        .foregroundStyle(isDue ? DS.amber : expiry == nil ? DS.muted : DS.mint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            (isDue ? DS.amber : expiry == nil ? DS.muted : DS.mint).opacity(0.11),
                            in: Capsule())
                }

                if let expiry {
                    HStack(spacing: 7) {
                        Image(systemName: "calendar.badge.clock")
                        Text("Signed until \(expiry.formatted(date: .abbreviated, time: .shortened))")
                    }
                    .font(.subheadline).foregroundStyle(DS.muted)

                    if isDue {
                        Label("DaySix itself needs to be refreshed now.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.bold()).foregroundStyle(DS.amber)
                    } else if let due = SelfProvisioning.refreshDueAt {
                        Text("Automatic refresh target: \(due.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote).foregroundStyle(DS.muted)
                    }
                } else {
                    Text("Signing expiry unavailable. DaySix could not read an embedded Apple provisioning profile. Check the actual expiration in SideStore.")
                        .font(.footnote).foregroundStyle(DS.amber)
                }

                if let attempt, isDue {
                    Text("Last refresh attempt: \(attempt.formatted(date: .abbreviated, time: .shortened)). This is not proof of success.")
                        .font(.footnote).foregroundStyle(DS.amber)
                }

                Button(action: openSigningApp) {
                    Label("Open SideStore to refresh", systemImage: "arrow.clockwise.shield")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(DS.ink)
                        .background(DS.gradient, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Text("For automatic self-renewal, install or reinstall DaySix from inside SideStore so SideStore manages it. Signing once through an unrelated installer does not automatically enroll DaySix.")
                    .font(.caption).foregroundStyle(DS.muted)
            }
        }
    }

    private var status: String {
        guard let expiry else { return "Unknown" }
        if Date.now >= expiry { return "Expired" }
        if isDue { return "Day 6 · Due" }
        let days = max(0, Calendar.current.dateComponents(
            [.day], from: Date.now, to: expiry).day ?? 0)
        return "\(days)d left"
    }

    private func openSigningApp() {
        guard let url = URL(string: "sidestore://") else { return }
        UIApplication.shared.open(url)
    }
}
