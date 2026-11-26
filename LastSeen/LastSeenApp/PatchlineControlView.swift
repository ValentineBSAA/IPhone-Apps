import SwiftUI

/// In-game control utility; no access to the real system or real jailbreak state.
struct PatchlineControlView: View {
    let openRelay: () -> Void
    let onRestart: () -> Void
    let earnedFlags: Set<String>
    @AppStorage("lastseen.relay.safeMode") private var safeMode = false
    @AppStorage("lastseen.relay.installed") private var installed = ""
    @AppStorage("lastseen.relay.versions") private var versions = ""
    @AppStorage("lastseen.relay.sources") private var sources = RelayCatalog.defaultSources
    @AppStorage("lastseen.relay.history") private var history = ""
    @AppStorage("lastseen.recovery.effects") private var effects = true
    @State private var restart: RelayRestart?
    @State private var confirm: RelayRestart?
    @State private var showGuide = false
    @Environment(\.scenePhase) private var phase
    private var optionalPackages:[RelayPackage] {
        RelayCatalog.packages.filter{!$0.essential && RelayCatalog.ids(installed).contains($0.id)}
    }
    private var activePackages:Int {
        optionalPackages.filter{PatchlinePackageHealth.status($0,installed:RelayCatalog.ids(installed),flags:earnedFlags,safeMode:safeMode) == .active}.count
    }
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    OpeningArt(name: "Jailbreak_Patchline", size: 70)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Patchline").font(.largeTitle.bold())
                        Label(safeMode ? "Safe Mode" : "Jailbroken", systemImage: safeMode ? "exclamationmark.shield" : "checkmark.seal.fill")
                            .foregroundColor(safeMode ? .orange : .teal)
                        Text("Rootless • Environment 2.0").font(.caption).foregroundColor(.secondary)
                    }
                }.padding(.vertical, 12)
                LabeledContent("Tweak loader", value: safeMode ? "Disabled" : "Active")
                LabeledContent("Installed optional packages",value:String(optionalPackages.count))
                LabeledContent("Active optional packages",value:String(activePackages))
                LabeledContent("Paused or unavailable",value:String(optionalPackages.count-activePackages))
            }
            Section("Environment") {
                LabeledContent("Bootstrap", value: RelayCatalog.package("bootstrap")?.version ?? "Unavailable")
                LabeledContent("Loader", value: RelayCatalog.package("loader")?.version ?? "Unavailable")
                LabeledContent("Package manager", value: RelayCatalog.package("relay")?.version ?? "Unavailable")
                LabeledContent("Registered repositories", value: String(RelayCatalog.ids(RelayCatalog.recoveredSources(sources, flags: earnedFlags)).count))
                LabeledContent("Essential packages", value: String(RelayCatalog.packages.filter(\.essential).count))
                NavigationLink("Package activity") {
                    List {
                        Section("Local transactions") {
                            let entries = history.split(separator: "\n").map(String.init)
                            if entries.isEmpty { Text("No completed transactions").foregroundColor(.secondary) }
                            ForEach(Array(entries.enumerated()), id: \.offset) { entry in Text(entry.element).font(.caption.monospaced()) }
                        }
                        Section("Installed packages") {
                            ForEach(RelayCatalog.packages.filter { RelayCatalog.installed($0.id, userIDs: RelayCatalog.ids(installed)) }) { package in
                                LabeledContent(package.title, value: RelayCatalog.installedVersion(package, versions: RelayCatalog.versions(versions)))
                            }
                        }
                    }.navigationTitle("Package activity")
                }
            }
            if EntityEcho.active(earnedFlags) {
                Section("Foreign extension") {
                    Label(safeMode ? "ECHO paused · still installed" : "ECHO · three unverified hooks",systemImage:"exclamationmark.shield").foregroundColor(.orange)
                    Text("Clock seconds, compact icons and hidden badge counts. Safe Mode pauses these overrides; quarantine removes them.").font(.caption)
                    NavigationLink { EntityEchoRemovalView() } label: {Label("Contain foreign extension",systemImage:"waveform.path.ecg")}
                }
            } else if earnedFlags.contains(EntityEcho.removed) {
                Section("Foreign extension") {Label("ECHO quarantined",systemImage:"checkmark.shield")}
            }
            Section("Diagnostics") {
                NavigationLink { PatchlineLoaderDiagnostics(flags: earnedFlags) } label: { Label("Tweak loader diagnostics", systemImage: "cpu") }
                NavigationLink { RecoveryCircuitView() } label: { Label("Recovery Circuit", systemImage: "point.3.connected.trianglepath.dotted") }
                NavigationLink { UtilityProgressView(openRelay: openRelay, onRestart: onRestart) } label: { Label("Local services", systemImage: "square.grid.2x2") }
            }
            Section("Maintenance") {
                Button { openRelay() } label: { Label("Open Relay", systemImage: "shippingbox.fill") }
                Button { confirm = .respring } label: { Label("Restart LumaShell", systemImage: "arrow.clockwise") }
                Button { confirm = .userspace } label: { Label("Reboot Userspace", systemImage: "power") }
                Button { confirm = safeMode ? .normal : .safeMode } label: { Label(safeMode ? "Exit Safe Mode" : "Enter Safe Mode", systemImage: "exclamationmark.shield") }
                Toggle("Restart sounds", isOn: $effects)
            }
            Section("Player guide") {
                Button { showGuide = true } label: { Label("Welcome to Last Seen", systemImage: "book.closed") }
                Text("Updated guide: package queues, discovered sources, Safe Mode, local services, Relay Support, VEIL and Game Saves.").font(.caption).foregroundColor(.secondary)
            }
            Section("About") {
                Text("Patchline is part of the fictional Last Seen phone. Maintenance actions never restart or modify your actual device.").font(.footnote).foregroundColor(.secondary)
            }
        }.navigationTitle("Patchline").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Restart the phone environment?", isPresented: Binding(get: { confirm != nil }, set: { if !$0 { confirm = nil } }), titleVisibility: .visible, presenting: confirm) { action in
                Button("Continue") {if phase == .active && restart == nil {restart=action};confirm=nil}
                Button("Cancel", role: .cancel) { confirm = nil }
            } message: { _ in Text("Your records and installed packages will be retained.") }
            .sheet(isPresented: $showGuide) {
                WelcomeBriefingView(revisiting: true, onContinue: { showGuide = false })
            }
            .fullScreenCover(item: $restart) { kind in
                if kind == .userspace {
                    RelayUserspaceView { restart = nil; onRestart() }
                } else {
                    ThemeRespringView {
                        if kind == .safeMode { safeMode = true }
                        if kind == .normal { safeMode = false }
                        OpeningQA.record("Patchline restart completed: " + kind.rawValue)
                        restart = nil; onRestart()
                    }
                }
            }
    }
}
