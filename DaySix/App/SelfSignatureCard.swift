import SwiftUI
import UIKit

/// The self card is always present. It is never added to the user-managed
/// app list, and it reads the renewed profile again after reinstall/refresh.
struct SelfSignatureCard: View {
    @EnvironmentObject private var store: DaySixStore
    @State private var editingExpiry = false
    @State private var editedExpiry = Date.now.addingTimeInterval(7 * 86_400)
    private var verifiedExpiry: Date? { SelfProvisioning.expiresAt }
    private var expiry: Date? { SelfProvisioning.effectiveExpiry }
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
                        Text(verifiedExpiry == nil ? "This app · manual expiry fallback" : "This app · verified profile date")
                            .font(.caption).foregroundStyle(DS.muted)
                    }
                    Spacer()
                    Text(status)
                        .font(.caption.bold())
                        .foregroundStyle(isDue ? DS.amber : verifiedExpiry == nil ? DS.amber : DS.mint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            (isDue ? DS.amber : verifiedExpiry == nil ? DS.amber : DS.mint).opacity(0.11),
                            in: Capsule())
                }

                if let expiry {
                    HStack(spacing: 7) {
                        Image(systemName: "calendar.badge.clock")
                        Text(verifiedExpiry == nil ? "Manually entered expiry: \(expiry.formatted(date: .abbreviated, time: .shortened))" : "Signed until \(expiry.formatted(date: .abbreviated, time: .shortened))")
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
                    Text("Signing expiry unavailable. DaySix could not read an embedded Apple provisioning profile. Enter the actual expiration shown in SideStore so day-six scheduling still works.")
                        .font(.footnote).foregroundStyle(DS.amber)
                }

                if verifiedExpiry == nil {
                    Button {
                        editedExpiry = SelfProvisioning.manualExpiry ?? Date.now.addingTimeInterval(7 * 86_400)
                        editingExpiry = true
                    } label: {
                        Label("Enter SideStore expiration", systemImage: "calendar.badge.clock")
                            .font(.footnote.bold()).foregroundStyle(DS.mint)
                    }
                    Text("Manual dates trigger reminders, but do not count as verified signing evidence.")
                        .font(.caption2).foregroundStyle(DS.muted)
                }

                if let renewed = RenewalAudit.lastVerifiedSelfRenewal {
                    Label("Last verified self-renewal: \(renewed.formatted(date: .abbreviated, time: .shortened))",
                          systemImage: "checkmark.seal.fill")
                        .font(.footnote).foregroundStyle(DS.mint)
                }
                if let attempt, isDue {
                    Text("Last refresh attempt: \(attempt.formatted(date: .abbreviated, time: .shortened)). This is not proof of success.")
                        .font(.footnote).foregroundStyle(DS.amber)
                }

                Button(action: { RefreshLauncher.runConfiguredShortcut() }) {
                    Label("Run DaySix Refresh", systemImage: "arrow.clockwise")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(DS.ink)
                        .background(DS.gradient, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button("Open SideStore manually") { RefreshLauncher.openSideStore() }
                    .font(.footnote.bold()).foregroundStyle(DS.mint)
                Text("Create the named 'DaySix Refresh' Shortcut under More first. Install DaySix from inside SideStore so SideStore can renew it. Shortcut execution is never proof that signing succeeded.")
                    .font(.caption).foregroundStyle(DS.muted)
            }
        }
        .sheet(isPresented: $editingExpiry) {
            NavigationStack {
                Form {
                    Section("DaySix expiration") {
                        DatePicker("Expires", selection: $editedExpiry,
                                   displayedComponents: [.date, .hourAndMinute])
                        Text("Use the exact expiration date shown in SideStore. This is a manual fallback only, not proof that signing succeeded.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Signing Expiration")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editingExpiry = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            SelfProvisioning.setManualExpiry(editedExpiry)
                            editingExpiry = false
                            store.reload()
                        }
                    }
                }
            }
        }
    }

    private var status: String {
        guard let expiry else { return "Unknown" }
        if Date.now >= expiry { return "Expired" }
        if isDue { return "Day 6 · Due" }
        let days = max(0, Calendar.current.dateComponents(
            [.day], from: Date.now, to: expiry).day ?? 0)
        return verifiedExpiry == nil ? "Manual · \(days)d" : "\(days)d left"
    }


}
