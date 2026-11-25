import SwiftUI
import UIKit
import AudioToolbox

enum RecoveryPower {
    static func connected(_ state: UIDevice.BatteryState) -> Bool {
        state == .charging || state == .full
    }
}

/// All installation operations are fictional. The only hardware input is external power.
struct RecoveryPrologue: View {
    @AppStorage("lastseen.recovery.stage") private var stage = 0
    @AppStorage("lastseen.recovery.progress") private var progress = 0
    @AppStorage("lastseen.recovery.simulated") private var simulated = false
    @AppStorage("lastseen.recovery.effects") private var effects = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var powered = false
    @State private var previousMonitoring: Bool?
    @State private var diagnosticsOpen = false
    private let installLog = ["Reading recovery manifest", "Preparing bootstrap", "Initializing fictional userspace", "Registering tweak loader", "Installing Relay package manager", "Refreshing icon cache", "Checking archived backup", "Finalizing environment"]
    private var connected: Bool { powered || simulated }

    var body: some View {
        Group {
            if stage >= 5 {
                PhoneSetupRoot()
            } else {
                desktop
                    .onAppear(perform: startMonitoring)
                    .onDisappear(perform: stopMonitoring)
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in readPower() }
                    .task(id: stage) { await advanceAnimation() }
            }
        }.preferredColorScheme(.dark)
    }

    private var desktop: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.12, green: 0.23, blue: 0.34), Color(red: 0.04, green: 0.09, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            if stage == 4 {
                VStack(spacing: 22) {
                    Image(systemName: "square.stack.3d.up.fill").font(.system(size: 68, weight: .light)).foregroundColor(.teal)
                    Text("PATCHLINE").font(.title2.weight(.light)).tracking(6)
                    ProgressView(value: Double(progress), total: 100).tint(.teal).frame(maxWidth: 190)
                    Text("Starting custom environment…").font(.caption).foregroundColor(.secondary)
                    Button("Skip animation") { progress = 100; stage = 5 }.font(.caption)
                }
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "desktopcomputer").font(.title3)
                        Text("Service workstation").font(.caption.weight(.medium))
                        Spacer()
                        Button { effects.toggle() } label: { Image(systemName: effects ? "speaker.wave.2" : "speaker.slash") }
                            .accessibilityLabel(effects ? "Mute connection effects" : "Enable connection effects")
                    }.padding(.horizontal, 5)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "square.stack.3d.up.fill").foregroundColor(.teal)
                                Text("Patchline Device Utility").font(.subheadline.bold())
                                Spacer()
                                Text("1.0").font(.caption.monospacedDigit()).foregroundColor(.secondary)
                            }.padding(12).background(Color.white.opacity(0.08))
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Service ticket 014").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                                Text("Customer requests a custom environment. Preserve recoverable data.").font(.subheadline)
                                HStack(spacing: 15) {
                                    Image(systemName: "iphone").font(.system(size: 46, weight: .light)).foregroundColor(connected ? .teal : .secondary)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Label(connected ? "Device connected" : "Waiting for device", systemImage: connected ? "checkmark.circle.fill" : "circle.dashed")
                                            .font(.headline).foregroundColor(connected ? .teal : .white)
                                        Text(simulated ? "Virtual USB • simulated" : powered ? "External power detected • virtual USB" : "Connect your phone to power")
                                            .font(.caption).foregroundColor(.secondary)
                                        Text("Model: P-14 · Owner: unlisted").font(.caption2).foregroundColor(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }.padding(12).background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
                                if !connected {
                                    Text("Plug in a charging cable or use wireless power. A real computer is not required.").font(.caption).foregroundColor(.secondary)
                                    Button("Continue without cable") { simulated = true; connectionFeedback() }.buttonStyle(.bordered)
                                }
                                if stage >= 1 {
                                    DisclosureGroup("Diagnostic report", isExpanded: $diagnosticsOpen) {
                                        VStack(alignment: .leading, spacing: 7) {
                                            ForEach(["Virtual transport: ready", "Recovery manifest: valid", "Archived user data: present", "Protected records: preserved", "Bootstrap compatibility: ready"], id: \.self) { line in
                                                Label(line, systemImage: "checkmark.circle").font(.caption.monospaced()).foregroundColor(.teal)
                                            }
                                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                                    }.font(.subheadline.weight(.medium))
                                }
                                VStack(alignment: .leading, spacing: 7) {
                                    Text("SESSION LOG").font(.caption2.bold()).foregroundColor(.secondary)
                                    Text("> \(connected ? "Virtual device handshake established." : "Awaiting connection…")")
                                    if stage >= 1 { Text("> Diagnostics completed.") }
                                    if stage >= 2 {
                                        ForEach(Array(installLog.prefix(min(installLog.count, progress * installLog.count / 100 + 1))), id: \.self) { Text("> " + $0) }
                                    }
                                    if stage == 3 { Text("> Installation complete. Reboot required.") }
                                    if stage == 2 && !connected { Text("> Connection interrupted. Reconnect to resume.").foregroundColor(.orange) }
                                }.font(.system(.caption, design: .monospaced)).foregroundColor(.teal)
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                                    .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                                if stage == 2 || stage == 3 {
                                    ProgressView(value: Double(progress), total: 100).tint(.teal)
                                    Text("\(progress)%").font(.caption.monospacedDigit()).foregroundColor(.secondary)
                                }
                                action
                            }.padding(14)
                        }.background(Color(red: 0.10, green: 0.15, blue: 0.21), in: RoundedRectangle(cornerRadius: 16))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.15), lineWidth: 1))
                        Text("Simulated service utility • No system changes or USB data access").font(.caption2).foregroundColor(.secondary).padding(.top, 6)
                    }.scrollIndicators(.hidden)
                    HStack {
                        Image(systemName: "square.grid.2x2.fill").foregroundColor(.teal)
                        Image(systemName: "folder.fill")
                        Image(systemName: "terminal.fill")
                        Spacer()
                        Label(connected ? "Connected" : "Offline", systemImage: "cable.connector")
                    }.font(.caption).padding(12).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .ignore).accessibilityLabel("Workstation taskbar. \(connected ? "Connected" : "Offline").")
                }.padding(16)
            }
        }
    }
    @ViewBuilder private var action: some View {
        switch stage {
        case 0:
            Button("Run diagnostics") { diagnosticsOpen = true; stage = 1 }.buttonStyle(.borderedProminent).disabled(!connected)
        case 1:
            Button("Install custom environment") { progress = 0; stage = 2 }.buttonStyle(.borderedProminent).disabled(!connected)
        case 2:
            Button("Skip installation animation") { progress = 100; stage = 3 }.buttonStyle(.bordered).disabled(!connected)
        case 3:
            Button("Reboot device") { progress = 0; stage = 4 }.buttonStyle(.borderedProminent)
        default: EmptyView()
        }
    }
    private func startMonitoring() {
        guard previousMonitoring == nil else { return }
        previousMonitoring = UIDevice.current.isBatteryMonitoringEnabled
        UIDevice.current.isBatteryMonitoringEnabled = true
        readPower()
    }
    private func stopMonitoring() {
        if let previous = previousMonitoring { UIDevice.current.isBatteryMonitoringEnabled = previous }
        previousMonitoring = nil
    }
    private func readPower() {
        let next = RecoveryPower.connected(UIDevice.current.batteryState)
        if next && !powered && !simulated { connectionFeedback() }
        powered = next
    }
    private func connectionFeedback() {
        guard effects else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1104)
    }
    @MainActor private func advanceAnimation() async {
        guard stage == 2 || stage == 4 else { return }
        let activeStage = stage
        while stage == activeStage && progress < 100 && !Task.isCancelled {
            do { try await Task.sleep(nanoseconds: activeStage == 2 ? 180_000_000 : 120_000_000) } catch { return }
            guard !Task.isCancelled, stage == activeStage else { return }
            if activeStage == 2 && !connected { continue }
            progress = min(100, progress + (reduceMotion ? 100 : activeStage == 2 ? 2 : 5))
        }
        guard !Task.isCancelled, stage == activeStage, progress >= 100 else { return }
        stage = activeStage == 2 ? 3 : 5
    }
}
