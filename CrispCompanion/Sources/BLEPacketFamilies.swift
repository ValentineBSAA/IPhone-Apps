import SwiftUI
import CoreBluetooth
import UIKit

/// One-start, three-tap passive study. No operational GATT commands are sent.
/// A "family" is an anonymous label for a repeatedly observed byte-1 value,
/// NOT a decoded message type or a compatible COSORI protocol.
enum BLEPacketFamilyPolicy {
    static let baselineSeconds = 10
    static let windowSeconds = 9
    static let connectionLimitSeconds: TimeInterval = 20
    static let sessionLimitSeconds: TimeInterval = 80
    static let maximumAnalyzedFrames = 64
    static let sequence: [FryerPreset] = [.airFry, .reheat, .airFry]
    static let service = BLEObservationPolicy.serialService
    static let notify = BLEObservationPolicy.serialNotify

    static func allows(_ service: CBUUID, _ characteristic: CBUUID) -> Bool {
        service == self.service && characteristic == notify
    }
}

/// Public-safe result: only event counts, structural predicates, and anonymous labels.
/// Raw bytes and the original type values are NOT included.
struct BLEPacketFamilyReport: Equatable {
    let idleEvents: Int
    let stepEvents: [Int]
    let analyzedFrames: Int
    let tenByteFrames: Int
    let shortFrames: Int
    let a5MagicMatches: Int
    let declaredLengthMatches: Int
    let bothMagicAndLengthMatches: Int
    let knownKettleTypeMatches: Int
    let fullDocumentedKettleTypeMatches: Int
    let distinctAnonymousTypes: Int
    let anonymousTypeDistribution: [String]
    let equalLengthAdjacentPairs: Int
    let sameAnonymousTypePairs: Int
    let sequencePlusOnePairs: Int
    let constantSequenceSumPairs: Int
    let packetLengthSet: [Int]
    let capped: Bool

    var safeText: String {
        [
            "Crisp Companion v0.1.8 / Packet Families / anonymous type labels only",
            "Initial physical preset: Reheat (never press Start)",
            "Automatic sequence: Air Fry → Reheat → Air Fry",
            "Idle FFF1 notifications: \(idleEvents)",
            "FFF1 notifications per prompt: \(stepEvents.map(String.init).joined(separator: ","))",
            "Frames analyzed: \(analyzedFrames)",
            "Observed packet lengths: \(packetLengthSet.map(String.init).joined(separator: ","))",
            "10-byte frames: \(tenByteFrames)",
            "Short frames (<6 bytes): \(shortFrames)",
            "A5 starting byte: \(a5MagicMatches)",
            "Declared payload length matches: \(declaredLengthMatches)",
            "A5 AND length matches: \(bothMagicAndLengthMatches)",
            "Documented kettle types 12/22: \(knownKettleTypeMatches)",
            "Full documented kettle type/header matches: \(fullDocumentedKettleTypeMatches)",
            "Distinct anonymous byte-1 categories: \(distinctAnonymousTypes)",
            "Idle categories: \(anonymousTypeDistribution[0])",
            "Air Fry 1 categories: \(anonymousTypeDistribution[1])",
            "Reheat categories: \(anonymousTypeDistribution[2])",
            "Air Fry 2 categories: \(anonymousTypeDistribution[3])",
            "Equal-length adjacent frame pairs: \(equalLengthAdjacentPairs)",
            "Same category in adjacent pairs: \(sameAnonymousTypePairs)",
            "Byte 2 +1 transitions: \(sequencePlusOnePairs)",
            "Byte 2+5 sum constant in adjacent pairs: \(constantSequenceSumPairs)",
            "Frame cap reached: \(capped)",
            "Categories A/B/C are arbitrary labels, not actual packet byte values.",
            "Structural resemblance does not establish a fryer status or control protocol.",
            "No raw payloads, actual type values, MAC addresses, tokens, keys, or cooking commands."
        ].joined(separator: "\n")
    }
}

/// Keeps only the minimum byte fields during the session. No complete BLE frame
/// leaves the CoreBluetooth callback, and even the ephemeral fields disappear on
/// completion, Stop, app background or screen exit.
struct BLEPacketFamilyAccumulator {
    private(set) var idleEvents = 0
    private(set) var stepEvents = [0, 0, 0]
    private(set) var analyzedFrames = 0
    private(set) var tenByteFrames = 0
    private(set) var shortFrames = 0
    private(set) var a5MagicMatches = 0
    private(set) var declaredLengthMatches = 0
    private(set) var bothMagicAndLengthMatches = 0
    private(set) var knownKettleTypeMatches = 0
    private(set) var fullDocumentedKettleTypeMatches = 0
    private(set) var equalLengthAdjacentPairs = 0
    private(set) var sameAnonymousTypePairs = 0
    private(set) var sequencePlusOnePairs = 0
    private(set) var constantSequenceSumPairs = 0
    private(set) var capped = false

    // Ephemeral: raw byte-1 values are retained only as opaque local match keys.
    // Neither this array nor previous sequence/check values appear in safeReport().
    private var typeValues: [UInt8] = []
    private var typeByPhase: [[Int]] = [[], [], [], []]
    private var previousSequence: UInt8?
    private var previousSequenceSum: UInt8?
    private var previousTypeCategory: Int?
    private var previousLength: Int?
    private var observedLengths = Set<Int>()

    mutating func observe(_ payload: Data, phase: Int) {
        guard (-1...2).contains(phase) else { return }
        if phase == -1 { idleEvents += 1 } else { stepEvents[phase] += 1 }

        guard analyzedFrames < BLEPacketFamilyPolicy.maximumAnalyzedFrames else {
            capped = true
            return
        }
        analyzedFrames += 1
        observedLengths.insert(payload.count)
        if payload.count == 10 { tenByteFrames += 1 }
        guard payload.count >= 6 else {
            shortFrames += 1
            previousSequence = nil
            previousSequenceSum = nil
            previousTypeCategory = nil
            previousLength = nil
            return
        }

        let magic = payload[0] == 0xA5
        let known = payload[1] == 0x12 || payload[1] == 0x22
        let length = Int(payload[3]) | (Int(payload[4]) << 8)
        let lengthMatches = length == payload.count - 6
        if magic { a5MagicMatches += 1 }
        if known { knownKettleTypeMatches += 1 }
        if lengthMatches { declaredLengthMatches += 1 }
        if magic && lengthMatches { bothMagicAndLengthMatches += 1 }
        if magic && known && lengthMatches { fullDocumentedKettleTypeMatches += 1 }

        let typeValue = payload[1]
        let typeCategory: Int
        if let existing = typeValues.firstIndex(of: typeValue) {
            typeCategory = existing
        } else {
            typeCategory = typeValues.count
            typeValues.append(typeValue)
        }
        typeByPhase[phase + 1].append(typeCategory)

        let sequence = payload[2]
        let sequenceSum = sequence &+ payload[5]
        if let oldSeq = previousSequence,
           let oldSum = previousSequenceSum,
           let oldType = previousTypeCategory,
           previousLength == payload.count {
            equalLengthAdjacentPairs += 1
            if oldType == typeCategory { sameAnonymousTypePairs += 1 }
            if sequence == oldSeq &+ 1 { sequencePlusOnePairs += 1 }
            if sequenceSum == oldSum { constantSequenceSumPairs += 1 }
        }
        previousSequence = sequence
        previousSequenceSum = sequenceSum
        previousTypeCategory = typeCategory
        previousLength = payload.count
    }

    func safeReport() -> BLEPacketFamilyReport {
        func label(_ index: Int) -> String {
            if index < 26 {
                return String(UnicodeScalar(65 + index)!)
            }
            return "T\(index + 1)"
        }
        let distribution = typeByPhase.map { categories -> String in
            if categories.isEmpty { return "none" }
            let unique = Set(categories).sorted()
            return unique.map { category -> String in
                let count = categories.filter { $0 == category }.count
                return "\(label(category))×\(count)"
            }.joined(separator: ",")
        }
        return BLEPacketFamilyReport(
            idleEvents: idleEvents, stepEvents: stepEvents,
            analyzedFrames: analyzedFrames, tenByteFrames: tenByteFrames,
            shortFrames: shortFrames, a5MagicMatches: a5MagicMatches,
            declaredLengthMatches: declaredLengthMatches,
            bothMagicAndLengthMatches: bothMagicAndLengthMatches,
            knownKettleTypeMatches: knownKettleTypeMatches,
            fullDocumentedKettleTypeMatches: fullDocumentedKettleTypeMatches,
            distinctAnonymousTypes: typeValues.count,
            anonymousTypeDistribution: distribution,
            equalLengthAdjacentPairs: equalLengthAdjacentPairs,
            sameAnonymousTypePairs: sameAnonymousTypePairs,
            sequencePlusOnePairs: sequencePlusOnePairs,
            constantSequenceSumPairs: constantSequenceSumPairs,
            packetLengthSet: observedLengths.sorted(),
            capped: capped
        )
    }

    mutating func clear() {
        self = BLEPacketFamilyAccumulator()
    }
}

final class BLEPacketFamilyModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    enum Stage: Equatable { case disconnected, connecting, idle, physical(Int), finished }

    @Published private(set) var status = "Ready for a three-step passive packet-family test."
    @Published private(set) var running = false
    @Published private(set) var subscribed = false
    @Published private(set) var stage: Stage = .disconnected
    @Published private(set) var secondsLeft = 0
    @Published private(set) var idleEvents = 0
    @Published private(set) var stepEvents = [0, 0, 0]
    @Published private(set) var result: BLEPacketFamilyReport?

    private var central: CBCentralManager?
    private var selected: CBPeripheral?
    private var session: UUID?
    private var stageToken: UUID?
    private var ticker: Timer?
    private var stageEnd = Date.distantPast
    private var stats = BLEPacketFamilyAccumulator()

    var currentPreset: FryerPreset? {
        guard case .physical(let index) = stage,
              BLEPacketFamilyPolicy.sequence.indices.contains(index) else { return nil }
        return BLEPacketFamilyPolicy.sequence[index]
    }

    func start() {
        guard !running else { return }
        clearResults()
        running = true
        stage = .connecting
        status = "Finding CAF-P583S-KUS for passive notifications…"
        let activeSession = UUID()
        session = activeSession
        DispatchQueue.main.asyncAfter(deadline: .now() + BLEPacketFamilyPolicy.connectionLimitSeconds) { [weak self] in
            guard let self, self.session == activeSession, !self.subscribed else { return }
            self.stop("Connection/notification subscription timed out.")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + BLEPacketFamilyPolicy.sessionLimitSeconds) { [weak self] in
            guard let self, self.session == activeSession else { return }
            self.stop("Session time limit reached. Bluetooth disconnected.")
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
        subscribed = false
        session = nil
        stageToken = nil
        ticker?.invalidate()
        ticker = nil
        central?.stopScan()
        if let selected {
            selected.delegate = nil
            if selected.state != .disconnected {
                central?.cancelPeripheralConnection(selected)
            }
        }
        selected = nil
        stats.clear()
        secondsLeft = 0
        if stage != .finished { stage = .disconnected }
        status = message
    }

    func erase() {
        stop("Session cleared. Nothing retained.")
        clearResults()
        stage = .disconnected
    }

    private func clearResults() {
        stats.clear()
        result = nil
        idleEvents = 0
        stepEvents = [0, 0, 0]
    }

    private func begin(_ next: Stage, seconds: Int) {
        guard running, let activeSession = session else { return }
        stage = next
        secondsLeft = seconds
        stageEnd = Date().addingTimeInterval(TimeInterval(seconds))
        let token = UUID()
        stageToken = token
        switch next {
        case .idle:
            status = "Hands off the fryer: collecting the untouched baseline."
        case .physical(let i):
            status = "Tap \(BLEPacketFamilyPolicy.sequence[i].name) ON THE FRYER once. Never press Start."
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        default: return
        }
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, self.session == activeSession, self.stageToken == token else { return }
            self.secondsLeft = max(0, Int(ceil(self.stageEnd.timeIntervalSinceNow)))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(seconds)) { [weak self] in
            guard let self, self.session == activeSession, self.stageToken == token else { return }
            self.advance()
        }
    }

    private func advance() {
        guard running else { return }
        switch stage {
        case .idle:
            begin(.physical(0), seconds: BLEPacketFamilyPolicy.windowSeconds)
        case .physical(let index) where index < 2:
            begin(.physical(index + 1), seconds: BLEPacketFamilyPolicy.windowSeconds)
        case .physical:
            result = stats.safeReport()
            stage = .finished
            stop("Passive frame-family comparison complete. Bluetooth disconnected.")
        case .connecting, .disconnected, .finished: break
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
        case .unsupported: stop("Bluetooth Low Energy unavailable.")
        case .unknown, .resetting: status = "Waiting for Bluetooth…"
        @unknown default: stop("Unknown Bluetooth state.")
        }
    }

    func centralManager(_ manager: CBCentralManager,
                        didDiscover found: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard running, selected == nil else { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? found.name ?? ""
        guard BLEObservationPolicy.matchesExactName(name) else { return }
        selected = found
        found.delegate = self
        manager.stopScan()
        status = "Fryer name matched; connecting to approved FFF1 notifications…"
        manager.connect(found, options: nil)
    }

    func centralManager(_ manager: CBCentralManager, didConnect found: CBPeripheral) {
        guard running, selected?.identifier == found.identifier else {
            manager.cancelPeripheralConnection(found)
            return
        }
        found.discoverServices([BLEPacketFamilyPolicy.service])
    }

    func centralManager(_ manager: CBCentralManager,
                        didFailToConnect found: CBPeripheral, error: Error?) {
        guard selected?.identifier == found.identifier else { return }
        stop("Bluetooth connection failed.")
    }

    func centralManager(_ manager: CBCentralManager,
                        didDisconnectPeripheral found: CBPeripheral, error: Error?) {
        guard running, selected?.identifier == found.identifier else { return }
        stop("Fryer disconnected before the observation finished.")
    }

    func peripheral(_ found: CBPeripheral, didDiscoverServices error: Error?) {
        guard running, selected?.identifier == found.identifier else { return }
        guard error == nil, let services = found.services,
              let service = services.first(where: { $0.uuid == BLEPacketFamilyPolicy.service }) else {
            stop("FFF0 notification service unavailable.")
            return
        }
        found.discoverCharacteristics([BLEPacketFamilyPolicy.notify], for: service)
    }

    func peripheral(_ found: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard running, selected?.identifier == found.identifier else { return }
        guard error == nil,
              let characteristic = service.characteristics?.first(where: {
                  BLEPacketFamilyPolicy.allows(service.uuid, $0.uuid)
                      && $0.properties.contains(.notify)
              }) else {
            stop("FFF1 notification characteristic unavailable.")
            return
        }
        // This configures a CCCD descriptor; NO characteristic payload writes,
        // no status requests, no router credentials, no heater or TI firmware OAD.
        found.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ found: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard running, selected?.identifier == found.identifier,
              let service = characteristic.service,
              BLEPacketFamilyPolicy.allows(service.uuid, characteristic.uuid) else { return }
        if error == nil && characteristic.isNotifying {
            if !subscribed {
                subscribed = true
                begin(.idle, seconds: BLEPacketFamilyPolicy.baselineSeconds)
            }
        } else {
            stop("FFF1 notification subscription failed.")
        }
    }

    func peripheral(_ found: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard running, subscribed, selected?.identifier == found.identifier,
              error == nil, characteristic.isNotifying,
              let service = characteristic.service,
              BLEPacketFamilyPolicy.allows(service.uuid, characteristic.uuid),
              let payload = characteristic.value else { return }
        let stageIndex: Int
        switch stage {
        case .idle: stageIndex = -1
        case .physical(let index): stageIndex = index
        case .connecting, .disconnected, .finished: return
        }
        // All raw bytes stay in this callback and are not saved or logged.
        stats.observe(payload, phase: stageIndex)
        idleEvents = stats.idleEvents
        stepEvents = stats.stepEvents
    }
}

struct BLEPacketFamilyView: View {
    @StateObject private var probe = BLEPacketFamilyModel()
    @State private var idleConfirmed = false
    @State private var copied = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeading(eyebrow: "PRIVATE BLE RESEARCH",
                            title: "Packet Families.",
                            subtitle: "One Start. Three physical taps. No raw Bluetooth export.")
                CrispCard {
                    Label("Read-only test", systemImage: "shield.lefthalf.filled")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Select Reheat on the fryer first, WITHOUT starting cooking. The fryer must stay idle and not heating. The app subscribes to FFF1 notifications, configuring only the Bluetooth CCCD descriptor. It sends no commands and does not access firmware services.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Toggle(isOn: $idleConfirmed) {
                        Text("Reheat selected. Fryer is idle and NOT heating.")
                            .font(.subheadline).foregroundColor(CrispPalette.cream)
                    }
                    .tint(CrispPalette.gold)
                    .disabled(probe.running)
                    Button {
                        copied = false
                        probe.start()
                    } label: {
                        Label("Start packet-family test", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                    .disabled(!idleConfirmed || probe.running)
                }
                CrispCard {
                    Text("LIVE INSTRUCTIONS")
                        .font(.caption.bold()).foregroundColor(CrispPalette.gold)
                    if probe.running {
                        switch probe.stage {
                        case .connecting:
                            ProgressView("Connecting…").tint(CrispPalette.gold)
                        case .idle:
                            Text("LEAVE THE FRYER UNTOUCHED")
                                .font(.title2.bold()).foregroundColor(CrispPalette.cream)
                        case .physical:
                            Text("TAP \(probe.currentPreset?.name.uppercased() ?? "PRESET")")
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
                    Text(probe.status).font(.subheadline).foregroundColor(CrispPalette.muted)
                    Text("Idle: \(probe.idleEvents) • Air Fry: \(probe.stepEvents[0]), Reheat: \(probe.stepEvents[1]), Air Fry: \(probe.stepEvents[2])")
                        .font(.caption.monospacedDigit()).foregroundColor(CrispPalette.muted)
                    if probe.running {
                        Button("Stop and disconnect", role: .destructive) { probe.stop() }
                            .buttonStyle(.bordered)
                    }
                }
                CrispCard {
                    Label("Automatically guided sequence", systemImage: "list.number")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("The app starts with ten seconds untouched. Then tap Air Fry, Reheat, and Air Fry as prompted. Each step lasts nine seconds and advances automatically. Never press the fryer's Start button.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    ForEach(Array(BLEPacketFamilyPolicy.sequence.enumerated()), id: \.offset) { i, preset in
                        HStack {
                            Text("\(i + 1). \(preset.name)")
                                .foregroundColor(CrispPalette.cream)
                            Spacer()
                            Text("\(probe.stepEvents[i]) events")
                                .font(.caption).foregroundColor(CrispPalette.muted)
                        }
                        Divider()
                    }
                }
                if let report = probe.result {
                    CrispCard {
                        Label("Private analysis completed", systemImage: "checkmark.shield")
                            .font(.headline).foregroundColor(CrispPalette.gold)
                        Text("Anonymous packet type categories: \(report.distinctAnonymousTypes)")
                            .font(.headline).foregroundColor(CrispPalette.cream)
                        Text("Air Fry → Reheat → Air Fry: \(report.anonymousTypeDistribution[1]) / \(report.anonymousTypeDistribution[2]) / \(report.anonymousTypeDistribution[3])")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text("A5 and length matches: \(report.bothMagicAndLengthMatches) of \(report.analyzedFrames)")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text("Sequence +1 pairs: \(report.sequencePlusOnePairs) of \(report.equalLengthAdjacentPairs)")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text("Byte 2+5 constant-sum pairs: \(report.constantSequenceSumPairs) of \(report.equalLengthAdjacentPairs)")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text("Category labels A/B/C reflect first-seen values, never actual byte values. Neither these labels nor matching headers prove temperature, preset, or cooking control.")
                            .font(.footnote).foregroundColor(CrispPalette.muted)
                        Button {
                            UIPasteboard.general.string = report.safeText
                            copied = true
                        } label: {
                            Label(copied ? "Safe report copied" : "Copy safe report",
                                  systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(CrispPalette.gold)
                        .foregroundColor(CrispPalette.background)
                    }
                }
                CrispCard {
                    Label("Privacy and limitations", systemImage: "lock.shield")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("The app examines incoming FFF1 frames only. It stores only temporary single-byte type and sequence data until this test finishes, then erases it. Nothing transmits raw payloads, actual type values or identifying data. A type label can remain unchanged even if the fryer emits a command acknowledgment instead of cooking status.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    if !probe.running {
                        Button("Clear results") {
                            probe.erase()
                            idleConfirmed = false
                            copied = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(20)
        }
        .background(CrispPalette.background)
        .navigationTitle("Packet Families")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { probe.erase() }
        .onChange(of: scenePhase) { phase in
            if phase != .active { probe.erase() }
        }
    }
}
