import SwiftUI
import CoreBluetooth

/// An advertisement name is a clue, not proof of hardware identity.
struct BLEDiscovery: Identifiable, Equatable {
    let id: UUID
    let name: String
    let advertisedServices: [String]
    let signalStrength: Int

    var modelMatch: Bool { name.uppercased() == "CAF-P583S-KUS" }
    var possibleFryer: Bool {
        let lower = name.lowercased()
        return modelMatch || lower.contains("cosori") || lower.contains("vesync") || lower.contains("p583")
    }
    var description: String {
        if modelMatch { return "COSORI Dual Blaze model-name match" }
        if possibleFryer { return "Possible COSORI / VeSync advertisement" }
        if name.lowercased().hasPrefix("[tv]") { return "TV, based on advertised name" }
        if name.lowercased().contains("jbl") { return "Audio device, based on advertised name" }
        if name == "Unnamed Bluetooth device" { return "Unknown Bluetooth device" }
        return "Other Bluetooth advertisement"
    }
}

struct BLECharacteristicInfo: Identifiable, Equatable {
    let id: String
    let capabilities: String
}

struct BLEServiceInfo: Identifiable, Equatable {
    let id: String
    let characteristics: [BLECharacteristicInfo]
}

/// Only performs user-initiated scan/connect/GATT metadata discovery.
/// NEVER reads characteristic values, subscribes to notifications, writes, or sends Wi-Fi credentials.
final class BluetoothDiscoveryModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published private(set) var devices: [BLEDiscovery] = []
    @Published private(set) var stateText = "Ready to scan"
    @Published private(set) var scanning = false
    @Published private(set) var inspectionText = "Select your fryer to inspect its Bluetooth service names."
    @Published private(set) var inspectedServices: [BLEServiceInfo] = []
    @Published private(set) var inspectionInProgress = false
    @Published private(set) var inspectedName: String?
    private var central: CBCentralManager?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var wantsToScan = false
    private var selected: CBPeripheral?
    private var pendingServiceUUIDs: Set<String> = []

    var fryerCandidates: [BLEDiscovery] { devices.filter(\.possibleFryer) }
    var otherDevices: [BLEDiscovery] { devices.filter { !$0.possibleFryer } }

    func start() {
        stopInspection()
        devices = []
        peripherals = [:]
        wantsToScan = true
        stateText = "Requesting Bluetooth access…"
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main, options: [
                CBCentralManagerOptionShowPowerAlertKey: false
            ])
        } else if let central {
            centralManagerDidUpdateState(central)
        }
    }

    func stop() {
        wantsToScan = false
        central?.stopScan()
        scanning = false
        stopInspection()
        stateText = "Scan stopped"
    }

    func stopInspection() {
        inspectionInProgress = false
        pendingServiceUUIDs.removeAll()
        if let selected, selected.state != .disconnected {
            central?.cancelPeripheralConnection(selected)
        }
        selected?.delegate = nil
        selected = nil
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard wantsToScan else { return }
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ])
            scanning = true
            stateText = "Scanning nearby Bluetooth devices…"
        case .poweredOff:
            scanning = false
            stateText = "Bluetooth is off. Enable it in iPhone Settings."
        case .unauthorized:
            scanning = false
            stateText = "Bluetooth access denied. Enable it under Privacy."
        case .unsupported:
            scanning = false
            stateText = "Bluetooth Low Energy is unavailable."
        case .resetting, .unknown:
            scanning = false
            stateText = "Waiting for Bluetooth…"
        @unknown default:
            scanning = false
            stateText = "Bluetooth state unknown."
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        guard wantsToScan else { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? peripheral.name ?? "Unnamed Bluetooth device"
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [])
            .map(\.uuidString).sorted()
        let item = BLEDiscovery(id: peripheral.identifier, name: name,
                                advertisedServices: services, signalStrength: RSSI.intValue)
        peripherals[item.id] = peripheral
        if let position = devices.firstIndex(where: { $0.id == item.id }) {
            devices[position] = item
        } else {
            devices.append(item)
        }
        devices.sort {
            if $0.modelMatch != $1.modelMatch { return $0.modelMatch }
            if $0.possibleFryer != $1.possibleFryer { return $0.possibleFryer }
            return $0.signalStrength > $1.signalStrength
        }
    }

    func inspect(_ device: BLEDiscovery) {
        guard device.possibleFryer else { return }
        guard central?.state == .poweredOn, let peripheral = peripherals[device.id] else {
            inspectionText = "The device is no longer available. Scan again."
            return
        }
        stopInspection()
        central?.stopScan()
        scanning = false
        wantsToScan = false
        selected = peripheral
        inspectedName = device.name
        inspectedServices = []
        inspectionInProgress = true
        inspectionText = "Connecting temporarily to inspect Bluetooth services…"
        peripheral.delegate = self
        central?.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard selected?.identifier == peripheral.identifier else {
            central.cancelPeripheralConnection(peripheral)
            return
        }
        inspectionText = "Bluetooth connected. Reading service and characteristic identifiers only…"
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard selected?.identifier == peripheral.identifier else { return }
        inspectionInProgress = false
        inspectionText = "Bluetooth connection failed. The fryer may require pairing mode."
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard selected?.identifier == peripheral.identifier else { return }
        inspectionInProgress = false
        if inspectedServices.isEmpty {
            inspectionText = "Disconnected before service discovery. Try again with the fryer powered on."
        } else {
            inspectionText = "Service inspection complete. No cooking commands were sent."
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard selected?.identifier == peripheral.identifier else { return }
        guard error == nil, let services = peripheral.services else {
            inspectionText = "Could not discover service identifiers. No device settings were changed."
            inspectionInProgress = false
            central?.cancelPeripheralConnection(peripheral)
            return
        }
        inspectedServices = services.map { BLEServiceInfo(id: $0.uuid.uuidString, characteristics: []) }
        pendingServiceUUIDs = Set(services.map { $0.uuid.uuidString })
        if services.isEmpty {
            inspectionText = "Connected, but no services were reported."
            inspectionInProgress = false
            central?.cancelPeripheralConnection(peripheral)
        } else {
            for service in services {
                // Metadata discovery only. Never read characteristic values.
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard selected?.identifier == peripheral.identifier else { return }
        let id = service.uuid.uuidString
        let discovered = (error == nil ? service.characteristics : nil) ?? []
        let characteristics: [BLECharacteristicInfo] = discovered.map { item in
            var properties: [String] = []
            if item.properties.contains(.read) { properties.append("readable") }
            if item.properties.contains(.write) { properties.append("writable") }
            if item.properties.contains(.writeWithoutResponse) { properties.append("write without response") }
            if item.properties.contains(.notify) { properties.append("notifiable") }
            if item.properties.contains(.indicate) { properties.append("indicates") }
            return BLECharacteristicInfo(id: item.uuid.uuidString, capabilities: properties.joined(separator: ", "))
        }
        if let index = inspectedServices.firstIndex(where: { $0.id == id }) {
            inspectedServices[index] = BLEServiceInfo(id: id, characteristics: characteristics)
        }
        pendingServiceUUIDs.remove(id)
        if pendingServiceUUIDs.isEmpty {
            inspectionInProgress = false
            inspectionText = "Service identifiers found. No values, passwords, or controls were accessed."
            central?.cancelPeripheralConnection(peripheral)
        }
    }
}

struct BluetoothDiscoveryView: View {
    @StateObject private var discovery = BluetoothDiscoveryModel()
    @State private var showOtherDevices = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeading(eyebrow: "LOCAL CONNECTION RESEARCH",
                            title: "Find my fryer.",
                            subtitle: "Your COSORI first. Everything else can stay out of the way.")
                CrispCard {
                    Label("Bluetooth diagnostics", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("We can find the fryer and inspect its service identifiers, but we cannot yet connect it to Wi-Fi or VeSync. No cooking controls are available.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Text(discovery.stateText).font(.subheadline).foregroundColor(CrispPalette.cream)
                    HStack {
                        Button {
                            discovery.start()
                        } label: { Label("Scan again", systemImage: "arrow.clockwise").frame(maxWidth: .infinity) }
                            .buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                            .foregroundColor(CrispPalette.background)
                        Button("Stop") { discovery.stop() }
                            .buttonStyle(.bordered)
                            .disabled(!discovery.scanning && !discovery.inspectionInProgress)
                    }
                }
                CrispCard {
                    Label("Your air fryer", systemImage: "flame.fill")
                        .font(.title3.bold()).foregroundColor(CrispPalette.gold)
                    if discovery.fryerCandidates.isEmpty {
                        Text("No COSORI advertisement detected yet. Keep the fryer powered on and scan again.")
                            .font(.footnote).foregroundColor(CrispPalette.muted)
                    }
                    ForEach(discovery.fryerCandidates) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(item.name).font(.headline).foregroundColor(CrispPalette.cream)
                                Spacer()
                                if item.modelMatch {
                                    Text("MODEL MATCH")
                                        .font(.caption2.bold()).foregroundColor(CrispPalette.gold)
                                }
                            }
                            Text(item.description).font(.caption).foregroundColor(CrispPalette.muted)
                            Label("Bluetooth signal: \(item.signalStrength) dBm", systemImage: "waveform")
                                .font(.caption).foregroundColor(CrispPalette.cream)
                            Text("Detected nearby, NOT paired or Wi-Fi connected.")
                                .font(.caption2).foregroundColor(CrispPalette.muted)
                            Button {
                                discovery.inspect(item)
                            } label: {
                                Label("Inspect Bluetooth services", systemImage: "magnifyingglass")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent).tint(CrispPalette.gold)
                            .foregroundColor(CrispPalette.background)
                            .disabled(discovery.inspectionInProgress)
                        }
                    }
                }
                if discovery.inspectedName != nil {
                    CrispCard {
                        Label("Bluetooth service inspection", systemImage: "wrench.adjustable")
                            .font(.headline).foregroundColor(CrispPalette.gold)
                        Text(discovery.inspectionText).font(.footnote).foregroundColor(CrispPalette.muted)
                        if discovery.inspectionInProgress {
                            ProgressView().tint(CrispPalette.gold)
                        }
                        if discovery.inspectedServices.isEmpty && !discovery.inspectionInProgress {
                            Text("No service UUIDs available yet. This does not mean the device has no Bluetooth functions.")
                                .font(.caption).foregroundColor(CrispPalette.muted)
                        }
                        ForEach(discovery.inspectedServices) { service in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Service: \(service.id)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(CrispPalette.cream).textSelection(.enabled)
                                if service.characteristics.isEmpty {
                                    Text("No characteristics reported")
                                        .font(.caption2).foregroundColor(CrispPalette.muted)
                                }
                                ForEach(service.characteristics) { characteristic in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(characteristic.id)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(CrispPalette.gold).textSelection(.enabled)
                                        Text(characteristic.capabilities.isEmpty ? "No advertised properties" : characteristic.capabilities)
                                            .font(.caption2).foregroundColor(CrispPalette.muted)
                                    }
                                }
                            }
                            Divider()
                        }
                    }
                }
                CrispCard {
                    DisclosureGroup(isExpanded: $showOtherDevices) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(discovery.otherDevices) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name).font(.subheadline.weight(.medium)).foregroundColor(CrispPalette.cream)
                                    Text(item.description + " · \(item.signalStrength) dBm")
                                        .font(.caption).foregroundColor(CrispPalette.muted)
                                    if !item.advertisedServices.isEmpty {
                                        Text("Services: " + item.advertisedServices.joined(separator: ", "))
                                            .font(.caption2).foregroundColor(CrispPalette.muted)
                                    }
                                }
                                Divider()
                            }
                        }
                        .padding(.top, 12)
                    } label: {
                        Text("Other nearby devices (\(discovery.otherDevices.count))")
                            .font(.headline).foregroundColor(CrispPalette.cream)
                    }
                    .tint(CrispPalette.gold)
                    Text("Bluetooth names aren't a universal product directory. Unknown devices remain unidentified rather than guessed.")
                        .font(.caption).foregroundColor(CrispPalette.muted)
                }
                CrispCard {
                    Label("Safety and privacy", systemImage: "hand.raised.fill")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Inspection briefly connects over Bluetooth to list service and characteristic identifiers. It never reads characteristic data, writes to them, sends Wi-Fi credentials, registers an account, or starts heat. Leave this screen to disconnect. Results stay in memory.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                }
            }.padding(20)
        }
        .background(CrispPalette.background)
        .navigationTitle("Bluetooth diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onDisappear { discovery.stop() }
    }
}
