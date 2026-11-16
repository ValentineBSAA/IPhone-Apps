import SwiftUI

private struct RenewalQueueItem: Identifiable {
    let id: String
    let title: String
    let expiration: Date
    let isSelf: Bool
    let isVerifiedByProfile: Bool

    var dueAt: Date { RenewalPolicy.renewAt(expiration: expiration) }

    var condition: RenewalCondition {
        if expiration <= .now { return .expired }
        if dueAt <= .now { return .due }
        return .scheduled
    }

    enum RenewalCondition {
        case scheduled, due, expired

        var title: String {
            switch self {
            case .scheduled: return "Scheduled"
            case .due: return "Ready"
            case .expired: return "Expired"
            }
        }

        var color: Color {
            switch self {
            case .scheduled: return DS.mint
            case .due: return DS.amber
            case .expired: return .red
            }
        }
    }
}

/// ReProvision-inspired renewal control panel with real, saved policy.
/// A signer handoff is clearly distinguished from signing completion.
struct RenewalCenterView: View {
    @EnvironmentObject private var store: DaySixStore
    @AppStorage(RenewalPolicy.autoKey) private var automaticRequests = true
    @AppStorage(RenewalPolicy.hoursKey) private var windowHours = 24

    private var queue: [RenewalQueueItem] {
        var result: [RenewalQueueItem] = []
        if let expiry = SelfProvisioning.effectiveExpiry {
            result.append(.init(id: "daysix-self", title: "DaySix",
                                expiration: expiry, isSelf: true,
                                isVerifiedByProfile: SelfProvisioning.expiresAt != nil))
        }
        for app in store.apps {
            result.append(.init(id: app.id.uuidString, title: app.name,
                                expiration: app.expiresAt, isSelf: false,
                                isVerifiedByProfile: false))
        }
        return result.sorted { $0.expiration < $1.expiration }
    }

    private var dueCount: Int {
        queue.filter { $0.condition == .due }.count
    }

    var body: some View {
        NavigationStack {
            DaySixBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: 17) {
                        SectionHeading(title: "Renewal Center",
                                       subtitle: "ReProvision-style management, built for stock iOS.")

                        GlassCard {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(DS.gradient)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Renewal Control").font(.headline)
                                        Text("iPhone-only, no desktop needed for routine refreshing")
                                            .font(.caption).foregroundStyle(DS.muted)
                                    }
                                    Spacer()
                                }
                                Divider().overlay(.white.opacity(0.08))
                                Toggle(isOn: $automaticRequests) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Automatic refresh requests")
                                            .font(.subheadline.bold())
                                        Text("Allows the DaySix Shortcut to request a SideStore refresh when due.")
                                            .font(.caption).foregroundStyle(DS.muted)
                                    }
                                }
                                .tint(DS.mint)
                                .onChange(of: automaticRequests) { _, _ in store.reload() }

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Refresh before expiration")
                                        .font(.subheadline.bold())
                                    Picker("Renewal lead time", selection: $windowHours) {
                                        Text("12h").tag(12)
                                        Text("24h").tag(24)
                                        Text("36h").tag(36)
                                        Text("48h").tag(48)
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: windowHours) { _, _ in store.reload() }
                                    Text("24 hours is the DaySix default: refresh on day six of a seven-day signature. Longer windows give iOS more chances to run your Shortcut.")
                                        .font(.caption).foregroundStyle(DS.muted)
                                }

                                GlowButton(title: "Run DaySix Refresh", symbol: "arrow.clockwise") {
                                    RefreshLauncher.runConfiguredShortcut()
                                }
                                Text("Runs your named Shortcut. It does not sign anything inside DaySix or guarantee that the Shortcut completed.")
                                    .font(.caption2).foregroundStyle(DS.muted)
                            }
                        }

                        HStack(alignment: .center) {
                            Text("SIGNING QUEUE")
                                .font(.caption.bold()).tracking(1.5).foregroundStyle(DS.muted)
                            Spacer()
                            Text("\(dueCount) ready · \(queue.count) monitored")
                                .font(.caption).foregroundStyle(DS.muted)
                        }

                        if queue.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label("No known signing expiration", systemImage: "calendar.badge.exclamationmark")
                                        .font(.subheadline.bold()).foregroundStyle(DS.amber)
                                    Text("Open My Apps to enter DaySix's actual SideStore expiration or add an app. Unknown expiration dates are never fabricated.")
                                        .font(.subheadline).foregroundStyle(DS.muted)
                                }
                            }
                        } else {
                            ForEach(queue) { item in
                                GlassCard {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: item.isSelf ? "checkmark.shield.fill" : "app.fill")
                                            .font(.title2)
                                            .foregroundStyle(item.isSelf ? DS.mint : DS.violet)
                                            .frame(width: 38, height: 38)
                                            .background(DS.cardBright,
                                                        in: RoundedRectangle(cornerRadius: 11))
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(item.title).font(.headline)
                                            Text(item.isSelf
                                                 ? (item.isVerifiedByProfile ? "Embedded provisioning profile" : "Manually entered expiration")
                                                 : "User-tracked expiration, not independently verified")
                                                .font(.caption2).foregroundStyle(DS.muted)
                                            Text("Expires \(item.expiration.formatted(date: .abbreviated, time: .shortened))")
                                                .font(.caption).foregroundStyle(.white.opacity(0.9))
                                            Text("Renewal target \(item.dueAt.formatted(date: .abbreviated, time: .shortened))")
                                                .font(.caption).foregroundStyle(DS.muted)
                                        }
                                        Spacer(minLength: 4)
                                        Text(item.condition.title)
                                            .font(.caption2.bold())
                                            .foregroundStyle(item.condition.color)
                                    }
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Stock iOS limitations", systemImage: "shield.lefthalf.filled")
                                    .font(.headline).foregroundStyle(DS.violet)
                                Text("ReProvision on a jailbroken phone uses a privileged background daemon. DaySix cannot install that daemon on a normal iPhone. Shortcuts and SideStore are the supported on-device route, but iOS may delay or reject a background refresh.")
                                    .font(.footnote).foregroundStyle(DS.muted)
                                Text("An app marked Expired requires recovery in the signer. DaySix does not pretend it can silently launch an app whose signature has already expired.")
                                    .font(.footnote).foregroundStyle(DS.amber)
                            }
                        }

                        NavigationLink {
                            RenewalHistoryView()
                        } label: {
                            Label("View Renewal History", systemImage: "clock.arrow.circlepath")
                                .font(.subheadline.bold())
                                .foregroundStyle(DS.mint)
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 20)
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
