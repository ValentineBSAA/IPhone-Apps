import SwiftUI

enum PatchlinePackageHealth: String {
    case essential = "Essential"
    case active = "Active"
    case safeMode = "Paused in Safe Mode"
    case unavailable = "Unavailable in this archive"
    case conflict = "Conflict"
    case missingRequirement = "Missing requirement"
    static func status(_ p: RelayPackage, installed: Set<String>, flags: Set<String>, safeMode: Bool) -> Self {
        if p.essential { return .essential }
        if !RelayCatalog.available(p.id, flags: flags) { return .unavailable }
        let effective = installed.union(RelayCatalog.packages.filter(\.essential).map(\.id))
        if !RelayCatalog.requirements(p.id).isSubset(of: effective) { return .missingRequirement }
        if !RelayCatalog.conflicts(p.id).isDisjoint(with: installed) { return .conflict }
        return safeMode && p.id != "relay-support" ? .safeMode : .active
    }
}

struct PatchlineLoaderDiagnostics: View {
    let flags: Set<String>
    @AppStorage("lastseen.relay.installed") private var installed = ""
    @AppStorage("lastseen.relay.versions") private var versions = ""
    @AppStorage("lastseen.relay.sources") private var sources = RelayCatalog.defaultSources
    @AppStorage("lastseen.relay.safeMode") private var safeMode = false
    private var ids: Set<String> { RelayCatalog.ids(installed) }
    private var enabled: Set<String> { RelayCatalog.ids(RelayCatalog.recoveredSources(sources, flags: flags)) }
    private var packages: [RelayPackage] { RelayCatalog.packages.filter { RelayCatalog.installed($0.id, userIDs: ids) } }
    private func health(_ p: RelayPackage) -> PatchlinePackageHealth {
        .status(p, installed: ids, flags: flags, safeMode: safeMode)
    }
    var body: some View {
        List {
            Section("Loader status") {
                LabeledContent("Active optional packages", value: String(packages.filter { health($0) == .active }.count))
                LabeledContent("Paused or unavailable", value: String(packages.filter { !$0.essential && health($0) != .active }.count))
                LabeledContent("Unknown installed entries", value: String(ids.filter { RelayCatalog.package($0) == nil }.count))
                Text("This diagnostic reads the simulated package database. It does not scan or modify the real device.").font(.caption).foregroundColor(.secondary)
            }
            Section("Installed components") {
                ForEach(packages) { p in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(p.title).font(.headline)
                            Spacer()
                            Text(health(p).rawValue).font(.caption).foregroundColor(health(p) == .active || health(p) == .essential ? .teal : .orange)
                        }
                        Text(RelayCatalog.installedVersion(p, versions: RelayCatalog.versions(versions))).font(.caption.monospaced())
                        if !p.essential && !enabled.contains(p.source) {
                            Label("Source not enabled · removal remains available", systemImage: "exclamationmark.circle").font(.caption).foregroundColor(.secondary)
                        }
                    }.padding(.vertical, 4)
                }
            }
        }.navigationTitle("Loader diagnostics")
    }
}
