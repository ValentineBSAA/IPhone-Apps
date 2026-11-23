import SwiftUI
import CoreBluetooth
import UIKit

// Passive, opt-in diagnostic. Mask the two counter/checksum-like positions
// before comparing bounded anonymous frame signatures. No raw data export.
struct BLETimeDifferenceReport {
    let counts: [Int]
    let distinctMaskedSignatures: [Int]
    let commonAcrossTimes: Bool
    let reversibleContrast: Bool
    let uninformative: Bool
    var safeText: String {
        [
            "Crisp Companion 0.1.9 / Idle time-only differential",
            "Physical steps: untouched 10, 11, 10, 11, 10 minutes; never Start",
            "FFF1 events by step: " + counts.map(String.init).joined(separator: ","),
            "Distinct masked signatures by step: " + distinctMaskedSignatures.map(String.init).joined(separator: ","),
            "Masked signature shared across 10/11: " + String(commonAcrossTimes),
            "Repeatable reversible signature contrast: " + String(reversibleContrast),
            "Insufficient evidence: " + String(uninformative),
            "Byte offsets 2 and 5 excluded. No raw packets, fingerprints or device identifiers.",
            "A positive contrast is a candidate association, NOT a decoded duration or safe control protocol."
        ].joined(separator: "\n")
    }
}

struct BLETimeDifferenceAccumulator {
    private(set) var counts = Array(repeating: 0, count: 5)
    private var signatures = Array(repeating: Set<[UInt8]>(), count: 5)
    private(set) var capped = false
    private var total = 0
    mutating func observe(_ data: Data, phase: Int) {
        guard (0..<5).contains(phase) else { return }
        counts[phase] += 1
        guard total < 64 else { capped = true; return }
        total += 1
        guard data.count >= 6, data.count <= 64 else { return }
        var masked = Array(data)
        masked[2] = 0
        masked[5] = 0
        signatures[phase].insert(masked)
    }
    func report() -> BLETimeDifferenceReport {
        let ten = signatures[0].union(signatures[2]).union(signatures[4])
        let eleven = signatures[1].union(signatures[3])
        let common = !ten.isDisjoint(with: eleven)
        // Baseline may be silent; compare the two active transitions to each setting.
        let tenRepeated = !signatures[2].intersection(signatures[4]).isEmpty
        let elevenRepeated = !signatures[1].intersection(signatures[3]).isEmpty
        let reversible = tenRepeated && elevenRepeated && !common
        return BLETimeDifferenceReport(
            counts: counts,
            distinctMaskedSignatures: signatures.map { $0.count },
            commonAcrossTimes: common,
            reversibleContrast: reversible,
            uninformative: !reversible
        )
    }
    mutating func clear() { self = BLETimeDifferenceAccumulator() }
}

final class BLETimeDifferenceModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published private(set) var running = false
    @Published private(set) var subscribed = false
    @Published private(set) var phase = -1
    @Published private(set) var status = "Ready. Set Air Fry to 10 minutes without starting."
    @Published private(set) var counts = Array(repeating: 0, count: 5)
    @Published private(set) var report: BLETimeDifferenceReport?
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var session: UUID?
    private var stats = BLETimeDifferenceAccumulator()
    private var deadline: Date?
    private var ticker: Timer?
    static let times = [10, 11, 10, 11, 10]
    func start() {
        guard !running else { return }
        erase()
        running = true
        status = "Connecting to CAF-P583S-KUS; do not touch the fryer."
        let token = UUID()
        session = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let self, self.session == token, !self.subscribed else { return }
            self.stop("Connection timed out.")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) { [weak self] in
            guard let self, self.session == token else { return }
            self.stop("Two-minute safety timeout.")
        }
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main,
                options: [CBCentralManagerOptionShowPowerAlertKey: false])
        } else if let central { centralManagerDidUpdateState(central) }
    }
    func confirmPhysicalStep() {
        guard running, subscribed, phase >= 0, phase < 4, deadline == nil else { return }
        phase += 1
        status = "NOW change the fryer to " + String(Self.times[phase]) + " minutes. Recording for 10 seconds."
        deadline = Date().addingTimeInterval(10)
        let token = session
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self, self.session == token, self.running else { return }
            self.deadline = nil
            if self.phase == 4 {
                self.report = self.stats.report()
                self.stop("Comparison complete. Bluetooth disconnected.")
            } else {
                self.status = "Keep the current setting. Tap Record next change BEFORE touching the fryer."
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    private func beginBaseline() {
        guard running else { return }
        phase = 0
        status = "Leave Air Fry at 10 minutes. Collecting untouched baseline for 8 seconds."
        deadline = Date().addingTimeInterval(8)
        let token = session
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            guard let self, self.session == token, self.running else { return }
            self.deadline = nil
            self.status = "Keep 10 minutes selected. Tap Record next change BEFORE touching the fryer."
        }
    }
    var waitingForConfirmation: Bool {
        running && subscribed && phase >= 0 && phase < 4 && deadline == nil
    }
    func stop(_ message: String = "Stopped. Bluetooth disconnected.") {
        running = false
        subscribed = false
        session = nil
        deadline = nil
        ticker?.invalidate()
        ticker = nil
        central?.stopScan()
        if let peripheral {
            peripheral.delegate = nil
            if peripheral.state != .disconnected { central?.cancelPeripheralConnection(peripheral) }
        }
        peripheral = nil
        stats.clear()
        status = message
    }
    func erase() {
        stop("Cleared.")
        report = nil
        counts = Array(repeating: 0, count: 5)
        phase = -1
    }
    func centralManagerDidUpdateState(_ manager: CBCentralManager) {
        guard running else { return }
        switch manager.state {
        case .poweredOn:
            manager.scanForPeripherals(withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        case .poweredOff: stop("Bluetooth is off.")
        case .unauthorized: stop("Bluetooth permission denied.")
        case .unsupported: stop("BLE unavailable.")
        case .unknown, .resetting: status = "Waiting for Bluetooth."
        @unknown default: stop("Bluetooth unavailable.")
        }
    }
    func centralManager(_ manager: CBCentralManager, didDiscover found: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard running, peripheral == nil else { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? found.name ?? ""
        guard BLEObservationPolicy.matchesExactName(name) else { return }
        peripheral = found
        found.delegate = self
        manager.stopScan()
        manager.connect(found, options: nil)
    }
    func centralManager(_ manager: CBCentralManager, didConnect found: CBPeripheral) {
        guard running, peripheral?.identifier == found.identifier else {
            manager.cancelPeripheralConnection(found); return
        }
        found.discoverServices([BLEObservationPolicy.serialService])
    }
    func centralManager(_ manager: CBCentralManager, didFailToConnect found: CBPeripheral, error: Error?) {
        guard peripheral?.identifier == found.identifier else { return }
        stop("Connection failed.")
    }
    func centralManager(_ manager: CBCentralManager, didDisconnectPeripheral found: CBPeripheral, error: Error?) {
        guard running, peripheral?.identifier == found.identifier else { return }
        stop("Fryer disconnected.")
    }
    func peripheral(_ found: CBPeripheral, didDiscoverServices error: Error?) {
        guard running, peripheral?.identifier == found.identifier else { return }
        guard error == nil, let service = found.services?.first(where: { $0.uuid == BLEObservationPolicy.serialService }) else {
            stop("FFF0 service missing."); return
        }
        found.discoverCharacteristics([BLEObservationPolicy.serialNotify], for: service)
    }
    func peripheral(_ found: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard running, peripheral?.identifier == found.identifier else { return }
        guard error == nil, service.uuid == BLEObservationPolicy.serialService,
              let characteristic = service.characteristics?.first(where: {
                  $0.uuid == BLEObservationPolicy.serialNotify && $0.properties.contains(.notify)
              }) else { stop("FFF1 notify unavailable."); return }
        // Subscription configures CCCD only; no characteristic reads/writes or heater commands.
        found.setNotifyValue(true, for: characteristic)
    }
    func peripheral(_ found: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard running, peripheral?.identifier == found.identifier,
              characteristic.uuid == BLEObservationPolicy.serialNotify else { return }
        if error == nil && characteristic.isNotifying {
            if !subscribed { subscribed = true; beginBaseline() }
        } else { stop("Notification subscription failed.") }
    }
    func peripheral(_ found: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard running, subscribed, peripheral?.identifier == found.identifier,
              error == nil, characteristic.isNotifying,
              characteristic.uuid == BLEObservationPolicy.serialNotify,
              characteristic.service?.uuid == BLEObservationPolicy.serialService,
              let data = characteristic.value, phase >= 0, deadline != nil else { return }
        stats.observe(data, phase: phase)
        counts = stats.counts
    }
}

struct BLETimeDifferenceView: View {
    @StateObject private var probe = BLETimeDifferenceModel()
    @State private var confirmedIdle = false
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeading(eyebrow: "PRIVATE BLE RESEARCH", title: "Time Difference.",
                            subtitle: "One setting. Two durations. No heating.")
                CrispCard {
                    Label("Read-only time experiment", systemImage: "shield.lefthalf.filled")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Physically select Air Fry and set 10 minutes. Leave the fryer idle. Never press its Start button. Only FFF1 notifications are observed. Subscribing configures a Bluetooth descriptor, not a cooking command.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Toggle("Air Fry is at 10 minutes, idle and NOT heating.", isOn: $confirmedIdle)
                        .tint(CrispPalette.gold).disabled(probe.running)
                    Button("Start time-only test") { probe.start() }
                        .buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                        .disabled(!confirmedIdle || probe.running)
                }
                CrispCard {
                    Text(probe.status).foregroundColor(CrispPalette.cream)
                    if probe.running {
                        Text("Step " + String(max(1, probe.phase + 1)) + " of 5")
                            .font(.headline).foregroundColor(CrispPalette.gold)
                        if probe.waitingForConfirmation {
                            Button("Record next change") { probe.confirmPhysicalStep() }
                                .buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                        }
                        Button("Stop and disconnect", role: .destructive) { probe.stop() }
                            .buttonStyle(.bordered)
                    }
                    Text("FFF1 events: " + probe.counts.map(String.init).joined(separator: " / "))
                        .font(.caption.monospacedDigit()).foregroundColor(CrispPalette.muted)
                }
                CrispCard {
                    Label("Physical sequence", systemImage: "clock.arrow.2.circlepath")
                        .foregroundColor(CrispPalette.gold)
                    Text("10 min untouched baseline → 11 → 10 → 11 → 10. Tap Record next change FIRST, then adjust the physical fryer during the 10-second recording window. Never start cooking.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                }
                if let report = probe.report {
                    CrispCard {
                        Label("Anonymous comparison", systemImage: "checkmark.shield")
                            .foregroundColor(CrispPalette.gold)
                        Text(report.reversibleContrast ? "Repeatable candidate difference detected" : "No repeatable time-specific difference established")
                            .font(.headline).foregroundColor(CrispPalette.cream)
                        Text("This does not prove duration telemetry or unlock local control.")
                            .font(.footnote).foregroundColor(CrispPalette.muted)
                        Button("Copy privacy-safe report") {
                            UIPasteboard.general.string = report.safeText
                        }.buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                    }
                }
            }.padding(20)
        }
        .background(CrispPalette.background)
        .navigationTitle("Time Difference")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { probe.erase() }
        .onChange(of: scenePhase) { phase in
            if phase != .active { probe.erase() }
        }
    }
}
