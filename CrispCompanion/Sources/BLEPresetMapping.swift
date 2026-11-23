import SwiftUI
import CoreBluetooth
import CryptoKit
import UIKit

// A guided, in-memory investigation, NOT a decoder or remote controller.
enum FryerPresetMap {
    // Matches the owner's observed top-to-bottom, left-to-right physical traversal.
    static let order: [FryerPreset] = [
        .chicken, .vegetables, .steak, .fries, .seafood, .frozen,
        .airFry, .keepWarm, .reheat, .bake, .roast, .broil
    ]
    static let listeningWindow: TimeInterval = 5
    static let untouchedBaseline: TimeInterval = 10
    static let maximumConnectionSession: TimeInterval = 300
    static let allowedServices = BLEObservationPolicy.allowedServices

    static func isAllowed(_ service: CBUUID, _ characteristic: CBUUID) -> Bool {
        BLEObservationPolicy.allowsNotification(service: service, characteristic: characteristic)
    }
}

struct PresetMappingResult: Identifiable, Equatable {
    let preset: FryerPreset
    var firstPackets: Int = 0
    var secondPackets: Int = 0
    var firstUnique: Int = 0
    var secondUnique: Int = 0
    var repeatedPatterns: Int = 0
    var idlePatterns: Int = 0

    var id: String { preset.rawValue }
}

/// Only aggregate counts and preset labels leave the diagnostic view,
/// and only after the user taps Copy safe summary.
enum PresetMapSummary {
    static func render(_ results: [PresetMappingResult]) -> String {
        let header = "Crisp Companion v0.1.4 • Local preset mapping • Counts only, not decoded status"
        let rows = results.map {
            "\($0.preset.name): pass1=\($0.firstPackets), pass2=\($0.secondPackets), " +
            "repeated=\($0.repeatedPatterns), idleOverlap=\($0.idlePatterns)"
        }
        return ([header] + rows).joined(separator: "\n")
    }
}

/// All digests use one ephemeral key during a measurement session.
/// Neither payloads nor keyed digests are exported, written to disk, or shown on screen.
struct PresetSignatureMap {
    private var key = SymmetricKey(size: .bits256)
    private var idle: Set<Data> = []
    private var windows: [[String: Set<Data>]] = [[:], [:]]
    private var counts: [[String: Int]] = [[:], [:]]
    private let capPerPreset = 128

    mutating func clear() {
        key = SymmetricKey(size: .bits256)
        idle.removeAll()
        windows = [[:], [:]]
        counts = [[:], [:]]
    }

    mutating func addIdle(_ bytes: Data, channel: String) {
        guard idle.count < 512 else { return }
        idle.insert(signature(bytes, channel: channel))
    }

    mutating func add(_ bytes: Data, channel: String, preset: FryerPreset, pass: Int) {
        guard pass == 0 || pass == 1 else { return }
        let name = preset.rawValue
        counts[pass][name, default: 0] += 1
        let digest = signature(bytes, channel: channel)
        if windows[pass][name, default: []].count < capPerPreset ||
            windows[pass][name, default: []].contains(digest) {
            windows[pass][name, default: []].insert(digest)
        }
    }

    func result(for preset: FryerPreset) -> PresetMappingResult {
        let name = preset.rawValue
        let a = windows[0][name] ?? []
        let b = windows[1][name] ?? []
        return PresetMappingResult(
            preset: preset,
            firstPackets: counts[0][name] ?? 0,
            secondPackets: counts[1][name] ?? 0,
            firstUnique: a.count,
            secondUnique: b.count,
            repeatedPatterns: a.intersection(b).count,
            idlePatterns: a.union(b).intersection(idle).count
        )
    }

    private func signature(_ bytes: Data, channel: String) -> Data {
        var message = Data(channel.utf8)
        message.append(0)
        message.append(bytes)
        return Data(HMAC<SHA256>.authenticationCode(for: message, using: key))
    }
}

final class BLEPresetMapper: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published private(set) var status = "Ready. Only the fryer's own panel will change settings."
    @Published private(set) var connected = false
    @Published private(set) var listening = false
    @Published private(set) var baselineFinished = false
    @Published private(set) var activeWindow = false
    @Published private(set) var countdown = 0
    @Published private(set) var pass = 0
    @Published private(set) var position = 0
    @Published private(set) var complete = false
    @Published private(set) var results = FryerPresetMap.order.map { PresetMappingResult(preset: $0) }
    @Published private(set) var backgroundPackets = 0

    private var central: CBCentralManager?
    private var selected: CBPeripheral?
    private var session: UUID?
    private var windowToken: UUID?
    private var timer: Timer?
    private var endAt = Date.distantPast
    private var awaitingServices = Set<String>()
    private var notifyingChannels = Set<String>()
    private var signatures = PresetSignatureMap()
    private var inBaseline = false

    var currentPreset: FryerPreset? {
        guard !complete, position < FryerPresetMap.order.count else { return nil }
        return FryerPresetMap.order[position]
    }
    var progress: Int { pass * FryerPresetMap.order.count + position }
    var canArm: Bool { connected && listening && baselineFinished && !activeWindow && !complete }

    func begin() {
        guard !connected && session == nil else { return }
        signatures.clear()
        results = FryerPresetMap.order.map { PresetMappingResult(preset: $0) }
        pass = 0
        position = 0
        complete = false
        backgroundPackets = 0
        baselineFinished = false
        listening = false
        activeWindow = false
        notifyingChannels.removeAll()
        awaitingServices.removeAll()
        status = "Scanning for the exact CAF-P583S-KUS advertised name…"
        let token = UUID()
        session = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let self, self.session == token, !self.listening else { return }
            self.stop("Connection/notification subscription timed out. No mapping was completed.")
        }
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main, options: [
                CBCentralManagerOptionShowPowerAlertKey: false
            ])
        } else if let central {
            centralManagerDidUpdateState(central)
        }
    }

    func armNextPreset() {
        guard canArm, let preset = currentPreset, let token = session else { return }
        activeWindow = true
        let window = UUID()
        windowToken = window
        countdown = Int(FryerPresetMap.listeningWindow)
        status = "NOW tap \(preset.name) on the physical fryer, without pressing Start."
        endAt = Date().addingTimeInterval(FryerPresetMap.listeningWindow)
        startTimer()
        DispatchQueue.main.asyncAfter(deadline: .now() + FryerPresetMap.listeningWindow) { [weak self] in
            guard let self, self.session == token, self.windowToken == window else { return }
            self.finishWindow()
        }
    }

    private func finishWindow() {
        guard activeWindow, let preset = currentPreset else { return }
        results[position] = signatures.result(for: preset)
        activeWindow = false
        windowToken = nil
        timer?.invalidate()
        timer = nil
        countdown = 0
        position += 1
        if position == FryerPresetMap.order.count {
            if pass == 0 {
                pass = 1
                position = 0
                status = "First pass complete. Repeat the same 12 presets in pass two."
            } else {
                complete = true
                status = "Both mapping passes complete. Bluetooth disconnected. Results remain on this screen."
                disconnectRetainingResults()
            }
        } else {
            status = "Window recorded. Arm \(currentPreset?.name ?? "the next preset") when ready."
        }
    }

    func stop(_ message: String = "Stopped and disconnected. No cooking commands sent.") {
        disconnectRetainingResults()
        activeWindow = false
        inBaseline = false
        baselineFinished = false
        complete = false
        status = message
    }

    func erase() {
        stop("Results cleared. No Bluetooth connection.")
        signatures.clear()
        results = FryerPresetMap.order.map { PresetMappingResult(preset: $0) }
        pass = 0
        position = 0
        backgroundPackets = 0
    }

    private func disconnectRetainingResults() {
        session = nil
        windowToken = nil
        timer?.invalidate()
        timer = nil
        central?.stopScan()
        if let selected {
            selected.delegate = nil
            if selected.state != .disconnected { central?.cancelPeripheralConnection(selected) }
        }
        selected = nil
        connected = false
        listening = false
        inBaseline = false
        activeWindow = false
        notifyingChannels.removeAll()
        awaitingServices.removeAll()
        countdown = 0
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.countdown = max(0, Int(ceil(self.endAt.timeIntervalSinceNow)))
        }
    }

    private func beginIdleBaseline() {
        guard let token = session else { return }
        inBaseline = true
        endAt = Date().addingTimeInterval(FryerPresetMap.untouchedBaseline)
        countdown = Int(FryerPresetMap.untouchedBaseline)
        status = "10-second idle check: do NOT touch the fryer's controls."
        startTimer()
        DispatchQueue.main.asyncAfter(deadline: .now() + FryerPresetMap.untouchedBaseline) { [weak self] in
            guard let self, self.session == token, self.inBaseline else { return }
            self.inBaseline = false
            self.baselineFinished = true
            self.timer?.invalidate()
            self.timer = nil
            self.countdown = 0
            self.status = "Ready: Arm Chicken, then tap Chicken on the fryer."
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard session != nil else { return }
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil,
                                      options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        case .poweredOff: stop("Bluetooth is switched off.")
        case .unauthorized: stop("Bluetooth permission denied in iPhone privacy settings.")
        case .unsupported: stop("Bluetooth Low Energy unavailable.")
        case .unknown, .resetting: status = "Waiting for Bluetooth…"
        @unknown default: stop("Unknown Bluetooth state.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard session != nil, selected == nil else { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? peripheral.name ?? ""
        guard BLEObservationPolicy.matchesExactName(name) else { return }
        selected = peripheral
        peripheral.delegate = self
        central.stopScan()
        status = "Exact model-name match. Connecting only for BLE notifications…"
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard session != nil, selected?.identifier == peripheral.identifier else {
            central.cancelPeripheralConnection(peripheral)
            return
        }
        connected = true
        status = "Discovering only permitted notification services…"
        peripheral.discoverServices(FryerPresetMap.allowedServices)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        guard selected?.identifier == peripheral.identifier else { return }
        stop("Connection failed. No commands were sent.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        guard session != nil, selected?.identifier == peripheral.identifier else { return }
        stop("Fryer disconnected. Mapping stopped without sending commands.")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard session != nil, selected?.identifier == peripheral.identifier else { return }
        guard error == nil, let services = peripheral.services else {
            stop("BLE service discovery failed.")
            return
        }
        let allowed = services.filter { FryerPresetMap.allowedServices.contains($0.uuid) }
        guard !allowed.isEmpty else { stop("No permitted BLE notification services."); return }
        awaitingServices = Set(allowed.map { $0.uuid.uuidString })
        for service in allowed {
            let target = service.uuid == BLEObservationPolicy.serialService
                ? BLEObservationPolicy.serialNotify : BLEObservationPolicy.secondaryNotify
            peripheral.discoverCharacteristics([target], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard session != nil, selected?.identifier == peripheral.identifier else { return }
        awaitingServices.remove(service.uuid.uuidString)
        if error == nil {
            for char in service.characteristics ?? [] {
                guard FryerPresetMap.isAllowed(service.uuid, char.uuid),
                      char.properties.contains(.notify) else { continue }
                // setNotifyValue configures CCCD (a descriptor write); NEVER writes cooking
                // characteristic values, reads payloads, or touches TI firmware OAD service.
                peripheral.setNotifyValue(true, for: char)
            }
        }
        if awaitingServices.isEmpty && notifyingChannels.isEmpty {
            status = "Waiting for an approved BLE notification subscription…"
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard session != nil, selected?.identifier == peripheral.identifier,
              let service = characteristic.service, FryerPresetMap.isAllowed(service.uuid, characteristic.uuid)
        else { return }
        if error == nil && characteristic.isNotifying {
            notifyingChannels.insert(characteristic.uuid.uuidString)
            if !listening {
                listening = true
                let token = session
                DispatchQueue.main.asyncAfter(deadline: .now() + FryerPresetMap.maximumConnectionSession) { [weak self] in
                    guard let self, self.session == token else { return }
                    self.stop("Five-minute session limit reached. Results are partial.")
                }
                beginIdleBaseline()
            }
        } else if notifyingChannels.isEmpty {
            status = "Notification subscription unavailable; it may require authentication."
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard session != nil, selected?.identifier == peripheral.identifier, error == nil,
              characteristic.isNotifying, let service = characteristic.service,
              FryerPresetMap.isAllowed(service.uuid, characteristic.uuid),
              let bytes = characteristic.value else { return }
        let channel = characteristic.uuid.uuidString
        if inBaseline {
            signatures.addIdle(bytes, channel: channel)
        } else if activeWindow, let preset = currentPreset {
            signatures.add(bytes, channel: channel, preset: preset, pass: pass)
            results[position] = signatures.result(for: preset)
        } else {
            backgroundPackets += 1
        }
    }
}

struct BLEPresetMappingView: View {
    @StateObject private var model = BLEPresetMapper()
    @State private var idleConfirmed = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeading(eyebrow: "LOCAL FRYER RESEARCH",
                            title: "Preset Mapping.",
                            subtitle: "Compare notification patterns for each physical cooking preset.")
                CrispCard {
                    Label("Safe testing only", systemImage: "shield.lefthalf.filled")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("The app listens only on FFF1 and F000FFE2. Notification subscription changes the Bluetooth CCCD descriptor. No commands, firmware operations, account connections, or heater control are sent.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Toggle(isOn: $idleConfirmed) {
                        Text("I am beside the fryer. It is idle and NOT heating.")
                            .font(.subheadline).foregroundColor(CrispPalette.cream)
                    }
                    .tint(CrispPalette.gold)
                    .disabled(model.connected)
                    Button {
                        model.begin()
                    } label: {
                        Label("Connect and run idle check", systemImage: "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                    .disabled(!idleConfirmed || model.connected || model.complete)
                }
                CrispCard {
                    Text(model.status).font(.subheadline).foregroundColor(CrispPalette.cream)
                    if model.countdown > 0 {
                        Text("\(model.countdown) seconds remaining")
                            .font(.caption).monospacedDigit().foregroundColor(CrispPalette.muted)
                    }
                    if model.listening && model.baselineFinished && !model.complete {
                        Text("Pass \(model.pass + 1) of 2 • Preset \(model.position + 1) of 12")
                            .font(.caption.weight(.semibold)).foregroundColor(CrispPalette.gold)
                        if let preset = model.currentPreset {
                            Text(preset.name).font(.title2.bold()).foregroundColor(CrispPalette.cream)
                            Text("Tap Arm, then immediately select this preset on the fryer's PHYSICAL panel within 5 seconds. Do not press Start.")
                                .font(.footnote).foregroundColor(CrispPalette.muted)
                            Button {
                                model.armNextPreset()
                            } label: {
                                Label("Arm \(preset.name) for 5 seconds", systemImage: "hand.tap.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(CrispPalette.gold)
                            .foregroundColor(CrispPalette.background)
                            .disabled(!model.canArm)
                        }
                    }
                    if model.complete {
                        Label("Two passes completed. No cooking controls were sent.",
                              systemImage: "checkmark.circle.fill")
                            .foregroundColor(CrispPalette.green)
                    }
                    if model.connected {
                        Button("Stop and disconnect", role: .destructive) {
                            model.stop()
                        }
                        .buttonStyle(.bordered)
                    }
                    if !model.connected {
                        Button("Clear local mapping results") {
                            model.erase()
                            idleConfirmed = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
                CrispCard {
                    Text("Physical button order")
                        .font(.headline).foregroundColor(CrispPalette.cream)
                    Text("Follow the 12 presets from top to bottom in each column, working left to right, then repeat the same order once.")
                        .font(.caption).foregroundColor(CrispPalette.muted)
                    ForEach(Array(FryerPresetMap.order.enumerated()), id: \.offset) { i, preset in
                        HStack {
                            Text("\(i + 1). \(preset.name)")
                                .font(.subheadline).foregroundColor(CrispPalette.cream)
                            Spacer()
                            let item = model.results[i]
                            Text("\(item.firstPackets) / \(item.secondPackets) packets")
                                .font(.caption).monospacedDigit().foregroundColor(CrispPalette.muted)
                        }
                        Divider()
                    }
                }
                if model.complete {
                    CrispCard {
                        Button {
                            UIPasteboard.general.string = PresetMapSummary.render(model.results)
                        } label: {
                            Label("Copy safe counts to share", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(CrispPalette.gold)
                        .foregroundColor(CrispPalette.background)
                    }
                    CrispCard {
                        Label("Repeatability summary", systemImage: "arrow.triangle.2.circlepath")
                            .font(.headline).foregroundColor(CrispPalette.gold)
                        Text("Matching patterns mean identical messages were received in the two windows for that preset. A match is not proof that the packet represents that preset; background counters and overlapping timing can affect results.")
                            .font(.footnote).foregroundColor(CrispPalette.muted)
                        ForEach(model.results) { result in
                            HStack {
                                Text(result.preset.name)
                                    .foregroundColor(CrispPalette.cream)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(result.repeatedPatterns) repeated")
                                        .font(.caption.weight(.semibold)).foregroundColor(CrispPalette.gold)
                                    Text("\(result.idlePatterns) also idle")
                                        .font(.caption2).foregroundColor(CrispPalette.muted)
                                }
                            }
                            Divider()
                        }
                    }
                }
                CrispCard {
                    Label("Important limitations", systemImage: "info.circle")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("A five-second window can include unrelated notifications, and a single preset may produce more than one packet. This tool does not decode temperature, time, or mode. It never stores raw messages or exports fingerprints. Leaving this screen clears every comparison, disconnects Bluetooth, and forgets the temporary encryption key.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Text("If the fryer starts heating or behaves unexpectedly, stop immediately.")
                        .font(.caption).foregroundColor(CrispPalette.muted)
                }
            }
            .padding(20)
        }
        .background(CrispPalette.background)
        .navigationTitle("Preset Mapping")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { model.erase() }
        .onChange(of: scenePhase) { phase in
            if phase != .active { model.erase() }
        }
    }
}
