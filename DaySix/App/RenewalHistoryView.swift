import SwiftUI

/// The audit history helps distinguish a scheduled attempt from a genuinely
/// updated embedded provisioning expiration after the app relaunches.
struct RenewalHistoryView: View {
    @State private var entries: [RenewalAudit.Entry] = RenewalAudit.entries

    var body: some View {
        DaySixBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeading(title: "Renewal History",
                                   subtitle: "Local evidence for attempts and verified self-renewals.")
                    GlassCard {
                        VStack(alignment: .leading, spacing: 9) {
                            Label("What these events prove", systemImage: "info.circle.fill")
                                .font(.headline).foregroundStyle(DS.mint)
                            Text("A refresh attempt means Shortcuts invoked SideStore. A verified self-renewal means DaySix launched with an embedded provisioning profile whose expiration genuinely increased.")
                                .font(.footnote).foregroundStyle(DS.muted)
                        }
                    }
                    if entries.isEmpty {
                        GlassCard {
                            Text("No history yet. DaySix records its own installed signature once an embedded Apple provisioning profile is available.")
                                .foregroundStyle(DS.muted)
                                .font(.subheadline)
                        }
                    } else {
                        ForEach(entries) { entry in
                            GlassCard {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: icon(for: entry.event))
                                        .font(.title2)
                                        .foregroundStyle(color(for: entry.event))
                                        .frame(width: 33)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(title(for: entry.event))
                                            .font(.subheadline.bold())
                                        Text(entry.message).font(.footnote)
                                            .foregroundStyle(DS.muted)
                                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2).foregroundStyle(DS.muted)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Renewal History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            RenewalAudit.reconcileSelfSignature()
            entries = RenewalAudit.entries
        }
    }

    private func icon(for kind: RenewalAudit.Entry.Event) -> String {
        switch kind {
        case .initialSignature: return "checkmark.shield"
        case .selfSignatureRenewed: return "checkmark.seal.fill"
        case .profileChanged: return "exclamationmark.triangle.fill"
        case .automationAttempt: return "clock.arrow.circlepath"
        }
    }

    private func title(for kind: RenewalAudit.Entry.Event) -> String {
        switch kind {
        case .initialSignature: return "Initial signature detected"
        case .selfSignatureRenewed: return "Self-renewal verified"
        case .profileChanged: return "Signing profile changed"
        case .automationAttempt: return "Automation attempted"
        }
    }

    private func color(for kind: RenewalAudit.Entry.Event) -> Color {
        switch kind {
        case .initialSignature, .selfSignatureRenewed: return DS.mint
        case .profileChanged: return DS.amber
        case .automationAttempt: return DS.violet
        }
    }
}
