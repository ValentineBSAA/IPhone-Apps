import SwiftUI
import CoreBluetooth

// There is NO known local-control protocol for CAF-P583S-KUS.
// This diagnostic never sends characteristic writes, firmware commands, or network credentials.
enum BLEObservationPolicy {
    static let exactName = "CAF-P583S-KUS"
    static let serialService = CBUUID(string: "FFF0")
    static let serialNotify = CBUUID(string: "FFF1")
    static let secondaryService = CBUUID(string: "F000FFE0-0451-4000-B000-000000000000")
    static let secondaryNotify = CBUUID(string: "F000FFE2-0451-4000-B000-000000000000")

    static func matchesExactName(_ name: String) -> Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() == exactName
    }

    static func allowsNotification(service: CBUUID, characteristic: CBUUID) -> Bool {
        (service == serialService && characteristic == serialNotify)
            || (service == secondaryService && characteristic == secondaryNotify)
    }

    static let allowedServices = [serialService, secondaryService]
    static let duration: TimeInterval = 45
}

struct BLEObservationEvent: Identifiable, Equatable {
    let id = UUID()
    let secondsAfterStart: Int
    let channel: String
    let byteCount: Int
}

/// All results are session-only metadata. Payload bytes, device IDs, SSIDs and tokens are never saved.
final class BLEEventObservatory: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published private(set) var status = "Idle. Nothing is connected."
    @Published private(set) var isRunning = false
    @Published private(set) var secondsRemaining = Int(BLEObservationPolicy.duration)
    @Published private(set) var eventCount = 0
    @Published private(set) var events: [BLEObservationEvent] = []
    @Published private(set) var foundExactModel = false
    @Published private(set) var activeChannels = 0

    private var central: CBCentralManager?
    private var selected: CBPeripheral?
    private var allowedServiceCallbacks: Set<String> = []
    private var session: UUID?
    private var expiry = Date.distantPast
    private var displayTimer: Timer?

    func start() {
        guard !isRunning else { return }
        eventCount = 0
        events = []
        activeChannels = 0
        foundExactModel = false
        secondsRemaining = Int(BLEObservationPolicy.duration)
        isRunning = true
        let token = UUID()
        session = token
        expiry = Date().addingTimeInterval(BLEObservationPolicy.duration)
        status = "Finding CAF-P583S-KUS. Only its exact advertised model name is accepted."

        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshCountdown()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + BLEObservationPolicy.duration) { [weak self] in
            guard let self, self.session == token else { return }
            self.stop(reason: "45-second observation ended. No device-control commands were sent.")
        }

        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main, options: [
                CBCentralManagerOptionShowPowerAlertKey: false
            ])
        } else if let central {
            centralManagerDidUpdateState(central)
        }
    }

    func stop(reason: String = "Observation stopped. No device-control commands were sent.") {
        session = nil
        isRunning = false
        displayTimer?.invalidate()
        displayTimer = nil
        secondsRemaining = 0
        central?.stopScan()
        allowedServiceCallbacks.removeAll()
        if let peripheral = selected {
            peripheral.delegate = nil
            if peripheral.state != .disconnected {
                central?.cancelPeripheralConnection(peripheral)
            }
        }
        selected = nil
        status = reason
    }

    private func refreshCountdown() {
        guard isRunning else { return }
        secondsRemaining = max(0, Int(ceil(expiry.timeIntervalSinceNow)))
        if secondsRemaining == 0 {
            stop(reason: "45-second observation finished. No cooking commands were sent.")
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard isRunning else { return }
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ])
            status = "Looking for your fryer…"
        case .poweredOff:
            stop(reason: "Bluetooth is off. Turn it on and try again.")
        case .unauthorized:
            stop(reason: "Bluetooth permission denied. Check iPhone Settings → Privacy.")
        case .unsupported:
            stop(reason: "Bluetooth Low Energy is not supported on this iPhone.")
        case .resetting, .unknown:
            status = "Bluetooth is becoming available…"
        @unknown default:
            stop(reason: "Unknown Bluetooth state.")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        guard isRunning, selected == nil else { return }
        let advertised = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertised ?? peripheral.name ?? ""
        guard BLEObservationPolicy.matchesExactName(name) else { return }
        foundExactModel = true
        selected = peripheral
        peripheral.delegate = self
        central.stopScan()
        status = "Model-name match found. Connecting to observe notification metadata…"
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard isRunning, selected?.identifier == peripheral.identifier else {
            central.cancelPeripheralConnection(peripheral)
            return
        }
        status = "Connected. Checking only the two approved notification services…"
        peripheral.discoverServices(BLEObservationPolicy.allowedServices)
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        guard selected?.identifier == peripheral.identifier else { return }
        stop(reason: "Couldn't connect to fryer. Nothing was changed.")
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        guard isRunning, selected?.identifier == peripheral.identifier else { return }
        stop(reason: "Fryer disconnected. Results retained only on this screen.")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard isRunning, selected?.identifier == peripheral.identifier else { return }
        guard error == nil, let services = peripheral.services else {
            stop(reason: "Bluetooth service discovery failed. No device controls were sent.")
            return
        }
        let allowed = services.filter { BLEObservationPolicy.allowedServices.contains($0.uuid) }
        if allowed.isEmpty {
            stop(reason: "No approved notification services were found.")
            return
        }
        allowedServiceCallbacks = Set(allowed.map { $0.uuid.uuidString })
        for service in allowed {
            let needed: CBUUID = service.uuid == BLEObservationPolicy.serialService
                ? BLEObservationPolicy.serialNotify : BLEObservationPolicy.secondaryNotify
            peripheral.discoverCharacteristics([needed], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard isRunning, selected?.identifier == peripheral.identifier else { return }
        allowedServiceCallbacks.remove(service.uuid.uuidString)
        if error == nil {
            for characteristic in service.characteristics ?? [] {
                guard BLEObservationPolicy.allowsNotification(
                    service: service.uuid, characteristic: characteristic.uuid
                ), characteristic.properties.contains(.notify) else { continue }
                // Subscribing changes the BLE CCCD descriptor (a configuration write).
                // No characteristic value is read or written here. Firmware OAD is excluded.
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        if allowedServiceCallbacks.isEmpty {
            status = "Listening for notifications. Adjust presets on the fryer while idle. Do not press Start."
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard isRunning, selected?.identifier == peripheral.identifier else { return }
        guard let service = characteristic.service,
              BLEObservationPolicy.allowsNotification(service: service.uuid,
                                                       characteristic: characteristic.uuid) else { return }
        if error == nil && characteristic.isNotifying {
            activeChannels += 1
            status = "Listening on \(activeChannels) approved channel(s). Keep the fryer idle."
        } else {
            status = "Notification subscription was unavailable. The fryer may require authentication."
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard isRunning, selected?.identifier == peripheral.identifier, error == nil,
              let service = characteristic.service,
              BLEObservationPolicy.allowsNotification(service: service.uuid,
                                                       characteristic: characteristic.uuid),
              characteristic.isNotifying else { return }
        // Length only. Never copy/print/parse/save characteristic.value contents.
        let count = characteristic.value?.count ?? 0
        let elapsed = max(0, Int(BLEObservationPolicy.duration - expiry.timeIntervalSinceNow))
        eventCount += 1
        if events.count < 60 {
            events.append(BLEObservationEvent(secondsAfterStart: elapsed,
                                               channel: characteristic.uuid.uuidString,
                                               byteCount: count))
        }
    }
}

struct BLEEventObservatoryView: View {
    @StateObject private var observer = BLEEventObservatory()
    @State private var idleConfirmed = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeading(eyebrow: "CLOUD-FREE RESEARCH",
                            title: "Event Observatory.",
                            subtitle: "Listen for local Bluetooth activity. Never operate the heater from here.")
                CrispCard {
                    Label("A controlled 45-second test", systemImage: "waveform.path.ecg")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("This experiment connects only to a device advertising CAF-P583S-KUS. It subscribes to FFF1 and F000FFE2. Subscribing changes the Bluetooth notification descriptor. It does not send cooking commands, collect your Wi-Fi password, or contact VeSync.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Toggle(isOn: $idleConfirmed) {
                        Text("I confirm the fryer is idle, not heating, and I am nearby.")
                            .font(.subheadline).foregroundColor(CrispPalette.cream)
                    }
                    .tint(CrispPalette.gold)
                    .disabled(observer.isRunning)
                    HStack(spacing: 12) {
                        Button {
                            observer.start()
                        } label: {
                            Label("Start observation", systemImage: "play.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(CrispPalette.gold)
                        .foregroundColor(CrispPalette.background)
                        .disabled(!idleConfirmed || observer.isRunning)
                        Button("Stop") {
                            observer.stop()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!observer.isRunning)
                    }
                    Text(observer.status)
                        .font(.subheadline).foregroundColor(CrispPalette.cream)
                    if observer.isRunning {
                        ProgressView(value: Double(45 - observer.secondsRemaining), total: 45)
                            .tint(CrispPalette.gold)
                        Text("\(observer.secondsRemaining) seconds remaining")
                            .font(.caption).monospacedDigit()
                            .foregroundColor(CrispPalette.muted)
                    }
                }
                CrispCard {
                    Label("Local signals", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    HStack {
                        metric("Device match", observer.foundExactModel ? "Found" : "Not found")
                        metric("Channels", "\(observer.activeChannels)")
                        metric("Events", "\(observer.eventCount)")
                    }
                    Text("The app shows only a timestamp, channel identifier and byte length. No message contents or identifiable device IDs are saved.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    if observer.events.isEmpty {
                        Text("No notification events have been received. This does not mean local control is impossible.")
                            .font(.footnote).foregroundColor(CrispPalette.muted)
                    } else {
                        ForEach(observer.events) { event in
                            HStack(spacing: 8) {
                                Text("+\(event.secondsAfterStart)s").monospacedDigit()
                                Spacer(minLength: 4)
                                Text(event.channel)
                                Spacer(minLength: 4)
                                Text("\(event.byteCount) bytes").monospacedDigit()
                            }
                            .font(.caption).foregroundColor(CrispPalette.cream)
                            Divider()
                        }
                        if observer.eventCount > observer.events.count {
                            Text("Only the first 60 events are shown.")
                                .font(.caption2).foregroundColor(CrispPalette.muted)
                        }
                    }
                }
                CrispCard {
                    Label("Physical test instructions", systemImage: "hand.raised.fill")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Keep the fryer plugged in but NOT cooking. After tapping Start observation, use only its physical controls to switch between presets or adjust the displayed time or temperature without pressing Start. The app automatically disconnects after 45 seconds. If the fryer unexpectedly heats or behaves differently, tap Stop immediately.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Text("This is diagnostic metadata, not live temperature or a pairing wizard. Even if events appear, their meanings are still unknown.")
                        .font(.caption).foregroundColor(CrispPalette.muted)
                }
            }
            .padding(20)
        }
        .background(CrispPalette.background)
        .navigationTitle("BLE Event Observatory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onDisappear {
            if observer.isRunning { observer.stop(reason: "Screen closed. Bluetooth disconnected.") }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active && observer.isRunning {
                observer.stop(reason: "App left foreground. Bluetooth disconnected.")
            }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title3.bold()).monospacedDigit()
                .foregroundColor(CrispPalette.cream)
            Text(title).font(.caption2)
                .foregroundColor(CrispPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(CrispPalette.panelRaised, in: RoundedRectangle(cornerRadius: 15))
    }
}
