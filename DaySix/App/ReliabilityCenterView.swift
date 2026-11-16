import SwiftUI
import UIKit
import UserNotifications

/// Guides the strongest stock-iOS reliability strategy we can honestly offer:
/// independent system automation triggers plus an opt-in signer-only lifeboat.
struct ReliabilityCenterView: View {
    @EnvironmentObject private var store: DaySixStore
    @State private var backgroundStatus: UIBackgroundRefreshStatus = .restricted
    @State private var notificationAuthorized = false
    @State private var sideStorePresent = false
    @State private var lowPowerMode = false

    private let smartAutomation = """
    A) Create a Shortcut named DaySix Refresh:
       1. Connect LocalDevVPN
       2. Open URL: sidestore:// (optional on iOS 27)
       3. Wait a few seconds
       4. DaySix: Record Refresh Attempt
       5. SideStore: Refresh All Apps

    B) Create a Time of Day DAILY automation:
       1. DaySix: Check DaySix Refresh
       2. If result is true → Run Shortcut: DaySix Refresh
       3. End If
       Enable Run Immediately if iOS offers it.

    C) Optional backup trigger: When Charger Is Connected:
       Repeat the check + If + Run Shortcut sequence.
       DaySix has a six-hour minimum spacing between automatic
       signing requests to avoid rapid duplicate attempts.
    """

    private let lifeboatAutomation = """
    EMERGENCY FAILSAFE (independent of DaySix):
    In Shortcuts, create a separate automation that does NOT
    call a DaySix action. This can still execute if DaySix
    itself fails to launch.

    Trigger: Time of Day → Daily → Run Immediately.
    Actions:
       1. Connect LocalDevVPN
       2. Open URL: sidestore:// (if needed for iOS 27)
       3. SideStore: Refresh All Apps

    WARNING: This directly requests a SideStore refresh daily,
    so it may cause needless Apple account signing calls.
    Enable it only if your first automation is unreliable.
    It still depends on SideStore, VPN, Apple account auth,
    network access and iOS allowing those actions to run.
    """

    var body: some View {
        DaySixBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    SectionHeading(title: "Reliability Lab",
                                   subtitle: "Every legitimate iPhone renewal safety net, without a jailbreak.")

                    GlassCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Label("Live readiness checks", systemImage: "checkmark.shield")
                                .font(.headline).foregroundStyle(DS.mint)
                            statusRow("SideStore installed",
                                      ok: sideStorePresent,
                                      good: "Detected on iPhone",
                                      bad: "Not detected",
                                      detail: "Detection cannot verify your Apple account or pairing.")
                            statusRow("Background App Refresh",
                                      ok: backgroundStatus == .available,
                                      good: "iOS permits requests",
                                      bad: "Disabled or restricted",
                                      detail: "Apple decides whether a background check actually runs.")
                            statusRow("Low Power Mode",
                                      ok: !lowPowerMode,
                                      good: "Off, background work has more opportunity",
                                      bad: "On, iOS limits background refresh",
                                      detail: "This does not change the fixed Shortcuts schedule.")
                            statusRow("iPhone notifications",
                                      ok: notificationAuthorized,
                                      good: "Authorized",
                                      bad: "Not enabled",
                                      detail: "Needed for proactive expiration warnings.")
                            HStack(spacing: 14) {
                                Button("Open Settings") {
                                    guard let u = URL(string: UIApplication.openSettingsURLString) else { return }
                                    UIApplication.shared.open(u)
                                }
                                Button("Ask for Alerts") { store.requestNotificationPermission() }
                            }
                            .font(.footnote.bold()).foregroundStyle(DS.mint)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Background watchdog", systemImage: "moon.stars.fill")
                                .font(.headline).foregroundStyle(DS.violet)
                            Text("Last iOS-granted background check")
                                .font(.caption).foregroundStyle(DS.muted)
                            Text(BackgroundRenewalWatchdog.lastChecked?
                                    .formatted(date: .abbreviated, time: .shortened)
                                 ?? "Never recorded")
                                .font(.subheadline.bold())
                            Text("The watchdog requests short background time to recheck expirations and issue a warning. It cannot sign an IPA, force a running daemon, or guarantee a check while locked.")
                                .font(.footnote).foregroundStyle(DS.muted)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Label("Smart automatic renewal", systemImage: "clock.arrow.2.circlepath")
                                .font(.headline).foregroundStyle(DS.mint)
                            Text("Use more than one Apple-supported Shortcuts trigger. Each trigger checks whether renewal is due before calling SideStore. Duplicate requests are spaced by at least six hours.")
                                .font(.subheadline).foregroundStyle(DS.muted)
                            Text(smartAutomation)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.91))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(DS.ink, in: RoundedRectangle(cornerRadius: 12))
                            Button {
                                UIPasteboard.general.string = smartAutomation
                            } label: {
                                Label("Copy Smart Setup", systemImage: "doc.on.doc")
                                    .font(.subheadline.bold()).foregroundStyle(DS.mint)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Independent lifeboat", systemImage: "life.preserver.fill")
                                .font(.headline).foregroundStyle(DS.amber)
                            Text("A separate iOS automation can call SideStore even if DaySix's signature expires. It must NOT depend on the DaySix Check intent.")
                                .font(.subheadline).foregroundStyle(.white.opacity(0.91))
                            Text(lifeboatAutomation)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(DS.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(DS.ink, in: RoundedRectangle(cornerRadius: 12))
                            Button {
                                UIPasteboard.general.string = lifeboatAutomation
                            } label: {
                                Label("Copy Emergency Setup", systemImage: "doc.on.doc")
                                    .font(.subheadline.bold()).foregroundStyle(DS.mint)
                            }
                            Text("This is opt-in because daily unnecessary provisioning can cause Apple account throttling. It still cannot recover a dead SideStore installation or a revoked Apple certificate.")
                                .font(.footnote).foregroundStyle(DS.amber)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("If both apps stop launching", systemImage: "cross.case.fill")
                                .font(.headline).foregroundStyle(DS.amber)
                            Text("No local iOS automation can execute an expired app's signing code. First restore a working on-device installer using the official SideInstaller instructions, then reinstall DaySix under SideStore management and verify your apps' data.")
                                .font(.footnote).foregroundStyle(DS.muted)
                            Link("Official SideInstaller",
                                 destination: URL(string: "https://sideinstaller.net/")!)
                                .font(.subheadline.bold()).foregroundStyle(DS.mint)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Reliability Lab")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: inspect)
    }

    private func statusRow(_ title: String, ok: Bool, good: String,
                           bad: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(ok ? DS.mint : DS.amber)
                .frame(width: 21)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(ok ? good : bad)
                    .font(.caption).foregroundStyle(ok ? DS.mint : DS.amber)
                Text(detail).font(.caption2).foregroundStyle(DS.muted)
            }
            Spacer()
        }
    }

    private func inspect() {
        backgroundStatus = UIApplication.shared.backgroundRefreshStatus
        lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        if let u = URL(string: "sidestore://") {
            sideStorePresent = UIApplication.shared.canOpenURL(u)
        }
        Task {
            let authorization = await UNUserNotificationCenter.current().notificationSettings()
                .authorizationStatus
            notificationAuthorized = authorization == .authorized
                || authorization == .provisional
        }
    }
}
