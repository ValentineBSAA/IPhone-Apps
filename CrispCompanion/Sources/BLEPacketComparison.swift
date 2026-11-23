import SwiftUI
import CoreBluetooth
import CryptoKit

/// These fingerprints are only comparable during one in-memory two-stage experiment.
/// No raw packet, stable hash, device identifier, password, or network data is persisted.
enum BLEComparePhase: String {
    case baseline
    case adjustments

    var title: String {
        self == .baseline ? "Idle baseline" : "Physical adjustments"
    }
}

struct BLEComparisonSummary: Equatable {
    var baselineEvents = 0
    var adjustmentEvents = 0
    var baselineUnique = 0
    var adjustmentUnique = 0
    var newPatterns = 0
    var sharedPatterns = 0
    var baselineFFF1 = 0
    var adjustmentFFF1 = 0
    var baselineFFE2 = 0
    var adjustmentFFE2 = 0
    var markers = 0
    var limited = false
}

/// HMAC key exists only for this app-screen session. It prevents guessing
/// low-entropy 10-byte BLE frames from any displayed statistics.
struct BLEInMemoryComparator {
    private var sessionKey = SymmetricKey(size: .bits256)
    private var baseline: [String: Set<Data>] = [:]
    private var adjustments: [String: Set<Data>] = [:]
    private(set) var summary = BLEComparisonSummary()
    private let maxPatterns = 512

    mutating func reset() {
        sessionKey = SymmetricKey(size: .bits256)
        baseline.removeAll()
        adjustments.removeAll()
        summary = BLEComparisonSummary()
    }

    mutating func markPhysicalAdjustment() {
        summary.markers += 1
    }

    mutating func record(_ bytes: Data, channel: String, phase: BLEComparePhase) {
        // Packet Data exists only as the callback argument, never in the accumulator.
        let signature = Data(HMAC<SHA256>.authenticationCode(for: bytes, using: sessionKey))
        var groups = phase == .baseline ? baseline : adjustments
        var known = groups[channel] ?? Set<Data>()
        // Cap cardinality, keep total event counts to make truncation explicit.
        if known.count < maxPatterns || known.contains(signature) {
            known.insert(signature)
            groups[channel] = known
        } else {
            summary.limited = true
        }
        if phase == .baseline {
            baseline = groups
            summary.baselineEvents += 1
            if channel == "FFF1" { summary.baselineFFF1 += 1 }
            if channel == BLEObservationPolicy.secondaryNotify.uuidString {
                summary.baselineFFE2 += 1
            }
        } else {
            adjustments = groups
            summary.adjustmentEvents += 1
            if channel == "FFF1" { summary.adjustmentFFF1 += 1 }
            if channel == BLEObservationPolicy.secondaryNotify.uuidString {
                summary.adjustmentFFE2 += 1
            }
        }
        summary.baselineUnique = baseline.values.reduce(0) { $0 + $1.count }
        summary.adjustmentUnique = adjustments.values.reduce(0) { $0 + $1.count }
        summary.sharedPatterns = adjustments.reduce(0) { total, entry in
            total + entry.value.intersection(baseline[entry.key] ?? []).count
        }
        summary.newPatterns = max(0, summary.adjustmentUnique - summary.sharedPatterns)
    }
}

/// Explicit opt-in local BLE notification comparator. No commands are sent to the fryer.
/// Only a BLE Client Characteristic Configuration Descriptor subscription is modified.
final class BLEPacketComparatorModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published private(set) var status = "Ready. Begin with a 45-second untouched baseline."
    @Published private(set) var running = false
    @Published private(set) var subscribed = false
    @Published private(set) var activePhase: BLEComparePhase?
    @Published private(set) var remainingSeconds = 45
    @Published private(set) var baselineComplete = false
    @Published private(set) var adjustmentsComplete = false
    @Published private(set) var summary = BLEComparisonSummary()

    private var accumulator = BLEInMemoryComparator()
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var pendingServices = Set<String>()
    private var subscribedChannels = Set<String>()
    private var generation: UUID?
    private var deadline = Date.distantPast
    private var ticker: Timer?
    private var isObserving = false

    func start(_ phase: BLEComparePhase) {
        guard !running else { return }
        guard phase == .baseline || baselineComplete else { return }
        if phase == .baseline {
            accumulator.reset()
            baselineComplete = false
            adjustmentsComplete = false
            summary = accumulator.summary
        }
        status = "Finding CAF-P583S-KUS…"
        activePhase = phase
        running = true
        subscribed = false
        isObserving = false
        remainingSeconds = 45
        let token = UUID()
        generation = token
        pendingServices.removeAll()
        subscribedChannels.removeAll()
        // A separate 20-second discovery/connection timeout. Measurement starts
        // only AFTER the approved notification subscription becomes active.
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let self, self.generation == token, !self.isObserving else { return }
            self.stop(reason: "Bluetooth connection timed out. No valid sample was collected.")
        }
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main, options: [
                CBCentralManagerOptionShowPowerAlertKey: false
            ])
        } else if let central {
            centralManagerDidUpdateState(central)
        }
    }

    func markAdjustment() {
        guard running, subscribed, activePhase == .adjustments else { return }
        accumulator.markPhysicalAdjustment()
        summary = accumulator.summary
    }

    func stop(reason: String = "Stopped early. This stage was not marked complete.", completed: Bool = false) {
        let wasRunning = running
        let phase = activePhase
        generation = nil
        running = false
        subscribed = false
        isObserving = false
        remainingSeconds = 0
        ticker?.invalidate()
        ticker = nil
        central?.stopScan()
        pendingServices.removeAll()
        subscribedChannels.removeAll()
        if let peripheral {
            peripheral.delegate = nil
            if peripheral.state != .disconnected {
                central?.cancelPeripheralConnection(peripheral)
            }
        }
        peripheral = nil
        if wasRunning && completed {
            if phase == .baseline { baselineComplete = true }
            if phase == .adjustments { adjustmentsComplete = true }
        }
        activePhase = nil
        status = reason
    }

    func erase() {
        stop(reason: "Results cleared. No Bluetooth connection.")
        accumulator.reset()
        summary = accumulator.summary
        baselineComplete = false
        adjustmentsComplete = false
        remainingSeconds = 45
    }

    private func beginObservation() {
        guard running, !isObserving, let token = generation else { return }
        isObserving = true
        subscribed = true
        deadline = Date().addingTimeInterval(45)
        remainingSeconds = 45
        status = activePhase == .baseline
            ? "Listening. Leave the fryer untouched for the entire 45 seconds."
            : "Listening. Change settings physically, then tap Mark adjustment."
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.generation == token else { return }
            self.remainingSeconds = max(0, Int(ceil(self.deadline.timeIntervalSinceNow)))
            if self.remainingSeconds == 0 {
                self.stop(reason: "45-second \(self.activePhase?.title ?? "test") complete.",
                          completed: true)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) { [weak self] in
            guard let self, self.generation == token else { return }
            self.stop(reason: "45-second \(self.activePhase?.title ?? "test") complete.", completed: true)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard running else { return }
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil,
                                       options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        case .poweredOff:
            stop(reason: "Bluetooth is off.")
        case .unauthorized:
            stop(reason: "Bluetooth permission denied in iPhone Settings.")
        case .unsupported:
            stop(reason: "Bluetooth Low Energy unavailable.")
        case .unknown, .resetting:
            status = "Waiting for Bluetooth…"
        @unknown default:
            stop(reason: "Unknown Bluetooth state.")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover discovered: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        guard running, peripheral == nil else { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? discovered.name ?? ""
        guard BLEObservationPolicy.matchesExactName(name) else { return }
        peripheral = discovered
        discovered.delegate = self
        central.stopScan()
        status = "Fryer model-name match found. Connecting…"
        central.connect(discovered, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect connected: CBPeripheral) {
        guard running, peripheral?.identifier == connected.identifier else {
            central.cancelPeripheralConnection(connected)
            return
        }
        status = "Discovering two permitted notification services…"
        connected.discoverServices(BLEObservationPolicy.allowedServices)
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect failed: CBPeripheral, error: Error?) {
        guard peripheral?.identifier == failed.identifier else { return }
        stop(reason: "Could not connect. No valid sample collected.")
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral disconnected: CBPeripheral, error: Error?) {
        guard running, peripheral?.identifier == disconnected.identifier else { return }
        stop(reason: "Fryer disconnected before the sample finished.")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard running, self.peripheral?.identifier == peripheral.identifier else { return }
        guard error == nil, let services = peripheral.services else {
            stop(reason: "Unable to discover approved Bluetooth services.")
            return
        }
        let allowed = services.filter { BLEObservationPolicy.allowedServices.contains($0.uuid) }
        if allowed.isEmpty {
            stop(reason: "No approved notification services detected.")
            return
        }
        pendingServices = Set(allowed.map { $0.uuid.uuidString })
        status = "Discovering notification characteristics…"
        for service in allowed {
            let wanted = service.uuid == BLEObservationPolicy.serialService
                ? BLEObservationPolicy.serialNotify : BLEObservationPolicy.secondaryNotify
            peripheral.discoverCharacteristics([wanted], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard running, self.peripheral?.identifier == peripheral.identifier else { return }
        pendingServices.remove(service.uuid.uuidString)
        if error == nil {
            for characteristic in service.characteristics ?? [] {
                guard BLEObservationPolicy.allowsNotification(
                    service: service.uuid, characteristic: characteristic.uuid
                ), characteristic.properties.contains(.notify) else { continue }
                // This alters the local BLE CCCD descriptor to subscribe; no
                // operational or firmware characteristic value is written.
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        if pendingServices.isEmpty {
            status = "Waiting for approved notification subscriptions…"
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard running, self.peripheral?.identifier == peripheral.identifier,
              let service = characteristic.service,
              BLEObservationPolicy.allowsNotification(
                  service: service.uuid, characteristic: characteristic.uuid
              ) else { return }
        if error == nil && characteristic.isNotifying {
            subscribedChannels.insert(characteristic.uuid.uuidString)
            beginObservation()
        } else if subscribedChannels.isEmpty {
            status = "Notification subscription unavailable. May require authentication."
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard running, subscribed, self.peripheral?.identifier == peripheral.identifier,
              error == nil, let service = characteristic.service,
              BLEObservationPolicy.allowsNotification(
                  service: service.uuid, characteristic: characteristic.uuid
              ), characteristic.isNotifying, let phase = activePhase,
              let bytes = characteristic.value else { return }
        accumulator.record(bytes, channel: characteristic.uuid.uuidString, phase: phase)
        summary = accumulator.summary
    }
}

struct BLEPacketComparisonView: View {
    @StateObject private var model = BLEPacketComparatorModel()
    @State private var idleConfirmed = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeading(eyebrow: "LOCAL BLE DIAGNOSTICS",
                            title: "Packet Comparison.",
                            subtitle: "Learn whether button changes alter messages. No cooking controls.")
                CrispCard {
                    Label("Before you begin", systemImage: "shield.lefthalf.filled")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Two separate 45-second measurements. Bluetooth notification subscription changes a configuration descriptor (CCCD), but no cooking, firmware, or Wi-Fi commands are sent. No VeSync account or cloud required.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Toggle(isOn: $idleConfirmed) {
                        Text("I am beside the fryer and confirm it is NOT heating.")
                            .foregroundColor(CrispPalette.cream).font(.subheadline)
                    }
                    .tint(CrispPalette.gold)
                    .disabled(model.running)
                }

                CrispCard {
                    Text("1. Untouched baseline")
                        .font(.title3.bold()).foregroundColor(CrispPalette.cream)
                    Text("Leave the fryer plugged in and idle. Do not touch its panel until 45 seconds have finished.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Button {
                        model.start(.baseline)
                    } label: {
                        Label(model.baselineComplete ? "Repeat untouched baseline" : "Start 45-second baseline",
                              systemImage: "pause.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                    .disabled(!idleConfirmed || model.running)
                    HStack {
                        metric("Packets", model.summary.baselineEvents)
                        metric("Unique patterns", model.summary.baselineUnique)
                    }
                    if model.baselineComplete {
                        Label("Baseline complete", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundColor(CrispPalette.green)
                    }
                }

                CrispCard {
                    Text("2. Physical adjustments")
                        .font(.title3.bold()).foregroundColor(CrispPalette.cream)
                    Text("Only after baseline: change presets, temperature or time using the fryer's own buttons. Never press Start. Tap Mark adjustment after each change.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Button {
                        model.start(.adjustments)
                    } label: {
                        Label("Start 45-second adjustment run", systemImage: "waveform.path")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                    .disabled(!idleConfirmed || !model.baselineComplete || model.running)
                    Button {
                        model.markAdjustment()
                    } label: {
                        Label("Mark adjustment", systemImage: "hand.tap")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!model.running || !model.subscribed || model.activePhase != .adjustments)
                    HStack {
                        metric("Packets", model.summary.adjustmentEvents)
                        metric("Unique patterns", model.summary.adjustmentUnique)
                        metric("Marked changes", model.summary.markers)
                    }
                    if model.adjustmentsComplete {
                        Label("Adjustment run complete", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundColor(CrispPalette.green)
                    }
                }

                CrispCard {
                    Label("Live connection", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text(model.status).font(.subheadline)
                        .foregroundColor(CrispPalette.cream)
                    if model.running {
                        Text(model.subscribed ? "\(model.remainingSeconds)s of observation remaining"
                                               : "Connecting. Observation clock has not started yet.")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        if model.subscribed {
                            ProgressView(value: Double(45 - model.remainingSeconds), total: 45)
                                .tint(CrispPalette.gold)
                        }
                        Button("Stop and disconnect") {
                            model.stop()
                        }
                        .buttonStyle(.bordered)
                    }
                    Button("Clear comparison and disconnect", role: .destructive) {
                        model.erase()
                        idleConfirmed = false
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.running)
                }

                if model.baselineComplete {
                    CrispCard {
                        Label("Comparison", systemImage: "arrow.left.arrow.right")
                            .font(.headline).foregroundColor(CrispPalette.gold)
                        Text(model.adjustmentsComplete
                             ? "These are message-pattern differences, not decoded cooking status."
                             : "Finish the physical-adjustment run to compare patterns.")
                            .font(.footnote).foregroundColor(CrispPalette.muted)
                        HStack {
                            metric("Patterns in both", model.summary.sharedPatterns)
                            metric("New patterns", model.summary.newPatterns)
                        }
                        HStack {
                            metric("Idle FFF1", model.summary.baselineFFF1)
                            metric("Changed FFF1", model.summary.adjustmentFFF1)
                        }
                        if model.summary.limited {
                            Text("Pattern limit reached. Only the first 512 distinct patterns per channel per phase were compared.")
                                .font(.caption).foregroundColor(CrispPalette.peach)
                        }
                        Text("Patterns are compared using a temporary secret key that is forgotten when you clear results or leave this screen. No packets, secret keys or identifiers are exported. Differences cannot, by themselves, prove a temperature or preset encoding.")
                            .font(.footnote).foregroundColor(CrispPalette.muted)
                    }
                }
            }
            .padding(20)
        }
        .background(CrispPalette.background)
        .navigationTitle("Packet Comparison")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onDisappear { model.erase() }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                model.erase()
            }
        }
    }

    private func metric(_ heading: String, _ value: Int) -> some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.title3.bold()).monospacedDigit().foregroundColor(CrispPalette.cream)
            Text(heading)
                .font(.caption2).foregroundColor(CrispPalette.muted)
                .lineLimit(2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(CrispPalette.panelRaised, in: RoundedRectangle(cornerRadius: 14))
    }
}
