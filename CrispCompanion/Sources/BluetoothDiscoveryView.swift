import SwiftUI
import CoreBluetooth

/// A discovery-only diagnostic. It never connects or sends data to a peripheral.
struct BLEDiscovery: Identifiable, Equatable {
    let id: UUID
    let name: String
    let advertisedServices: [String]
    let signalStrength: Int
    var possibleFryer: Bool {
        let lower = name.lowercased()
        return lower.contains("vesync") || lower.contains("cosori") ||
               lower.contains("p583") || lower.contains("afr")
    }
}

final class BluetoothDiscoveryModel: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published private(set) var devices: [BLEDiscovery] = []
    @Published private(set) var stateText = "Ready to scan"
    @Published private(set) var scanning = false
    private var central: CBCentralManager?
    private var wantsToScan = false

    func start() {
        devices = []
        wantsToScan = true
        stateText = "Requesting Bluetooth access…"
        if central == nil {
            // Permission is prompted only from this explicit action.
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
        if stateText == "Scanning nearby Bluetooth devices…" {
            stateText = "Scan stopped"
        }
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
            stateText = "Bluetooth is turned off. Enable it in iPhone Settings."
        case .unauthorized:
            scanning = false
            stateText = "Bluetooth access was denied. Enable it in iPhone privacy settings."
        case .unsupported:
            scanning = false
            stateText = "Bluetooth Low Energy isn't available on this device."
        case .resetting, .unknown:
            scanning = false
            stateText = "Waiting for Bluetooth to become available…"
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
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertisedName ?? peripheral.name ?? "Unnamed Bluetooth device"
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? [])
            .map(\.uuidString).sorted()
        let device = BLEDiscovery(
            id: peripheral.identifier, name: name,
            advertisedServices: services,
            signalStrength: RSSI.intValue
        )
        if let position = devices.firstIndex(where: { $0.id == device.id }) {
            devices[position] = device
        } else {
            devices.append(device)
        }
        // Prioritize only NAME hints. Discovery never proves device identity.
        devices.sort {
            if $0.possibleFryer != $1.possibleFryer { return $0.possibleFryer }
            return $0.signalStrength > $1.signalStrength
        }
    }
}

struct BluetoothDiscoveryView: View {
    @StateObject private var discovery = BluetoothDiscoveryModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeading(
                    eyebrow: "LOCAL PAIRING RESEARCH",
                    title: "Find my fryer.",
                    subtitle: "Discover nearby Bluetooth devices with your iPhone."
                )

                CrispCard {
                    Label("Discovery only", systemImage: "shield.lefthalf.filled")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("The COSORI CAF-P583S family is reported as using Bluetooth onboarding. This tool scans advertisements but DOES NOT pair, send Wi-Fi passwords, register a VeSync account, or operate the heater.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Text(discovery.stateText)
                        .font(.subheadline.weight(.medium)).foregroundColor(CrispPalette.cream)
                    HStack(spacing: 12) {
                        Button {
                            discovery.start()
                        } label: {
                            Label(discovery.scanning ? "Scan again" : "Start scan", systemImage: "antenna.radiowaves.left.and.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(CrispPalette.gold)
                        .foregroundColor(CrispPalette.background)
                        Button("Stop") { discovery.stop() }
                            .buttonStyle(.bordered)
                            .disabled(!discovery.scanning)
                    }
                }

                CrispCard {
                    Text("Nearby advertisements")
                        .font(.headline).foregroundColor(CrispPalette.cream)
                    Text("\(discovery.devices.count) discovered · Session only · No data uploaded")
                        .font(.caption).foregroundColor(CrispPalette.muted)
                    if discovery.devices.isEmpty {
                        Text("Nothing detected yet. A fryer may not advertise until its pairing mode is enabled. Some nearby devices may not support Bluetooth Low Energy.")
                            .font(.footnote).foregroundColor(CrispPalette.muted)
                    }
                    ForEach(discovery.devices) { device in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .foregroundColor(device.possibleFryer ? CrispPalette.gold : CrispPalette.muted)
                                Text(device.name)
                                    .font(.subheadline.weight(.semibold)).foregroundColor(CrispPalette.cream)
                                    .lineLimit(2)
                                Spacer(minLength: 4)
                            }
                            Text("Signal: \(device.signalStrength) dBm")
                                .font(.caption).foregroundColor(CrispPalette.muted)
                            if !device.advertisedServices.isEmpty {
                                Text("Advertised services: \(device.advertisedServices.joined(separator: ", "))")
                                    .font(.caption2).foregroundColor(CrispPalette.muted)
                                    .textSelection(.enabled)
                            }
                            if device.possibleFryer {
                                Text("Possible manufacturer name match · NOT verified identity")
                                    .font(.caption2).foregroundColor(CrispPalette.gold)
                            }
                        }
                        .padding(.vertical, 6)
                        Divider().overlay(Color.white.opacity(0.08))
                    }
                }

                CrispCard {
                    Label("What happens after discovery?", systemImage: "info.circle")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("If you can see a likely fryer advertisement, we'll research its pairing services and authentication before attempting ANY connection. If nothing appears, we must investigate hardware pairing mode or a different provisioning method. This is not an automatic pairing wizard yet.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Text("Privacy: scans stay in memory and are cleared when the page closes. Do not share nearby device identifiers or home network credentials publicly.")
                        .font(.caption2).foregroundColor(CrispPalette.muted)
                }
            }
            .padding(20)
        }
        .background(CrispPalette.background)
        .navigationTitle("Bluetooth discovery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onDisappear { discovery.stop() }
    }
}
