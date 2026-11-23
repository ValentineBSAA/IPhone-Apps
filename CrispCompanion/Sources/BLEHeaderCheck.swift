import SwiftUI
import CoreBluetooth
import UIKit

/// Investigatory only. The kettle reference protocol is NOT confirmed for this air fryer.
/// The only permitted GATT action is notification subscription (CCCD descriptor configuration).
enum BLEHeaderCheckPolicy {
    static let baselineSeconds = 10
    static let physicalSeconds = 12
    static let connectTimeoutSeconds: TimeInterval = 20
    static let sessionLimitSeconds: TimeInterval = 60
    static let maxFrames = 64
    static let service = BLEObservationPolicy.serialService
    static let notification = BLEObservationPolicy.serialNotify

    static func permits(_ service: CBUUID, _ characteristic: CBUUID) -> Bool {
        service == self.service && characteristic == notification
    }
}

/// Only aggregate counts. No complete frames are retained, shown, uploaded, or copied.
struct BLEHeaderReport: Equatable {
    let idleNotifications: Int
    let changeNotifications: Int
    let tenByteFrames: Int
    let shortFrames: Int
    let headerCandidates: Int
    let a5MagicMatches: Int
    let knownKettleTypes: Int
    let declaredLengthMatches: Int
    let fullKettleHeaderMatches: Int
    let comparedAdjacentPairs: Int
    let sequencePlusOnePairs: Int
    let constantSumPairs: Int
    let capped: Bool

    var safeText: String {
        return [
            "Crisp Companion v0.1.7 / Passive Header Check / counts only",
            "Fryer initial mode: Reheat; physical change: Air Fry (no Start)",
            "Untouched baseline FFF1 notifications: \(idleNotifications)",
            "Air Fry prompt FFF1 notifications: \(changeNotifications)",
            "10-byte notifications: \(tenByteFrames)",
            "Shorter than six bytes: \(shortFrames)",
            "Header-sized notifications (6+ bytes): \(headerCandidates)",
            "First-byte kettle magic A5 matches: \(a5MagicMatches)",
            "Known kettle packet type 12/22 matches: \(knownKettleTypes)",
            "Header declared payload length matches: \(declaredLengthMatches)",
            "All three kettle header predicates match: \(fullKettleHeaderMatches)",
            "Adjacent 6+-byte frame pairs: \(comparedAdjacentPairs)",
            "Byte 2 increments by one (modulo 256): \(sequencePlusOnePairs)",
            "Byte 2 + byte 5 constant across adjacent frames: \(constantSumPairs)",
            "Capture limit reached: \(capped)",
            "Result is structural compatibility only, not a confirmed fryer protocol.",
            "No packet contents, variable byte values, IDs, fingerprints, SSIDs, keys or cooking commands included."
        ].joined(separator: "\n")
    }
}

struct BLEHeaderCounter {
    private(set) var idleNotifications = 0
    private(set) var changeNotifications = 0
    private(set) var tenByteFrames = 0
    private(set) var shortFrames = 0
    private(set) var headerCandidates = 0
    private(set) var a5MagicMatches = 0
    private(set) var knownKettleTypes = 0
    private(set) var declaredLengthMatches = 0
    private(set) var fullKettleHeaderMatches = 0
    private(set) var comparedAdjacentPairs = 0
    private(set) var sequencePlusOnePairs = 0
    private(set) var constantSumPairs = 0
    private(set) var capped = false

    // These two temporary metadata values are kept only to compare successive messages.
    // They are cleared by reset() on completion, navigation, and app background.
    private var previousSeq: UInt8?
    private var previousSum: UInt8?
    private var packetCount = 0

    mutating func observe(_ data: Data, duringIdle: Bool) {
        if duringIdle {
            idleNotifications += 1
        } else {
            changeNotifications += 1
        }
        guard packetCount < BLEHeaderCheckPolicy.maxFrames else {
            capped = true
            return
        }
        packetCount += 1
        if data.count == 10 { tenByteFrames += 1 }
        guard data.count >= 6 else {
            shortFrames += 1
            previousSeq = nil
            previousSum = nil
            return
        }
        headerCandidates += 1
        let magic = data[0] == 0xA5
        let knownType = data[1] == 0x12 || data[1] == 0x22
        let payloadSize = Int(data[3]) | (Int(data[4]) << 8)
        let lengthMatch = payloadSize == data.count - 6
        if magic { a5MagicMatches += 1 }
        if knownType { knownKettleTypes += 1 }
        if lengthMatch { declaredLengthMatches += 1 }
        if magic && knownType && lengthMatch { fullKettleHeaderMatches += 1 }

        let sequence = data[2]
        let sum = sequence &+ data[5]
        if let previousSeq, let previousSum {
            comparedAdjacentPairs += 1
            if sequence == previousSeq &+ 1 { sequencePlusOnePairs += 1 }
            if sum == previousSum { constantSumPairs += 1 }
        }
        previousSeq = sequence
        previousSum = sum
    }

    func summary() -> BLEHeaderReport {
        BLEHeaderReport(
            idleNotifications: idleNotifications,
            changeNotifications: changeNotifications,
            tenByteFrames: tenByteFrames,
            shortFrames: shortFrames,
            headerCandidates: headerCandidates,
            a5MagicMatches: a5MagicMatches,
            knownKettleTypes: knownKettleTypes,
            declaredLengthMatches: declaredLengthMatches,
            fullKettleHeaderMatches: fullKettleHeaderMatches,
            comparedAdjacentPairs: comparedAdjacentPairs,
            sequencePlusOnePairs: sequencePlusOnePairs,
            constantSumPairs: constantSumPairs,
            capped: capped
        )
    }

    mutating func reset() { self = BLEHeaderCounter() }
}

final class BLEHeaderCheckModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    enum Stage: Equatable { case disconnected, connecting, baseline, changing, finished }
    @Published private(set) var status = "Ready for the passive header check."
    @Published private(set) var running = false
    @Published private(set) var stage: Stage = .disconnected
    @Published private(set) var secondsLeft = 0
    @Published private(set) var idleCount = 0
    @Published private(set) var changeCount = 0
    @Published private(set) var report: BLEHeaderReport?

    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var sessionID: UUID?
    private var stageID: UUID?
    private var countdownTimer: Timer?
    private var deadline = Date()
    private var listening = false
    private var accumulator = BLEHeaderCounter()

    func start() {
        guard !running else { return }
        clearReport()
        running = true
        stage = .connecting
        status = "Connecting to the exact COSORI model name…"
        let token = UUID()
        sessionID = token
        DispatchQueue.main.asyncAfter(deadline: .now() + BLEHeaderCheckPolicy.connectTimeoutSeconds) { [weak self] in
            guard let self, self.sessionID == token, !self.listening else { return }
            self.stop("Connection or notification subscription timed out.")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + BLEHeaderCheckPolicy.sessionLimitSeconds) { [weak self] in
            guard let self, self.sessionID == token else { return }
            self.stop("Safety session limit reached. Bluetooth disconnected.")
        }
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main,
                options: [CBCentralManagerOptionShowPowerAlertKey: false])
        } else if let central {
            centralManagerDidUpdateState(central)
        }
    }

    func stop(_ message: String = "Stopped. Bluetooth disconnected.") {
        running = false
        listening = false
        sessionID = nil
        stageID = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        central?.stopScan()
        if let peripheral {
            peripheral.delegate = nil
            if peripheral.state != .disconnected { central?.cancelPeripheralConnection(peripheral) }
        }
        peripheral = nil
        accumulator.reset()
        secondsLeft = 0
        if stage != .finished { stage = .disconnected }
        status = message
    }

    func clear() {
        stop("Results cleared. No Bluetooth connection.")
        clearReport()
        stage = .disconnected
    }

    private func clearReport() {
        accumulator.reset()
        report = nil
        idleCount = 0
        changeCount = 0
    }

    private func beginStage(_ target: Stage, duration: Int) {
        guard running, let token = sessionID else { return }
        stage = target
        secondsLeft = duration
        deadline = Date().addingTimeInterval(TimeInterval(duration))
        let thisStage = UUID()
        stageID = thisStage
        if target == .baseline {
            status = "Do not touch the fryer during the 10-second baseline."
        } else {
            status = "Tap AIR FRY on the physical fryer once. Never press Start."
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, self.sessionID == token, self.stageID == thisStage else { return }
            self.secondsLeft = max(0, Int(ceil(self.deadline.timeIntervalSinceNow)))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(duration)) { [weak self] in
            guard let self, self.sessionID == token, self.stageID == thisStage else { return }
            self.advance()
        }
    }

    private func advance() {
        guard running else { return }
        switch stage {
        case .baseline:
            beginStage(.changing, duration: BLEHeaderCheckPolicy.physicalSeconds)
        case .changing:
            // Aggregate first, then immediately zero the ephemeral comparison bytes.
            report = accumulator.summary()
            stage = .finished
            stop("Header compatibility check finished. Bluetooth disconnected.")
        case .connecting, .disconnected, .finished:
            break
        }
    }

    func centralManagerDidUpdateState(_ manager: CBCentralManager) {
        guard running else { return }
        switch manager.state {
        case .poweredOn:
            manager.scanForPeripherals(withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        case .poweredOff: stop("Bluetooth is switched off.")
        case .unauthorized: stop("Bluetooth access denied in iPhone Settings.")
        case .unsupported: stop("This iPhone does not support Bluetooth Low Energy.")
        case .unknown, .resetting: status = "Waiting for Bluetooth…"
        @unknown default: stop("Unknown Bluetooth state.")
        }
    }

    func centralManager(_ manager: CBCentralManager,
                        didDiscover found: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard running, peripheral == nil else { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? found.name ?? ""
        guard BLEObservationPolicy.matchesExactName(name) else { return }
        peripheral = found
        found.delegate = self
        manager.stopScan()
        status = "Exact model-name match. Discovering only FFF0/FFF1…"
        manager.connect(found, options: nil)
    }

    func centralManager(_ manager: CBCentralManager, didConnect found: CBPeripheral) {
        guard running, peripheral?.identifier == found.identifier else {
            manager.cancelPeripheralConnection(found)
            return
        }
        found.discoverServices([BLEHeaderCheckPolicy.service])
    }

    func centralManager(_ manager: CBCentralManager,
                        didFailToConnect found: CBPeripheral, error: Error?) {
        guard peripheral?.identifier == found.identifier else { return }
        stop("Bluetooth connection failed.")
    }

    func centralManager(_ manager: CBCentralManager,
                        didDisconnectPeripheral found: CBPeripheral, error: Error?) {
        guard running, peripheral?.identifier == found.identifier else { return }
        stop("Fryer disconnected during passive test.")
    }

    func peripheral(_ found: CBPeripheral, didDiscoverServices error: Error?) {
        guard running, peripheral?.identifier == found.identifier else { return }
        guard error == nil, let services = found.services,
              let service = services.first(where: { $0.uuid == BLEHeaderCheckPolicy.service }) else {
            stop("FFF0 service not found."); return
        }
        found.discoverCharacteristics([BLEHeaderCheckPolicy.notification], for: service)
    }

    func peripheral(_ found: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard running, peripheral?.identifier == found.identifier else { return }
        guard error == nil,
              let characteristic = service.characteristics?.first(where: {
                BLEHeaderCheckPolicy.permits(service.uuid, $0.uuid)
                    && $0.properties.contains(.notify)
              }) else {
            stop("FFF1 notifications unavailable."); return
        }
        // setNotifyValue configures CCCD descriptor only; there are NO
        // characteristic-value writes/reads, heater instructions or OAD.
        found.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ found: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard running, peripheral?.identifier == found.identifier,
              let service = characteristic.service,
              BLEHeaderCheckPolicy.permits(service.uuid, characteristic.uuid) else { return }
        if error == nil && characteristic.isNotifying {
            if !listening {
                listening = true
                beginStage(.baseline, duration: BLEHeaderCheckPolicy.baselineSeconds)
            }
        } else {
            stop("FFF1 notification subscription unavailable.")
        }
    }

    func peripheral(_ found: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard running, listening, peripheral?.identifier == found.identifier,
              error == nil, characteristic.isNotifying,
              let service = characteristic.service,
              BLEHeaderCheckPolicy.permits(service.uuid, characteristic.uuid),
              let data = characteristic.value else { return }
        switch stage {
        case .baseline:
            accumulator.observe(data, duringIdle: true)
            idleCount += 1
        case .changing:
            accumulator.observe(data, duringIdle: false)
            changeCount += 1
        case .disconnected, .connecting, .finished: return
        }
    }
}

struct BLEHeaderCheckView: View {
    @StateObject private var probe = BLEHeaderCheckModel()
    @State private var confirmed = false
    @State private var copied = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeading(eyebrow: "CLOUD-FREE SIGNAL RESEARCH",
                            title: "Header Check.",
                            subtitle: "One start, one physical tap, no repeated preset marathons.")
                CrispCard {
                    Label("Safe passive observation", systemImage: "shield.lefthalf.filled")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("First select Reheat on the physical fryer without starting it. This diagnostic subscribes only to FFF1. Subscription configures a Bluetooth CCCD descriptor, but it never sends operating commands, touches firmware update services, or starts heating.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Toggle(isOn: $confirmed) {
                        Text("Reheat selected. Fryer is idle and NOT heating.")
                            .font(.subheadline).foregroundColor(CrispPalette.cream)
                    }
                    .tint(CrispPalette.gold)
                    .disabled(probe.running)
                    Button {
                        copied = false
                        probe.start()
                    } label: {
                        Label("Start private header check", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                    .disabled(!confirmed || probe.running)
                }
                CrispCard {
                    Text("LIVE PROMPT").font(.caption.bold()).foregroundColor(CrispPalette.gold)
                    if probe.running {
                        switch probe.stage {
                        case .connecting:
                            ProgressView("Connecting…").tint(CrispPalette.gold)
                        case .baseline:
                            Text("LEAVE FRYER UNTOUCHED")
                                .font(.title2.bold()).foregroundColor(CrispPalette.cream)
                        case .changing:
                            Text("TAP AIR FRY ONCE")
                                .font(.title2.bold()).foregroundColor(CrispPalette.gold)
                        case .disconnected, .finished:
                            EmptyView()
                        }
                        if probe.secondsLeft > 0 {
                            Text("\(probe.secondsLeft)s")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .monospacedDigit().foregroundColor(CrispPalette.cream)
                        }
                    }
                    Text(probe.status)
                        .font(.subheadline).foregroundColor(CrispPalette.muted)
                    HStack {
                        Text("Idle events: \(probe.idleCount)")
                        Spacer()
                        Text("Tap events: \(probe.changeCount)")
                    }
                    .font(.caption.monospacedDigit()).foregroundColor(CrispPalette.muted)
                    if probe.running {
                        Button("Stop and disconnect", role: .destructive) { probe.stop() }
                            .buttonStyle(.bordered)
                    }
                }
                if let report = probe.report {
                    CrispCard {
                        Label("Header compatibility result", systemImage: "checkmark.shield")
                            .font(.headline).foregroundColor(CrispPalette.gold)
                        Text("\(report.fullKettleHeaderMatches) complete kettle-style header matches from \(report.headerCandidates) header-sized notifications.")
                            .font(.subheadline).foregroundColor(CrispPalette.cream)
                        Text("Magic A5 matched: \(report.a5MagicMatches)")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text("Known type matched: \(report.knownKettleTypes)")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text("Payload length matched: \(report.declaredLengthMatches)")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text("Sequence +1 comparisons: \(report.sequencePlusOnePairs) / \(report.comparedAdjacentPairs)")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text(report.headerCandidates == 0
                             ? "No full header available. The result is inconclusive."
                             : "A matching header would suggest structural similarity only. It cannot establish a safe air-fryer status or control protocol.")
                            .font(.footnote).foregroundColor(CrispPalette.muted)
                        Button {
                            UIPasteboard.general.string = report.safeText
                            copied = true
                        } label: {
                            Label(copied ? "Safe results copied" : "Copy safe report",
                                  systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(CrispPalette.gold)
                        .foregroundColor(CrispPalette.background)
                    }
                }
                CrispCard {
                    Label("Privacy and research limits", systemImage: "lock.shield")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("The header check examines incoming packet bytes only inside a Bluetooth callback. It retains no raw frames or message fingerprints. The copyable summary contains counts and structural match results only. The COSORI kettle is a different appliance; shared Bluetooth identifiers and even a matching header would not prove compatible controls. Never press the fryer's Start button during testing.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    if !probe.running {
                        Button("Clear local results") {
                            probe.clear()
                            confirmed = false
                            copied = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(20)
        }
        .background(CrispPalette.background)
        .navigationTitle("Header Check")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { probe.clear() }
        .onChange(of: scenePhase) { next in
            if next != .active { probe.clear() }
        }
    }
}
