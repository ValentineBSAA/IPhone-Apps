import SwiftUI
import UIKit
import AudioToolbox

enum RecoveryPower {
    static func connected(_ state: UIDevice.BatteryState) -> Bool {
        state == .charging || state == .full
    }
}

enum OpeningPace {
    static let recognition = 10
    static let diagnostics = 15
    static let preparation = 20
    static let installation = 65
    static let reboot = 15
    static let total = recognition + diagnostics + preparation + installation + reboot
    static func duration(_ stage: Int) -> Int {
        switch stage { case 1: return recognition + diagnostics; case 2: return preparation + installation; case 4: return reboot; default: return 0 }
    }
    static func canAdvance(stage: Int, connected: Bool, active: Bool) -> Bool {
        active && (stage == 4 || ((stage == 1 || stage == 2) && connected))
    }
}

/// All device operations are simulated; only real external-power status is observed.
struct RecoveryPrologue: View {
    @AppStorage("lastseen.recovery.stage") private var stage = 0
    @AppStorage("lastseen.recovery.progress") private var elapsed = 0
    @AppStorage("lastseen.recovery.simulated") private var simulated = false
    @AppStorage("lastseen.recovery.effects") private var effects = true
    @AppStorage("lastseen.recovery.openingRevision") private var revision = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    @State private var powered = false
    @State private var previousMonitoring: Bool?
    @State private var verbose = false
    @State private var showQA = false
    @State private var initialized = false
    private let accent = Color(red: 0.35, green: 0.86, blue: 0.77)
    private let background = Color(red: 0.035, green: 0.06, blue: 0.10)
    private var connected: Bool { powered || simulated }
    private var duration: Int { OpeningPace.duration(stage) }
    private var fraction: Double { duration > 0 ? min(1, Double(elapsed) / Double(duration)) : 0 }
    private var interrupted: Bool { (stage == 1 || stage == 2) && !connected }
    private var phaseTitle: String {
        switch stage {
        case 0: return connected ? "Device connected" : "Connect your device"
        case 1: return elapsed < OpeningPace.recognition ? "Recognizing device" : elapsed < duration ? "Running diagnostics" : "Device ready"
        case 2: return elapsed < OpeningPace.preparation ? "Preparing environment" : "Installing jailbreak"
        case 3: return "Installation complete"
        case 4: return "Starting Patchline"
        default: return "Welcome to Last Seen"
        }
    }
    private var detail: String {
        switch stage {
        case 0: return connected ? "Your service session is ready." : "Connect your phone to power using a charging cable."
        case 1: return elapsed < OpeningPace.recognition ? "Establishing a virtual device session." : elapsed < duration ? "Checking the recovery environment and preserving archived records." : "Diagnostics passed. The custom environment is ready to install."
        case 2: return elapsed < OpeningPace.preparation ? "Preparing the local bootstrap and package environment." : "Keep the connection active while the custom environment is installed."
        case 3: return "Patchline and Relay are ready. Restart the fictional phone to finish."
        case 4: return "Finalizing services and refreshing the icon cache."
        default: return "A new environment. An unfamiliar backup. Your story begins here."
        }
    }
    private var diagnosticLines: [String] {
        let items = ["Virtual transport established", "Recovery manifest verified", "Archived records located", "Protected records preserved", "Compatibility confirmed"]
        return Array(items.prefix(stage > 1 ? items.count : min(items.count, max(0, (elapsed - 10) / 3))))
    }
    private var installLines: [String] {
        let items = ["Preparing bootstrap", "Preparing userspace environment", "Registering tweak loader", "Installing Relay package manager", "Verifying local package index", "Refreshing icon cache", "Preserving archived backup", "Finalizing custom environment"]
        return Array(items.prefix(stage > 2 ? items.count : min(items.count, max(0, elapsed / 10))))
    }

    var body: some View {
        Group {
            if !initialized {
                background.ignoresSafeArea()
            } else if stage >= 6 {
                PhoneSetupRoot()
            } else {
                interface
                    .onAppear { startMonitoring() }
                    .onDisappear { stopMonitoring() }
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)) { _ in readPower() }
                    .task(id: stage) { await runClock() }
            }
        }
        .preferredColorScheme(.dark)
        .statusBar(hidden: initialized && stage == 4)
        .tint(accent)
        .onAppear {
            guard !initialized else { return }
            if revision < 3 {
                // One-time replay of the revised prologue, never reset the phone or earned access.
                stage = 0; elapsed = 0; simulated = false; revision = 3
                OpeningQA.record("Opening revision 3 initialized; existing phone records retained")
            }
            initialized = true
        }
        .onChange(of: phase) { value in
            guard stage < 6, initialized else { return }
            if value == .background { OpeningQA.record("Opening backgrounded at stage \(stage), \(elapsed)s") }
            if value == .active { readPower(); OpeningQA.record("Opening resumed at stage \(stage), \(elapsed)s") }
        }
        .sheet(isPresented: $showQA) { OpeningDiagnosticsView() }
    }

    private var interface: some View {
        ZStack {
            if stage == 4 {
                RestartArtwork(phase: RestartPhase.opening(at: elapsed))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.65), value: RestartPhase.opening(at: elapsed))
                    .overlay(alignment: .bottom) {
                        if RestartPhase.opening(at: elapsed) != .black {
                            Button("Skip animation") { elapsed = duration; finishTimedStage() }.font(.caption).foregroundColor(.white.opacity(0.6)).padding(.bottom, 24)
                        }
                    }.transition(.opacity)
            } else {
            background.ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(0.14), .clear], center: .top, startRadius: 10, endRadius: 450).ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 20) {
                        if stage == 0 { connectionArt }
                        else if stage == 4 { bootArt }
                        else { stageArt }
                        Text(phaseTitle).font(.system(size: 32, weight: .semibold, design: .rounded)).multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text(detail).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        if stage == 0 { connectionStatus }
                        if stage == 1 || stage == 2 || stage == 4 { progressCard }
                        if interrupted { interruptionCard }
                        if stage == 5 { completionInfo }
                        if stage > 0 && stage < 5 { verbosePanel }
                    }.padding(.horizontal, 23).padding(.vertical, 24)
                }.scrollIndicators(.hidden)
                actions.padding(.horizontal, 23).padding(.bottom, 12)
                Text("PATCHLINE  •  DEVICE UTILITY").font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(1.8).foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }.frame(maxWidth: 540)
            }
        }.animation(reduceMotion ? nil : .easeInOut(duration: 0.7), value: stage == 4)
    }
    private var header: some View {
        HStack {
            HStack(spacing: 9) {
                OpeningArt(name: "Opening_Computer", size: 39)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Patchline").font(.headline)
                    Text("Device utility").font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer()
            Button { effects.toggle(); OpeningQA.record(effects ? "Connection effects enabled" : "Connection effects muted") } label: {
                Image(systemName: effects ? "speaker.wave.2" : "speaker.slash").frame(width: 36, height: 44)
            }.accessibilityLabel(effects ? "Mute connection effects" : "Enable connection effects")
            Button { showQA = true } label: {
                OpeningArt(name: "Opening_Diagnostics", size: 32).frame(width: 36, height: 44)
            }.accessibilityLabel("Developer Diagnostics")
        }.padding(.horizontal, 22).padding(.top, 6)
    }
    private var connectionArt: some View {
        VStack(spacing: 10) {
            OpeningArt(name: connected ? "Opening_Computer" : "Opening_Phone", size: 176)
                .opacity(connected ? 1 : 0.82)
            HStack(spacing: 10) {
                OpeningArt(name: "Opening_USB", size: 42)
                Text(connected ? "Virtual connection established" : "Connect your charging cable")
                    .font(.caption.weight(.medium)).foregroundColor(.secondary)
            }
        }.frame(maxWidth: .infinity)
            .accessibilityLabel(connected ? "Connected virtual device" : "Connect to external power")
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: connected)
    }
    private var stageArt: some View {
        let name: String = stage == 1 ? (elapsed < OpeningPace.recognition ? "Opening_USB" : "Opening_Diagnostics")
            : stage == 2 ? "Opening_Install" : stage == 3 ? "Opening_Unlock" : "Opening_Respring"
        return OpeningArt(name: name, size: 176)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: name)
    }
    private var bootArt: some View { OpeningArt(name: "Opening_Reboot", size: 176) }
    private var connectionStatus: some View {
        HStack(spacing: 12) {
            Circle().fill(connected ? accent : .orange).frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 4) {
                Text(connected ? "Connection established" : "Waiting for connection").font(.subheadline.weight(.semibold))
                Text(simulated ? "Simulated connection" : powered ? "External power detected" : "No external power detected").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if connected { Image(systemName: "checkmark.circle.fill").foregroundColor(accent) }
            else { ProgressView().tint(accent) }
        }.padding(15).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 17))
    }
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(interrupted ? "Paused" : elapsed >= duration ? "Complete" : "In progress").font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(fraction * 100))%").font(.system(.title3, design: .monospaced))
            }
            ProgressView(value: fraction).tint(interrupted ? .orange : accent)
            Text("\(elapsed) of \(duration) seconds • \(max(0, duration - elapsed))s remaining").font(.caption.monospacedDigit()).foregroundColor(.secondary)
            if stage == 1 { stepRow("Device recognition", complete: elapsed >= OpeningPace.recognition); stepRow("Diagnostics", complete: elapsed >= duration) }
            if stage == 2 { stepRow("Prepare environment", complete: elapsed >= OpeningPace.preparation); stepRow("Install custom environment", complete: elapsed >= duration) }
        }.padding(17).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
    }
    private func stepRow(_ label: String, complete: Bool) -> some View {
        HStack {
            Image(systemName: complete ? "checkmark.circle.fill" : "circle").foregroundColor(complete ? accent : .secondary)
            Text(label).font(.caption)
            Spacer()
        }
    }
    private var interruptionCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Connection interrupted", systemImage: "exclamationmark.triangle.fill").font(.headline).foregroundColor(.orange)
            Text("Progress is saved. Reconnect to resume, or continue without a cable.").font(.caption).foregroundColor(.secondary)
            Button("Continue without cable") { chooseVirtual() }.buttonStyle(.bordered)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 15))
    }
    private var verbosePanel: some View {
        DisclosureGroup(isExpanded: $verbose) {
            VStack(alignment: .leading, spacing: 8) {
                Text("> Service session ready")
                ForEach(diagnosticLines, id: \.self) { Text("> " + $0) }
                if stage >= 2 { ForEach(installLines, id: \.self) { Text("> " + $0) } }
                if stage == 4 { Text("> Starting virtual services") }
            }.font(.system(.caption, design: .monospaced)).foregroundColor(accent)
                .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 12)).padding(.top, 10)
        } label: {
            HStack(spacing: 8) { OpeningArt(name: "Opening_Terminal", size: 32); Text("Verbose mode") }
        }.font(.subheadline).padding(14).background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 15))
    }
    private var completionInfo: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Custom environment installed", systemImage: "checkmark.seal.fill").foregroundColor(accent).font(.headline)
            Text("Last Seen is an original fictional horror game. Patchline, Relay, the restored records and all system changes exist only inside the game. No real jailbreak, USB transfer or device modification has occurred.")
            Text("Inspired by the creativity of the jailbreak community, from Installer and Cydia through redsn0w, evasi0n, checkra1n, unc0ver, Dopamine, palera1n, Sileo and Zebra. Independent projects; no affiliation or endorsement.")
                .foregroundColor(.secondary)
        }.font(.subheadline).frame(maxWidth: .infinity, alignment: .leading).padding(17).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
    }
    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
        }.buttonStyle(.borderedProminent).tint(accent).foregroundColor(background)
    }
    @ViewBuilder private var actions: some View {
        VStack(spacing: 10) {
            switch stage {
            case 0:
                primary("Begin diagnostics") { transition(1) }.disabled(!connected)
                if !connected { Button("Continue without cable") { chooseVirtual() }.font(.subheadline) }
            case 1:
                if elapsed >= duration { primary("Install jailbreak") { transition(2) }.disabled(!connected) }
                else { Text(interrupted ? "Reconnect to continue" : "Diagnostics are running").font(.caption).foregroundColor(.secondary) }
            case 2:
                Text(interrupted ? "Installation paused" : "Keep this screen open").font(.caption).foregroundColor(.secondary)
            case 3:
                primary("Userspace reboot") { transition(4) }
            case 4:
                Text("Starting the new environment").font(.caption).foregroundColor(.secondary)
            case 5:
                primary("Continue to phone") { transition(6) }
            default: EmptyView()
            }
            if duration > 0 && elapsed < duration && !interrupted {
                Button("Skip animation") {
                    elapsed = duration
                    OpeningQA.record("Animation explicitly skipped at stage \(stage)")
                    if stage != 1 { finishTimedStage() }
                }.font(.caption).foregroundColor(.secondary)
            }
        }
    }
    private func transition(_ next: Int) {
        OpeningQA.record("Stage \(stage) completed at \(elapsed)s; entering \(next)")
        elapsed = 0; stage = next
        if next == 4 { OpeningQA.record("Userspace reboot started") }
        if next == 5 { RestartAudio.stop(); OpeningQA.record("Userspace reboot and respring completed; welcome displayed") }
    }
    private func finishTimedStage() {
        if stage == 2 { transition(3) }
        else if stage == 4 { transition(5) }
        else if stage == 1 { OpeningQA.record("Diagnostics finished at \(elapsed)s") }
    }
    private func chooseVirtual() {
        guard !simulated else { return }
        simulated = true
        OpeningQA.record("Cable-free simulated connection selected")
        connectionFeedback()
    }
    private func startMonitoring() {
        guard previousMonitoring == nil else { return }
        previousMonitoring = UIDevice.current.isBatteryMonitoringEnabled
        UIDevice.current.isBatteryMonitoringEnabled = true
        readPower()
        OpeningQA.record("Recovery screen opened at stage \(stage), \(elapsed)s")
    }
    private func stopMonitoring() {
        if let previous = previousMonitoring { UIDevice.current.isBatteryMonitoringEnabled = previous }
        previousMonitoring = nil
    }
    private func readPower() {
        let next = RecoveryPower.connected(UIDevice.current.batteryState)
        if next != powered {
            OpeningQA.record(next ? "External power connected" : "External power disconnected")
            if !simulated && (stage == 1 || stage == 2) && elapsed < duration {
                OpeningQA.record(next ? "Timed stage resumed after connection" : "Timed stage paused after disconnection")
            }
            if !simulated && stage <= 2 && phase == .active {
                if next {
                    connectionFeedback()
                } else {
                    disconnectionFeedback()
                }
            }
        }
        powered = next
    }
    private func connectionFeedback() {
        guard effects else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        AudioServicesPlaySystemSound(1104)
        OpeningQA.record("Connection haptic and sound requested")
    }
    private func disconnectionFeedback() {
        guard effects else { return }
        if stage == 1 || stage == 2 {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
        OpeningQA.record("Disconnection haptic requested")
    }
    @MainActor private func runClock() async {
        let activeStage = stage
        let seconds = OpeningPace.duration(activeStage)
        guard seconds > 0 else { return }
        while elapsed < seconds && stage == activeStage && !Task.isCancelled {
            do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
            guard !Task.isCancelled, stage == activeStage else { return }
            guard OpeningPace.canAdvance(stage: activeStage, connected: connected, active: phase == .active && !showQA) else { continue }
            elapsed = min(seconds, elapsed + 1)
            if stage == 4 && elapsed == 8 {
                OpeningQA.record("Respring started")
                RestartAudio.play("RespringDown", enabled: effects)
            }
            if stage == 4 && elapsed == 10 { RestartAudio.play("RespringUp", enabled: effects) }
            if elapsed == OpeningPace.recognition && stage == 1 { OpeningQA.record("Device recognition completed") }
            if elapsed == OpeningPace.preparation && stage == 2 { OpeningQA.record("Environment preparation completed") }
        }
        guard !Task.isCancelled, stage == activeStage, elapsed >= seconds else { return }
        finishTimedStage()
    }
}
