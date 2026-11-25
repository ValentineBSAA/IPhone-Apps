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
    @State private var pulse = false
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
        .tint(accent)
        .onAppear {
            guard !initialized else { return }
            if revision < 2 {
                // One-time replay of the revised prologue, never reset the phone or earned access.
                stage = 0; elapsed = 0; simulated = false; revision = 2
                OpeningQA.record("Opening revision 2 initialized; existing phone records retained")
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
    }
    private var header: some View {
        HStack {
            HStack(spacing: 9) {
                Image(systemName: "square.stack.3d.up.fill").font(.title2).foregroundColor(accent)
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
                Image(systemName: "waveform.path.ecg").frame(width: 36, height: 44)
            }.accessibilityLabel("Developer Diagnostics")
        }.padding(.horizontal, 22).padding(.top, 6)
    }
    private var connectionArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30).fill(.white.opacity(0.035))
            RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.10))
            Canvas { context, size in
                let w = size.width, h = size.height
                let monitor = CGRect(x: w * 0.08, y: h * 0.18, width: w * 0.44, height: h * 0.44)
                let phone = CGRect(x: w * 0.68, y: h * 0.11, width: w * 0.23, height: h * 0.64)
                func box(_ rect: CGRect, _ r: CGFloat, _ fill: Color, _ stroke: Color) {
                    let p = Path(roundedRect: rect, cornerRadius: r)
                    context.fill(p, with: .color(fill)); context.stroke(p, with: .color(stroke), lineWidth: 1.5)
                }
                box(monitor, 8, Color(red: 0.17, green: 0.21, blue: 0.28), .white.opacity(0.4))
                box(monitor.insetBy(dx: 6, dy: 6), 4, background, .white.opacity(0.12))
                let stand = Path { p in
                    p.move(to: CGPoint(x: monitor.midX, y: monitor.maxY)); p.addLine(to: CGPoint(x: monitor.midX, y: monitor.maxY + 20))
                    p.move(to: CGPoint(x: monitor.midX - 25, y: monitor.maxY + 20)); p.addLine(to: CGPoint(x: monitor.midX + 25, y: monitor.maxY + 20))
                }
                context.stroke(stand, with: .color(.gray), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                box(phone, 14, Color(red: 0.18, green: 0.22, blue: 0.29), .white.opacity(0.5))
                box(phone.insetBy(dx: 4, dy: 4), 11, background, .white.opacity(0.10))
                box(CGRect(x: phone.midX - 12, y: phone.minY + 8, width: 24, height: 5), 3, .gray.opacity(0.7), .clear)
                let cable = Path { p in
                    p.move(to: CGPoint(x: monitor.maxX, y: monitor.midY))
                    p.addLine(to: CGPoint(x: w * 0.57, y: monitor.midY))
                    p.addQuadCurve(to: CGPoint(x: w * 0.60, y: monitor.midY + 12), control: CGPoint(x: w * 0.60, y: monitor.midY))
                    p.addLine(to: CGPoint(x: w * 0.60, y: h * 0.85))
                    p.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.90), control: CGPoint(x: w * 0.60, y: h * 0.90))
                    p.addLine(to: CGPoint(x: phone.midX - 12, y: h * 0.90))
                    p.addQuadCurve(to: CGPoint(x: phone.midX, y: h * 0.83), control: CGPoint(x: phone.midX, y: h * 0.90))
                    p.addLine(to: CGPoint(x: phone.midX, y: phone.maxY + (connected ? 2 : 12)))
                }
                context.stroke(cable, with: .color(connected ? accent : .gray), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, dash: connected ? [] : [5, 6]))
                let plug = CGRect(x: phone.midX - 7, y: phone.maxY + (connected ? 0 : 12), width: 14, height: 10)
                box(plug, 3, connected ? accent : .gray, .white.opacity(0.25))
                context.draw(Text(Image(systemName: "terminal")).font(.system(size: 25)).foregroundColor(accent.opacity(0.8)), at: CGPoint(x: monitor.midX, y: monitor.midY))
                context.draw(Text(Image(systemName: connected ? "bolt.fill" : "cable.connector")).font(.system(size: 25)).foregroundColor(connected ? accent : .gray), at: CGPoint(x: phone.midX, y: phone.midY))
            }.padding(10)
        }.frame(height: 205)
            .accessibilityLabel(connected ? "Illustration of connected virtual phone" : "Illustration showing where to connect a charging cable")
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: connected)
    }
    private var stageArt: some View {
        ZStack {
            Circle().fill(accent.opacity(0.055)).frame(width: 145, height: 145)
            Circle().strokeBorder(accent.opacity(0.18), lineWidth: 1).frame(width: 145, height: 145)
            Circle().strokeBorder(.white.opacity(0.08), lineWidth: 1).frame(width: 117, height: 117)
            if stage == 1 || stage == 2 {
                Circle().trim(from: 0, to: CGFloat(fraction)).stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round)).frame(width: 145, height: 145).rotationEffect(.degrees(-90))
            }
            Image(systemName: stage == 1 ? "waveform.path.ecg" : stage == 2 ? "square.stack.3d.up.fill" : stage == 3 ? "checkmark.seal.fill" : "lock.open.fill")
                .font(.system(size: 48, weight: .light)).foregroundColor(accent)
        }.frame(height: 155).accessibilityHidden(true)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: elapsed)
    }
    private var bootArt: some View {
        VStack(spacing: 15) {
            Image(systemName: "square.stack.3d.up.fill").font(.system(size: 80, weight: .ultraLight)).foregroundColor(accent)
            Text("P A T C H L I N E").font(.caption.weight(.semibold)).foregroundColor(.secondary)
        }.frame(height: 160).accessibilityHidden(true)
    }
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
        DisclosureGroup("Verbose mode", isExpanded: $verbose) {
            VStack(alignment: .leading, spacing: 8) {
                Text("> Service session ready")
                ForEach(diagnosticLines, id: \.self) { Text("> " + $0) }
                if stage >= 2 { ForEach(installLines, id: \.self) { Text("> " + $0) } }
                if stage == 4 { Text("> Starting virtual services") }
            }.font(.system(.caption, design: .monospaced)).foregroundColor(accent)
                .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 12)).padding(.top, 10)
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
                primary("Reboot device") { transition(4) }
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
                    finishTimedStage()
                }.font(.caption).foregroundColor(.secondary)
            }
        }
    }
    private func transition(_ next: Int) {
        OpeningQA.record("Stage \(stage) completed at \(elapsed)s; entering \(next)")
        elapsed = 0; stage = next
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
            if next && !simulated { connectionFeedback() }
        }
        powered = next
    }
    private func connectionFeedback() {
        guard effects else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1104)
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
            if elapsed == OpeningPace.recognition && stage == 1 { OpeningQA.record("Device recognition completed") }
            if elapsed == OpeningPace.preparation && stage == 2 { OpeningQA.record("Environment preparation completed") }
        }
        guard !Task.isCancelled, stage == activeStage, elapsed >= seconds else { return }
        finishTimedStage()
    }
}
