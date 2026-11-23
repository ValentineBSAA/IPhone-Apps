import SwiftUI

struct KitchenSettingsView: View {
    @EnvironmentObject private var kitchen: KitchenStore
    @State private var token = ""
    @State private var address = ""
    @State private var savedNotice = ""

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
                    Text("Unofficial independent companion · v0.1.1 · iOS 16+")
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
