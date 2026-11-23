import SwiftUI
import CoreBluetooth
import UIKit

/// Experimental metadata only. This app NEVER sends fryer operating commands.
enum BLEStructurePolicy {
    static let advertisedName = "CAF-P583S-KUS"
    static let idleSeconds = 10
    static let phaseSeconds = 9
    static let sequence: [FryerPreset] = [.airFry, .reheat, .airFry]
    static let connectionTimeout: TimeInterval = 20
    static let sessionTimeout: TimeInterval = 75
    static let maxFramesPerPhase = 12
    static let maxBytesPerFrame = 32
    static let targetService = BLEObservationPolicy.serialService
    static let targetCharacteristic = BLEObservationPolicy.serialNotify
    static func isPermitted(service: CBUUID, characteristic: CBUUID) -> Bool {
        service == targetService && characteristic == targetCharacteristic
    }
}

/// Data stays in memory during the test and is released before displaying results.
struct BLEStructureFrame {
    let phase: Int // -1 idle, 0 Air Fry, 1 Reheat, 2 Air Fry
    let elapsedTenths: Int // Relative to the AUTOMATIC PROMPT, not the actual tap
    let bytes: Data
}

/// Only statistical results may be copied. No raw values or fingerprints.
struct BLEStructureReport: Equatable {
    let totalFrames: Int
    let idleFrames: Int
    let phaseFrames: [Int]
    let firstPromptDelayTenths: [Int?]
    let frameLengths: [Int]
    let usablePairCount: Int
    let changedPositions: [Int]
    let offset2ChangedPairs: Int
    let offset5ChangedPairs: Int
    let changedTogetherPairs: Int
    let byte2PlusOnePairs: Int
    let byte5PlusOnePairs: Int
    let constantMod256Sum: Bool
    let constantXor: Bool
    let sameAirFryChangedPositions: [Int]
    let firstAirFryToReheatChanged: [Int]
    let candidateStablePresetPositions: [Int]
    let truncated: Bool
    let note: String

    static func analyze(_ samples: [BLEStructureFrame],
                        phaseCounts: [Int],
                        idleCount: Int,
                        truncated: Bool = false) -> BLEStructureReport {
        let foreground = samples.filter { $0.phase >= 0 && $0.phase < 3 }
        let frameLengths = Array(Set(samples.map { $0.bytes.count })).sorted()
        let firstDelay: [Int?] = (0..<3).map { i in
            foreground.first(where: { $0.phase == i })?.elapsedTenths
        }
        let compatible = foreground.filter {
            $0.bytes.count > 5 && $0.bytes.count <= BLEStructurePolicy.maxBytesPerFrame
        }
        // Assess adjacent packets in *capture order* only when equal-length, not arbitrary stream order.
        let pairs: [(Data, Data)] = zip(compatible, compatible.dropFirst()).compactMap { first, second in
            first.bytes.count == second.bytes.count ? (first.bytes, second.bytes) : nil
        }
        var changed: Set<Int> = []
        var c2 = 0
        var c5 = 0
        var both = 0
        var plus2 = 0
        var plus5 = 0
        for (a, b) in pairs {
            for i in 0..<a.count where a[i] != b[i] { changed.insert(i) }
            let diff2 = a[2] != b[2]
            let diff5 = a[5] != b[5]
            if diff2 { c2 += 1 }
            if diff5 { c5 += 1 }
            if diff2 && diff5 { both += 1 }
            if b[2] == a[2] &+ 1 { plus2 += 1 }
            if b[5] == a[5] &+ 1 { plus5 += 1 }
        }
        let twoFive = compatible.map { ($0.bytes[2], $0.bytes[5]) }
        // These algebraic checks are heuristics, NEVER proof of checksums or counters.
        let sameSum = twoFive.count >= 3 &&
            Set(twoFive.map { Int($0.0 &+ $0.1) }).count == 1
        let sameXor = twoFive.count >= 3 &&
            Set(twoFive.map { Int($0.0 ^ $0.1) }).count == 1

        let first: [Data?] = (0..<3).map { phase in
            compatible.first(where: { $0.phase == phase })?.bytes
        }
        var airRepeat: [Int] = []
        var transition: [Int] = []
        var candidates: [Int] = []
        if let a = first[0], let b = first[1], let a2 = first[2],
           a.count == b.count && b.count == a2.count {
            for index in 0..<a.count {
                if a[index] != a2[index] { airRepeat.append(index) }
                if a[index] != b[index] { transition.append(index) }
                if a[index] == a2[index] && a[index] != b[index] {
                    candidates.append(index)
                }
            }
        }

        let note: String
        if foreground.isEmpty {
            note = "No FFF1 packets observed during physical-change prompts. No decoding possible."
        } else if first.contains(where: { $0 == nil }) {
            note = "Some prompts had no usable FFF1 packet. Timing and byte relationships are incomplete."
        } else if candidates.isEmpty {
            note = "No stable Air Fry versus Reheat byte candidates in this small sample. Positions may include counters, checksums or unrelated state."
        } else {
            note = "Possible byte-position candidates found, but NOT verified as preset, temperature or timer fields."
        }
        return BLEStructureReport(totalFrames: idleCount + phaseCounts.reduce(0, +),
                                  idleFrames: idleCount,
                                  phaseFrames: phaseCounts,
                                  firstPromptDelayTenths: firstDelay,
                                  frameLengths: frameLengths,
                                  usablePairCount: pairs.count,
                                  changedPositions: changed.sorted(),
                                  offset2ChangedPairs: c2,
                                  offset5ChangedPairs: c5,
                                  changedTogetherPairs: both,
                                  byte2PlusOnePairs: plus2,
                                  byte5PlusOnePairs: plus5,
                                  constantMod256Sum: sameSum,
                                  constantXor: sameXor,
                                  sameAirFryChangedPositions: airRepeat,
                                  firstAirFryToReheatChanged: transition,
                                  candidateStablePresetPositions: candidates,
                                  truncated: truncated, note: note)
    }

    var safeSummary: String {
        func positions(_ arr: [Int]) -> String {
            arr.isEmpty ? "none" : arr.map(String.init).joined(separator: ",")
        }
        func times(_ arr: [Int?]) -> String {
            arr.map { value in
                guard let value else { return "none" }
                return String(format: "%.1f", Double(value) / 10.0) + "s"
            }.joined(separator: ",")
        }
        return [
            "Crisp Companion v0.1.6 / Structural BLE Probe / aggregate diagnostic only",
            "Physical prompts: Air Fry, Reheat, Air Fry (initially select Reheat)",
            "Idle FFF1 events: \(idleFrames)",
            "FFF1 events per prompt: \(phaseFrames.map(String.init).joined(separator: ","))",
            "First event after prompt (NOT exact tap latency): \(times(firstPromptDelayTenths))",
            "Observed packet lengths: \(positions(frameLengths))",
            "Comparable adjacent pairs: \(usablePairCount)",
            "All changed offsets (zero-based): \(positions(changedPositions))",
            "Offset 2 changed pairs: \(offset2ChangedPairs)",
            "Offset 5 changed pairs: \(offset5ChangedPairs)",
            "Offsets 2 and 5 changed together: \(changedTogetherPairs)",
            "Offset 2 +1 transitions: \(byte2PlusOnePairs)",
            "Offset 5 +1 transitions: \(byte5PlusOnePairs)",
            "Offset 2+5 constant modulo 256 (heuristic): \(constantMod256Sum)",
            "Offset 2 XOR 5 constant (heuristic): \(constantXor)",
            "Air Fry repeat changed offsets: \(positions(sameAirFryChangedPositions))",
            "First Air Fry -> Reheat changed offsets: \(positions(firstAirFryToReheatChanged))",
            "Candidate stable preset offsets: \(positions(candidateStablePresetPositions))",
            "Capture limit reached: \(truncated)",
            "No raw message values, stable hashes, Wi-Fi credentials, device IDs, or control instructions."
        ].joined(separator: "\n")
    }
}

final class BLEStructureProbeModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    enum Phase: Equatable { case waiting, idle, prompt(Int), complete }
    @Published private(set) var status = "Ready for a three-tap local Bluetooth observation."
    @Published private(set) var running = false
    @Published private(set) var listening = false
    @Published private(set) var phase: Phase = .waiting
    @Published private(set) var secondsLeft = 0
    @Published private(set) var idleCount = 0
    @Published private(set) var phaseCounts = [0, 0, 0]
    @Published private(set) var result: BLEStructureReport?

    private var central: CBCentralManager?
    private var selected: CBPeripheral?
    private var session: UUID?
    private var stageToken: UUID?
    private var ticker: Timer?
    private var stageStart = Date()
    private var stageEnd = Date()
    private var frames: [BLEStructureFrame] = []
    private var truncated = false

    var currentPreset: FryerPreset? {
        guard case .prompt(let index) = phase,
              BLEStructurePolicy.sequence.indices.contains(index) else { return nil }
        return BLEStructurePolicy.sequence[index]
    }

    func start() {
        guard !running else { return }
        clearLocalResults()
        running = true
        status = "Looking for CAF-P583S-KUS…"
        phase = .waiting
        let token = UUID()
        session = token
        DispatchQueue.main.asyncAfter(deadline: .now() + BLEStructurePolicy.connectionTimeout) { [weak self] in
            guard let self, self.session == token, !self.listening else { return }
            self.stop("Bluetooth connection or subscription timed out.")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + BLEStructurePolicy.sessionTimeout) { [weak self] in
            guard let self, self.session == token else { return }
            self.stop("Session timed out; no cooking commands were sent.")
        }
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main,
                options: [CBCentralManagerOptionShowPowerAlertKey: false])
        } else if let central {
            centralManagerDidUpdateState(central)
        }
    }

    func stop(_ message: String = "Stopped and Bluetooth disconnected.") {
        running = false
        listening = false
        session = nil
        stageToken = nil
        ticker?.invalidate()
        ticker = nil
        central?.stopScan()
        if let selected {
            selected.delegate = nil
            if selected.state != .disconnected { central?.cancelPeripheralConnection(selected) }
        }
        selected = nil
        frames.removeAll(keepingCapacity: false)
        secondsLeft = 0
        status = message
    }

    func clear() {
        stop("All research results cleared.")
        clearLocalResults()
    }

    private func clearLocalResults() {
        phase = .waiting
        phaseCounts = [0, 0, 0]
        idleCount = 0
        result = nil
        frames.removeAll(keepingCapacity: false)
        truncated = false
    }

    private func begin(_ next: Phase, duration: Int) {
        guard running, let token = session else { return }
        phase = next
        secondsLeft = duration
        stageStart = Date()
        stageEnd = stageStart.addingTimeInterval(TimeInterval(duration))
        let stage = UUID()
        stageToken = stage
        switch next {
        case .idle: status = "Hands off: untouched idle baseline."
        case .prompt(let n):
            status = "Tap \(BLEStructurePolicy.sequence[n].name) on the fryer's PHYSICAL panel. Never press Start."
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .waiting, .complete: return
        }
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, self.session == token, self.stageToken == stage else { return }
            self.secondsLeft = max(0, Int(ceil(self.stageEnd.timeIntervalSinceNow)))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(duration)) { [weak self] in
            guard let self, self.session == token, self.stageToken == stage else { return }
            self.next()
        }
    }

    private func next() {
        guard running else { return }
        switch phase {
        case .idle:
            begin(.prompt(0), duration: BLEStructurePolicy.phaseSeconds)
        case .prompt(let n) where n < 2:
            begin(.prompt(n+1), duration: BLEStructurePolicy.phaseSeconds)
        case .prompt:
            // Compute summary before disconnect; discard all data bytes immediately.
            result = BLEStructureReport.analyze(frames, phaseCounts: phaseCounts,
                                                idleCount: idleCount, truncated: truncated)
            phase = .complete
            stop("Analysis completed on your iPhone. Bluetooth disconnected.")
        case .waiting, .complete: break
        }
    }

    func centralManagerDidUpdateState(_ manager: CBCentralManager) {
        guard running else { return }
        switch manager.state {
        case .poweredOn:
            manager.scanForPeripherals(withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        case .poweredOff: stop("Bluetooth is off.")
        case .unauthorized: stop("Bluetooth permission denied in iPhone Settings.")
        case .unsupported: stop("This iPhone cannot use Bluetooth Low Energy.")
        case .unknown, .resetting: status = "Waiting for Bluetooth…"
        @unknown default: stop("Unknown Bluetooth state.")
        }
    }

    func centralManager(_ manager: CBCentralManager,
                        didDiscover device: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard running, selected == nil else { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? device.name ?? ""
        guard BLEObservationPolicy.matchesExactName(name) else { return }
        selected = device
        device.delegate = self
        manager.stopScan()
        status = "Model-name match found. Connecting to the FFF1 notification channel…"
        manager.connect(device, options: nil)
    }

    func centralManager(_ manager: CBCentralManager, didConnect device: CBPeripheral) {
        guard running, selected?.identifier == device.identifier else {
            manager.cancelPeripheralConnection(device)
            return
        }
        device.discoverServices([BLEStructurePolicy.targetService])
    }

    func centralManager(_ manager: CBCentralManager,
                        didFailToConnect device: CBPeripheral, error: Error?) {
        guard selected?.identifier == device.identifier else { return }
        stop("Bluetooth connection failed.")
    }

    func centralManager(_ manager: CBCentralManager,
                        didDisconnectPeripheral device: CBPeripheral, error: Error?) {
        guard running, selected?.identifier == device.identifier else { return }
        stop("Fryer disconnected before this test finished.")
    }

    func peripheral(_ device: CBPeripheral, didDiscoverServices error: Error?) {
        guard running, selected?.identifier == device.identifier else { return }
        guard error == nil, let services = device.services,
              let service = services.first(where: { $0.uuid == BLEStructurePolicy.targetService }) else {
            stop("FFF0 Bluetooth service unavailable.")
            return
        }
        device.discoverCharacteristics([BLEStructurePolicy.targetCharacteristic], for: service)
    }

    func peripheral(_ device: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard running, selected?.identifier == device.identifier else { return }
        guard error == nil, service.uuid == BLEStructurePolicy.targetService,
              let characteristic = service.characteristics?.first(where: {
                  BLEStructurePolicy.isPermitted(service: service.uuid, characteristic: $0.uuid)
                  && $0.properties.contains(.notify)
              }) else {
            stop("FFF1 notification characteristic unavailable.")
            return
        }
        // CCCD subscription changes descriptor configuration, but no characteristic
        // values or heater / firmware update commands are written.
        device.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ device: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard running, selected?.identifier == device.identifier,
              let service = characteristic.service,
              BLEStructurePolicy.isPermitted(service: service.uuid,
                                             characteristic: characteristic.uuid) else { return }
        if error == nil && characteristic.isNotifying {
            if !listening {
                listening = true
                begin(.idle, duration: BLEStructurePolicy.idleSeconds)
            }
        } else {
            stop("The FFF1 notification subscription was refused.")
        }
    }

    func peripheral(_ device: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard running, listening, selected?.identifier == device.identifier,
              error == nil, characteristic.isNotifying,
              let service = characteristic.service,
              BLEStructurePolicy.isPermitted(service: service.uuid,
                                             characteristic: characteristic.uuid),
              let value = characteristic.value else { return }
        let phaseIndex: Int
        switch phase {
        case .idle:
            idleCount += 1
            phaseIndex = -1
        case .prompt(let n):
            phaseCounts[n] += 1
            phaseIndex = n
        case .waiting, .complete: return
        }
        guard value.count > 0 && value.count <= BLEStructurePolicy.maxBytesPerFrame else {
            truncated = true
            return
        }
        if frames.filter({ $0.phase == phaseIndex }).count >= BLEStructurePolicy.maxFramesPerPhase {
            truncated = true
            return
        }
        let elapsed = max(0, Int((Date().timeIntervalSince(stageStart) * 10).rounded()))
        frames.append(BLEStructureFrame(phase: phaseIndex,
                                        elapsedTenths: elapsed, bytes: Data(value)))
    }
}

struct BLEStructureProbeView: View {
    @StateObject private var probe = BLEStructureProbeModel()
    @State private var safetyConfirmed = false
    @State private var copied = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeading(eyebrow: "PRIVATE LOCAL RESEARCH",
                            title: "Signal Structure.",
                            subtitle: "One start, three physical taps, automatic byte analysis.")
                CrispCard {
                    Label("Quick, read-only test", systemImage: "shield.lefthalf.filled")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Before opening the test, select Reheat on the fryer without starting cooking. It must remain idle and cool. The app only subscribes to FFF1 notifications, configuring a BLE CCCD descriptor. No heater, firmware, Wi-Fi, or cloud commands.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Toggle(isOn: $safetyConfirmed) {
                        Text("Fryer is idle and not heating. I have selected Reheat.")
                            .font(.subheadline).foregroundColor(CrispPalette.cream)
                    }
                    .tint(CrispPalette.gold).disabled(probe.running)
                    Button {
                        copied = false
                        probe.start()
                    } label: {
                        Label("Start automatic signal test", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                    .disabled(!safetyConfirmed || probe.running)
                }
                CrispCard {
                    Text("LIVE INSTRUCTIONS")
                        .font(.caption.bold()).foregroundColor(CrispPalette.gold)
                    if probe.running && probe.listening {
                        switch probe.phase {
                        case .idle:
                            Text("DON'T TOUCH THE FRYER")
                                .font(.title2.bold()).foregroundColor(CrispPalette.cream)
                        case .prompt:
                            Text("TAP \(probe.currentPreset?.name.uppercased() ?? "PRESET")")
                                .font(.title2.bold()).foregroundColor(CrispPalette.gold)
                        case .waiting, .complete:
                            Text("Finishing").font(.title2.bold())
                        }
                        Text("\(probe.secondsLeft)s")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .monospacedDigit().foregroundColor(CrispPalette.cream)
                    } else if probe.running {
                        ProgressView("Connecting to COSORI…").tint(CrispPalette.gold)
                    }
                    Text(probe.status).font(.footnote).foregroundColor(CrispPalette.muted)
                    if probe.running {
                        Button("Stop and disconnect", role: .destructive) { probe.stop() }
                            .buttonStyle(.bordered)
                    }
                }
                CrispCard {
                    Label("Automatic physical prompts", systemImage: "list.number")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("After ten seconds untouched, tap Air Fry, then Reheat, then Air Fry again. Each prompt lasts nine seconds and advances automatically. Never press the fryer's Start button.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    ForEach(Array(BLEStructurePolicy.sequence.enumerated()), id: \.offset) { index, preset in
                        HStack {
                            Text("\(index + 1). \(preset.name)").foregroundColor(CrispPalette.cream)
                            Spacer()
                            Text("\(probe.phaseCounts[index]) events")
                                .font(.caption).foregroundColor(CrispPalette.muted)
                        }
                        Divider()
                    }
                }
                if let result = probe.result {
                    CrispCard {
                        Label("Structural clues", systemImage: "waveform.path.ecg")
                            .font(.headline).foregroundColor(CrispPalette.gold)
                        Text("\(result.totalFrames) notifications, \(result.usablePairCount) comparable adjacent pairs")
                            .font(.subheadline).foregroundColor(CrispPalette.cream)
                        Text("Positions 2 and 5 changed together: \(result.changedTogetherPairs)")
                            .font(.subheadline).foregroundColor(CrispPalette.gold)
                        Text("Potential preset offsets: \(positionList(result.candidateStablePresetPositions))")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text(result.note).font(.footnote).foregroundColor(CrispPalette.muted)
                        Button {
                            UIPasteboard.general.string = result.safeSummary
                            copied = true
                        } label: {
                            Label(copied ? "Safe report copied" : "Copy safe report", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                        .foregroundColor(CrispPalette.background)
                    }
                }
                CrispCard {
                    Label("Privacy and limits", systemImage: "lock.shield")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Up to 12 short frames per phase are compared locally and discarded when the session ends. Only counts, byte-position numbers and time from each prompt are exportable. Prompt timing is not an exact measurement of when you pressed the fryer button. Equal sums or XORs are clues, not proof of a checksum or local control.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    if !probe.running {
                        Button("Clear results") {
                            probe.clear()
                            safetyConfirmed = false
                            copied = false
                        }.buttonStyle(.bordered)
                    }
                }
            }.padding(20)
        }
        .background(CrispPalette.background)
        .navigationTitle("Signal Structure")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { probe.clear() }
        .onChange(of: scenePhase) { phase in
            if phase != .active { probe.clear() }
        }
    }

    private func positionList(_ items: [Int]) -> String {
        items.isEmpty ? "none" : items.map(String.init).joined(separator: ", ")
    }
}
