import SwiftUI
import CoreBluetooth
import UIKit

/// Research-only, foreground-only four-tap test. Never sends cooking commands.
enum QuickProbePolicy {
    static let sequence: [FryerPreset] = [.airFry, .reheat, .airFry, .reheat]
    static let idleSeconds = 12
    static let stepSeconds = 8
    static let maxFrameBytes = 64
    static let approvedServices = BLEObservationPolicy.allowedServices
    static func permits(_ service: CBUUID, _ characteristic: CBUUID) -> Bool {
        BLEObservationPolicy.allowsNotification(service: service, characteristic: characteristic)
    }
}

struct QuickProbeResult: Equatable {
    let received: Int
    let lengths: [Int]
    let candidatePositions: [Int]
    let airFryChanged: [Int]
    let reheatChanged: [Int]
    let firstTransitionChanged: [Int]
    let explanation: String

    static func compare(_ frames: [Data?]) -> QuickProbeResult {
        let lengths = frames.map { $0?.count ?? 0 }
        let present = frames.compactMap { $0 }
        guard frames.count == 4 && present.count == 4 else {
            return QuickProbeResult(received: present.count, lengths: lengths,
                                    candidatePositions: [], airFryChanged: [],
                                    reheatChanged: [], firstTransitionChanged: [],
                                    explanation: "Incomplete capture. One or more of the four steps received no FFF1 notification.")
        }
        let bytes = present.map { Array($0) }
        guard let first = bytes.first, !first.isEmpty, first.count <= QuickProbePolicy.maxFrameBytes,
              bytes.allSatisfy({ $0.count == first.count }) else {
            return QuickProbeResult(received: 4, lengths: lengths,
                                    candidatePositions: [], airFryChanged: [],
                                    reheatChanged: [], firstTransitionChanged: [],
                                    explanation: "Message lengths differ or exceed the comparison limit.")
        }
        let positions = Array(first.indices)
        let airChanges = positions.filter { bytes[0][$0] != bytes[2][$0] }
        let reheatChanges = positions.filter { bytes[1][$0] != bytes[3][$0] }
        let transitionChanges = positions.filter { bytes[0][$0] != bytes[1][$0] }
        let candidates = positions.filter {
            bytes[0][$0] == bytes[2][$0] &&
            bytes[1][$0] == bytes[3][$0] &&
            bytes[0][$0] != bytes[1][$0]
        }
        return QuickProbeResult(
            received: 4, lengths: lengths,
            candidatePositions: candidates,
            airFryChanged: airChanges,
            reheatChanged: reheatChanges,
            firstTransitionChanged: transitionChanges,
            explanation: candidates.isEmpty
                ? "No stable candidate positions found. Changing counters or checksums may be present."
                : "Candidate positions appeared stable within repeated presets and different between them. This is not decoded status."
        )
    }

    func safeReport(idleCount: Int, perStep: [Int]) -> String {
        func show(_ values: [Int]) -> String {
            values.isEmpty ? "none" : values.map(String.init).joined(separator: ",")
        }
        return [
            "Crisp Companion 0.1.5 / Quick Local Probe / positions and counts only",
            "Sequence: Air Fry, Reheat, Air Fry, Reheat",
            "Idle notifications: \(idleCount)",
            "Notifications per step: \(perStep.map(String.init).joined(separator: ","))",
            "First FFF1 packet lengths: \(lengths.map(String.init).joined(separator: ","))",
            "Usable steps: \(received)/4",
            "Possible preset-sensitive offsets (zero-based): \(show(candidatePositions))",
            "Air Fry repeat changed offsets: \(show(airFryChanged))",
            "Reheat repeat changed offsets: \(show(reheatChanged))",
            "First A vs B changed offsets: \(show(firstTransitionChanged))",
            "No Bluetooth bytes, fingerprints, account credentials or device IDs included."
        ].joined(separator: "\n")
    }
}

final class QuickProbeModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    enum Phase: Equatable { case idle, tap(Int), done }
    @Published private(set) var status = "Ready to investigate local Bluetooth events."
    @Published private(set) var running = false
    @Published private(set) var subscribed = false
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var countdown = 0
    @Published private(set) var idleCount = 0
    @Published private(set) var stepCounts = [0, 0, 0, 0]
    @Published private(set) var result: QuickProbeResult?

    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var session: UUID?
    private var phaseID: UUID?
    private var timer: Timer?
    private var finishAt = Date.distantPast
    private var subscriptions = Set<String>()
    private var captures: [Data?] = [nil, nil, nil, nil]

    var activePreset: FryerPreset? {
        guard case .tap(let i) = phase else { return nil }
        return QuickProbePolicy.sequence.indices.contains(i) ? QuickProbePolicy.sequence[i] : nil
    }

    func start() {
        guard !running else { return }
        clearObservations()
        running = true
        status = "Looking for CAF-P583S-KUS…"
        let token = UUID()
        session = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let self, self.session == token, !self.subscribed else { return }
            self.stop("Connection or subscription timed out.")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 90) { [weak self] in
            guard let self, self.session == token else { return }
            self.stop("Session timeout: Bluetooth disconnected.")
        }
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main,
                                       options: [CBCentralManagerOptionShowPowerAlertKey: false])
        } else if let central {
            centralManagerDidUpdateState(central)
        }
    }

    func stop(_ reason: String = "Stopped. Bluetooth disconnected.") {
        running = false
        subscribed = false
        session = nil
        phaseID = nil
        timer?.invalidate()
        timer = nil
        central?.stopScan()
        subscriptions.removeAll()
        if let peripheral {
            peripheral.delegate = nil
            if peripheral.state != .disconnected { central?.cancelPeripheralConnection(peripheral) }
        }
        peripheral = nil
        captures = [nil, nil, nil, nil]
        countdown = 0
        status = reason
    }

    func erase() {
        stop("Results cleared.")
        clearObservations()
    }

    private func clearObservations() {
        phase = .idle
        idleCount = 0
        stepCounts = [0, 0, 0, 0]
        captures = [nil, nil, nil, nil]
        result = nil
    }

    private func enter(_ next: Phase) {
        guard running, let token = session else { return }
        phase = next
        let duration: Int
        switch next {
        case .idle:
            duration = QuickProbePolicy.idleSeconds
            status = "Leave the fryer untouched for 12 seconds."
        case .tap(let i):
            duration = QuickProbePolicy.stepSeconds
            status = "TAP \(QuickProbePolicy.sequence[i].name.uppercased()) NOW on the fryer. Do not press Start."
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .done: return
        }
        countdown = duration
        finishAt = Date().addingTimeInterval(TimeInterval(duration))
        let id = UUID()
        phaseID = id
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, self.session == token, self.phaseID == id else { return }
            self.countdown = max(0, Int(ceil(self.finishAt.timeIntervalSinceNow)))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(duration)) { [weak self] in
            guard let self, self.session == token, self.phaseID == id else { return }
            self.advance()
        }
    }

    private func advance() {
        guard running else { return }
        switch phase {
        case .idle: enter(.tap(0))
        case .tap(let index) where index < 3: enter(.tap(index + 1))
        case .tap:
            let completed = QuickProbeResult.compare(captures)
            result = completed
            phase = .done
            stop("Comparison complete. Bluetooth disconnected.")
        case .done: break
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
        case .unsupported: stop("Bluetooth Low Energy is unavailable.")
        case .unknown, .resetting: status = "Waiting for Bluetooth…"
        @unknown default: stop("Unknown Bluetooth state.")
        }
    }

    func centralManager(_ manager: CBCentralManager, didDiscover device: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard running, peripheral == nil else { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? device.name ?? ""
        guard BLEObservationPolicy.matchesExactName(name) else { return }
        peripheral = device
        device.delegate = self
        manager.stopScan()
        status = "Fryer model-name match. Connecting to approved Bluetooth services…"
        manager.connect(device, options: nil)
    }

    func centralManager(_ manager: CBCentralManager, didConnect device: CBPeripheral) {
        guard running, peripheral?.identifier == device.identifier else {
            manager.cancelPeripheralConnection(device)
            return
        }
        device.discoverServices(QuickProbePolicy.approvedServices)
    }

    func centralManager(_ manager: CBCentralManager, didFailToConnect device: CBPeripheral,
                        error: Error?) {
        guard peripheral?.identifier == device.identifier else { return }
        stop("Bluetooth connection failed.")
    }

    func centralManager(_ manager: CBCentralManager, didDisconnectPeripheral device: CBPeripheral,
                        error: Error?) {
        guard running, peripheral?.identifier == device.identifier else { return }
        stop("Fryer disconnected before comparison finished.")
    }

    func peripheral(_ device: CBPeripheral, didDiscoverServices error: Error?) {
        guard running, peripheral?.identifier == device.identifier else { return }
        guard error == nil, let services = device.services else { stop("Service discovery failed."); return }
        let filtered = services.filter { QuickProbePolicy.approvedServices.contains($0.uuid) }
        guard !filtered.isEmpty else { stop("No permitted services detected."); return }
        for service in filtered {
            let characteristic = service.uuid == BLEObservationPolicy.serialService
                ? BLEObservationPolicy.serialNotify : BLEObservationPolicy.secondaryNotify
            device.discoverCharacteristics([characteristic], for: service)
        }
    }

    func peripheral(_ device: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard running, peripheral?.identifier == device.identifier, error == nil else { return }
        for characteristic in service.characteristics ?? [] {
            guard QuickProbePolicy.permits(service.uuid, characteristic.uuid),
                  characteristic.properties.contains(.notify) else { continue }
            // CCCD subscription is a descriptor configuration write, NOT a cooking command.
            device.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(_ device: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard running, peripheral?.identifier == device.identifier,
              let service = characteristic.service,
              QuickProbePolicy.permits(service.uuid, characteristic.uuid) else { return }
        if error == nil && characteristic.isNotifying {
            subscriptions.insert(characteristic.uuid.uuidString)
            if !subscribed {
                subscribed = true
                enter(.idle)
            }
        } else if subscriptions.isEmpty {
            status = "Notification subscription unavailable."
        }
    }

    func peripheral(_ device: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard running, subscribed, peripheral?.identifier == device.identifier,
              error == nil, characteristic.isNotifying,
              let service = characteristic.service,
              QuickProbePolicy.permits(service.uuid, characteristic.uuid),
              let bytes = characteristic.value else { return }
        switch phase {
        case .idle: idleCount += 1
        case .tap(let index):
            guard QuickProbePolicy.sequence.indices.contains(index) else { return }
            stepCounts[index] += 1
            guard characteristic.uuid == BLEObservationPolicy.serialNotify else { return }
            if captures[index] == nil && bytes.count > 0 &&
                bytes.count <= QuickProbePolicy.maxFrameBytes {
                captures[index] = Data(bytes)
            }
        case .done: break
        }
    }
}

struct QuickLocalProbeView: View {
    @StateObject private var model = QuickProbeModel()
    @State private var idleConfirmed = false
    @State private var copied = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeading(eyebrow: "LOCAL BLE RESEARCH",
                            title: "Quick Local Probe.",
                            subtitle: "One Start. Four physical taps. Automatic comparison.")
                CrispCard {
                    Label("One short, safe test", systemImage: "shield.lefthalf.filled")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Keep the fryer idle and NOT heating. The app only subscribes to approved Bluetooth notifications, which configures the CCCD descriptor. No Wi-Fi, firmware or cooking commands are sent.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Toggle(isOn: $idleConfirmed) {
                        Text("I am beside the fryer. It is NOT heating.")
                            .font(.subheadline).foregroundColor(CrispPalette.cream)
                    }.tint(CrispPalette.gold).disabled(model.running)
                    Button {
                        copied = false
                        model.start()
                    } label: {
                        Label("Start automatic test", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                    .disabled(!idleConfirmed || model.running)
                }
                CrispCard {
                    Text(model.running ? "DO THIS NOW" : "TEST STATUS")
                        .font(.caption.bold()).foregroundColor(CrispPalette.gold)
                    if model.running && model.subscribed {
                        switch model.phase {
                        case .idle:
                            Text("LEAVE THE FRYER UNTOUCHED")
                                .font(.title2.bold()).foregroundColor(CrispPalette.cream)
                        case .tap:
                            Text("TAP \(model.activePreset?.name.uppercased() ?? "PRESET")")
                                .font(.title2.bold()).foregroundColor(CrispPalette.gold)
                        case .done:
                            Text("Finished").font(.title2.bold()).foregroundColor(CrispPalette.cream)
                        }
                        Text("\(model.countdown)s")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .monospacedDigit().foregroundColor(CrispPalette.cream)
                    } else if model.running {
                        ProgressView("Connecting to fryer…").tint(CrispPalette.gold)
                    }
                    Text(model.status).font(.subheadline).foregroundColor(CrispPalette.muted)
                    if model.running {
                        Button("Stop and disconnect", role: .destructive) { model.stop() }
                            .buttonStyle(.bordered)
                    }
                }
                CrispCard {
                    Label("Automatic sequence", systemImage: "list.number")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("After 12 seconds untouched, each physical-button prompt lasts eight seconds and advances itself. Only tap the fryer, never its Start button.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    ForEach(Array(QuickProbePolicy.sequence.enumerated()), id: \.offset) { i, preset in
                        HStack {
                            Text("\(i + 1). \(preset.name)").foregroundColor(CrispPalette.cream)
                            Spacer()
                            Text("\(model.stepCounts[i]) events")
                                .font(.caption).foregroundColor(CrispPalette.muted)
                        }
                        Divider()
                    }
                }
                if let result = model.result {
                    CrispCard {
                        Label("Byte-position comparison", systemImage: "waveform.path.ecg")
                            .font(.headline).foregroundColor(CrispPalette.gold)
                        Text("Usable FFF1 windows: \(result.received)/4")
                            .foregroundColor(CrispPalette.cream)
                        Text("Candidate positions: \(positions(result.candidatePositions))")
                            .font(.headline).foregroundColor(CrispPalette.gold)
                        Text("Air Fry repeat changed: \(positions(result.airFryChanged))")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text("Reheat repeat changed: \(positions(result.reheatChanged))")
                            .font(.caption).foregroundColor(CrispPalette.muted)
                        Text(result.explanation).font(.footnote).foregroundColor(CrispPalette.muted)
                        Button {
                            UIPasteboard.general.string = result.safeReport(
                                idleCount: model.idleCount, perStep: model.stepCounts)
                            copied = true
                        } label: {
                            Label(copied ? "Safe report copied" : "Copy safe report",
                                  systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                        .foregroundColor(CrispPalette.background)
                    }
                }
                CrispCard {
                    Label("Research only", systemImage: "info.circle")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Only the first FFF1 notification from each step is compared. Its packet bytes are kept temporarily in memory and discarded after analysis. Copy includes only message lengths, counts, and changed byte positions. These are clues, not decoded temperature or preset values. No raw BLE data or device identifiers are exported.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    if !model.running {
                        Button("Clear results") {
                            model.erase()
                            idleConfirmed = false
                            copied = false
                        }.buttonStyle(.bordered)
                    }
                }
            }.padding(20)
        }
        .background(CrispPalette.background)
        .navigationTitle("Quick Local Probe")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { model.erase() }
        .onChange(of: scenePhase) { phase in
            if phase != .active { model.erase() }
        }
    }

    private func positions(_ values: [Int]) -> String {
        values.isEmpty ? "none" : values.map(String.init).joined(separator: ", ")
    }
}
