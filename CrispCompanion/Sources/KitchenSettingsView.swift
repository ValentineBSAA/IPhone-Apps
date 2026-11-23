import SwiftUI

struct KitchenSettingsView: View {
    @EnvironmentObject private var kitchen: KitchenStore
    @State private var token = ""
    @State private var address = ""
    @State private var savedNotice = ""
    @State private var showAdvancedBluetooth = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeading(eyebrow: "PREFERENCES", title: "Make it yours.", subtitle: "Keep your kitchen private, clear, and in control.")
                CrispCard {
                    Toggle(isOn: $kitchen.previewMode) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Preview mode").font(.headline).foregroundColor(CrispPalette.cream)
                            Text("Explore the UI without contacting your appliance")
                                .font(.caption).foregroundColor(CrispPalette.muted)
                        }
                    }
                    .tint(CrispPalette.gold)
                    if !kitchen.previewMode {
                        Text("Live mode requires an already paired VeSync device and an authorized HTTPS NAS bridge.")
                            .font(.footnote).foregroundColor(CrispPalette.gold)
                    }
                }
                CrispCard {
                    Label("Signal Structure", systemImage: "waveform.path.ecg")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Our shortest signal experiment: three physical taps, automatic timing, and private analysis of bytes 2 and 5. It does not operate the fryer.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    NavigationLink {
                        BLEStructureProbeView()
                    } label: {
                        Label("Open Signal Structure", systemImage: "chart.xyaxis.line")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                }
                CrispCard {
                    Label("Quick Local Probe", systemImage: "waveform.path.ecg")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("One Start, four physical taps. Automatic timing and private byte-position comparison. No 24-preset routine.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    NavigationLink {
                        QuickLocalProbeView()
                    } label: {
                        Label("Open Quick Local Probe", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                }
                DisclosureGroup(isExpanded: $showAdvancedBluetooth) {
                    VStack(spacing: 16) {
                CrispCard {
                    Label("Find my fryer", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Your COSORI appears first. Inspect its Bluetooth service identifiers, without Wi-Fi setup, account registration or cooking commands.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    NavigationLink {
                        BluetoothDiscoveryView()
                    } label: {
                        Label("Open Bluetooth discovery", systemImage: "waveform.path")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                }
                CrispCard {
                    Label("BLE Event Observatory", systemImage: "waveform.path.ecg")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Cloud-free, idle-only diagnostic: listen for local Bluetooth notification lengths for 45 seconds, without sending cooking commands.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    NavigationLink {
                        BLEEventObservatoryView()
                    } label: {
                        Label("Open Event Observatory", systemImage: "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                }
                CrispCard {
                    Label("Packet Comparison", systemImage: "arrow.left.arrow.right")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Compare a 45-second untouched baseline with physical settings changes, without storing raw Bluetooth messages or sending commands.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    NavigationLink {
                        BLEPacketComparisonView()
                    } label: {
                        Label("Open Packet Comparison", systemImage: "waveform.path")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                }
                CrispCard {
                    Label("Preset Mapping", systemImage: "square.grid.3x3.fill")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("Guide 12 physical presets through two repeatable five-second Bluetooth notification windows, without decoding or sending cooking commands.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    NavigationLink {
                        BLEPresetMappingView()
                    } label: {
                        Label("Open Preset Mapping", systemImage: "waveform.path.ecg")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                }
                    }
                    .padding(.top, 12)
                } label: {
                    Label("Advanced Bluetooth diagnostics", systemImage: "slider.horizontal.3")
                        .font(.headline).foregroundColor(CrispPalette.cream)
                }
                .tint(CrispPalette.gold)
                .padding(16)
                .background(CrispPalette.panelRaised, in: RoundedRectangle(cornerRadius: 16))
                CrispCard {
                    Label("Private NAS bridge", systemImage: "lock.shield.fill")
                        .font(.headline).foregroundColor(CrispPalette.cream)
                    Text("Optional. Settings are stored on this device. Your VeSync password belongs ONLY on your own NAS, never in the app.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    TextField("https://your-private-bridge.example", text: $address)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(CrispPalette.panelRaised, in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("HTTPS bridge address")
                    SecureField("Bridge access token", text: $token)
                        .textInputAutocapitalization(.never)
                        .padding(12)
                        .background(CrispPalette.panelRaised, in: RoundedRectangle(cornerRadius: 12))
                    Button("Save connection settings") {
                        kitchen.bridgeURL = address
                        if !token.isEmpty { BridgeTokenVault.save(token) }
                        savedNotice = "Connection settings saved on this iPhone."
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CrispPalette.gold)
                    .foregroundColor(CrispPalette.background)
                    Button("Test secure connection") {
                        Task { await kitchen.refresh() }
                    }
                    .disabled(kitchen.previewMode || kitchen.isRefreshing)
                    if !savedNotice.isEmpty { Text(savedNotice).font(.caption).foregroundColor(CrispPalette.green) }
                    if let error = kitchen.lastError { Text(error).font(.caption).foregroundColor(CrispPalette.peach) }
                }
                CrispCard {
                    Label("What Build 1 can do", systemImage: "checkmark.seal")
                        .font(.headline).foregroundColor(CrispPalette.cream)
                    Text("Premium iPhone dashboard, preset planning, saved personal recipes, manual timer, notification requests, and optional read-only device status through a private bridge.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                }
                CrispCard {
                    Label("Still to unlock", systemImage: "wrench.and.screwdriver")
                        .font(.headline).foregroundColor(CrispPalette.gold)
                    Text("First-time Wi-Fi provisioning, firmware-specific controls, official recipe synchronization, and real appliance events require pairing research and physical testing. No heat-start control is provided.")
                        .font(.footnote).foregroundColor(CrispPalette.muted)
                    Text("Unofficial independent companion · v0.1.6 · iOS 16+")
                        .font(.caption2).foregroundColor(CrispPalette.muted)
                }
            }
            .padding(20)
        }
        .background(CrispPalette.background)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { address = kitchen.bridgeURL }
    }
}
