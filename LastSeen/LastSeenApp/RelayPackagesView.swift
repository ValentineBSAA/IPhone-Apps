import SwiftUI

/// Cydia-inspired local package manager. All sources and transactions are bundled game data.
struct RelayPackagesView: View {
    @AppStorage("lastseen.relay.installed") private var installed = ""
    @AppStorage("lastseen.relay.versions") private var versions = ""
    @AppStorage("lastseen.relay.sources") private var sources = RelayCatalog.defaultSources
    @AppStorage("lastseen.relay.history") private var history = ""
    @AppStorage("lastseen.relay.wishlist") private var wishlist = ""
    @AppStorage("lastseen.relay.lastRefresh") private var lastRefresh = 0.0
    @AppStorage("lastseen.relay.safeMode") private var safeMode = false
    @AppStorage("lastseen.lab.wallpaper") private var wallpaper = 0
    @AppStorage("lastseen.relay.compactIcons") private var compactIcons = false
    @AppStorage("lastseen.relay.tealTheme") private var tealTheme = false
    @State private var tab: Tab = .featured
    @State private var query = ""
    @State private var queue: [RelayChange] = []
    @State private var selected: RelayPackage?
    @State private var showQueue = false
    @State private var showSources = false
    @State private var sourceAddress = ""
    @State private var sourceFeedback = ""
    @State private var category = "All"
    @State private var showTransaction = false
    @State private var confirmed: [RelayChange] = []
    @State private var restart: RelayRestart?
    @State private var notice = ""
    @State private var refresh = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onRestart: () -> Void
    let earnedFlags: Set<String>
    init(earnedFlags: Set<String> = [], onRestart: @escaping () -> Void = {}) { self.earnedFlags = earnedFlags; self.onRestart = onRestart }

    private enum Tab: String, CaseIterable {
        case featured = "Relay", sources = "Sources", changes = "Changes", installed = "Installed", search = "Search"
        var icon: String {
            switch self {
            case .featured: return "shippingbox.fill"
            case .sources: return "square.stack.3d.up"
            case .changes: return "clock.arrow.circlepath"
            case .installed: return "checkmark.circle"
            case .search: return "magnifyingglass"
            }
        }
    }
    private var ids: Set<String> { RelayCatalog.ids(installed) }
    private var sourceIDs: Set<String> { RelayCatalog.ids(RelayCatalog.recoveredSources(sources,flags:earnedFlags)) }
    private var versionMap: [String: String] { RelayCatalog.versions(versions) }
    private var visiblePackages: [RelayPackage] { RelayCatalog.packages.filter { RelayCatalog.visible($0, sources: sourceIDs, installed: ids, flags: earnedFlags) } }
    private var updates: [RelayPackage] { visiblePackages.filter { !$0.essential && ids.contains($0.id) && sourceIDs.contains($0.source) && RelayCatalog.available($0.id, flags: earnedFlags) && RelayCatalog.installedVersion($0, versions: versionMap) != $0.version } }
    private var queueProblems: [String] { RelayPlan.problems(queue, sources: sourceIDs, installed: ids, flags: earnedFlags, versions: versionMap) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 10) {
                    OpeningArt(name: "Jailbreak_Relay", size: 42)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Relay").font(.title2.bold())
                        Label(safeMode ? "Safe Mode" : "Rootless • Ready", systemImage: safeMode ? "exclamationmark.shield" : "checkmark.seal.fill")
                            .font(.caption).foregroundColor(safeMode ? .orange : .teal)
                    }
                }
                Spacer()
                Button { showQueue = true } label: {
                    Label("Queue (\(queue.count))", systemImage: "tray.full")
                        .font(.subheadline.weight(.semibold))
                }.buttonStyle(.bordered).accessibilityIdentifier("relay.queue")
            }.padding(.horizontal, 16).padding(.vertical, 9)
            if !notice.isEmpty {
                Text(notice).font(.caption).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).padding(.bottom, 6)
            }
            Divider()
            Group {
                switch tab {
                case .featured: featured
                case .sources: sourcePage
                case .changes: changesPage
                case .installed: installedPage
                case .search: searchPage
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { item in
                    Button {
                        tab = item
                    } label: {
                        VStack(spacing: 4) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: item.icon).font(.system(size: 21, weight: .medium)).frame(width: 30, height: 27)
                                if item == .changes && !updates.isEmpty {
                                    Text("\(updates.count)").font(.system(size: 9, weight: .bold)).padding(3).background(.red, in: Capsule()).foregroundColor(.white).offset(x: 6, y: -3)
                                }
                            }
                            Text(item == .featured ? "Discover" : item.rawValue).font(.system(size: 10, weight: .medium))
                        }.frame(maxWidth: .infinity).frame(minHeight: 49)
                            .foregroundColor(tab == item ? .teal : .secondary)
                    }.buttonStyle(.plain).accessibilityAddTraits(tab == item ? .isSelected : []).accessibilityIdentifier("relay.tab." + item.rawValue)
                }
            }.padding(.horizontal, 5).background(.ultraThinMaterial)
        }
        .navigationTitle("Relay").navigationBarTitleDisplayMode(.inline)
        .onAppear { recoverSources() }
        .onChange(of: sources) { _ in recoverSources() }
        .sheet(item: $selected) { p in
            NavigationStack { detail(p).navigationTitle(p.title).navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { selected = nil } } } }
        }
        .sheet(isPresented: $showSources) {
            NavigationStack {
                Form {
                    Section("Repository address") {
                        TextField("Enter a discovered address",text:$sourceAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                        if let source=RelayCatalog.sourceForAddress(sourceAddress,flags:earnedFlags),!sourceIDs.contains(source.id) {
                            sourceRow(source)
                            Button("Add repository") {
                                sources=RelayCatalog.encoded(sourceIDs.union([source.id]))
                                notice="Repository added"; sourceAddress=""; sourceFeedback=""; showSources=false
                            }
                        } else {
                            Button("Check address") {
                                sourceFeedback = RelayCatalog.sourceForAddress(sourceAddress,flags:earnedFlags).map { sourceIDs.contains($0.id) ? "Already added." : "Ready to add." } ?? "This local repository is not available. Check the address and your discoveries."
                            }.disabled(sourceAddress.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                        }
                        if !sourceFeedback.isEmpty {Text(sourceFeedback).font(.caption).foregroundColor(.secondary)}
                    }
                    Section {Text("Use an address you have found in LumaOS. Relay reads bundled indexes and never contacts an external server.").font(.footnote).foregroundColor(.secondary)}
                }.navigationTitle("Add Source").toolbar{ToolbarItem(placement:.cancellationAction){Button("Cancel"){showSources=false}}}
            }
        }
        .sheet(isPresented: $showQueue, onDismiss: {
            if !confirmed.isEmpty { showTransaction = true }
        }) {
            NavigationStack {
                List {
                    if queue.isEmpty { Text("Your queue is empty.").foregroundColor(.secondary) }
                    ForEach(queue) { change in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(change.package.title).font(.headline)
                                Text(change.action.rawValue + " • " + change.package.version).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) { queue.removeAll { $0.id == change.id } } label: { Image(systemName: "minus.circle.fill") }.buttonStyle(.borderless).accessibilityLabel("Remove from queue")
                        }
                    }
                    if !queue.isEmpty {
                        if !queueProblems.isEmpty {
                            Section("Resolve before continuing") {
                                ForEach(Array(queueProblems.enumerated()), id: \.offset) { problem in
                                    Label(problem.element, systemImage: "exclamationmark.triangle").font(.subheadline).foregroundColor(.orange)
                                }
                            }
                        }
                        Section {
                            Button("Confirm \(queue.count) changes") {
                                guard queueProblems.isEmpty else { notice = "Queue no longer valid"; return }
                                confirmed = queue; showQueue = false
                            }.disabled(!queueProblems.isEmpty).accessibilityIdentifier("relay.queue.confirm")
                            Button("Clear queue", role: .destructive) { queue.removeAll() }
                        } footer: { Text("Changes apply together after LumaShell restarts.") }
                    }
                }.navigationTitle("Queue").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { showQueue = false } } }
            }
        }
        .fullScreenCover(isPresented: $showTransaction) {
            RelayTransactionView(changes: confirmed, onCancel: {
                confirmed = []; showTransaction = false
            }, onComplete: {
                let committed = applyConfirmed()
                showTransaction = false
                if committed { onRestart() }
            })
        }
        .fullScreenCover(item: $restart) { kind in
            if kind == .userspace {
                RelayUserspaceView {
                    restart = nil; onRestart()
                }
            } else {
                ThemeRespringView {
                    if kind == .safeMode { safeMode = true }
                    if kind == .normal { safeMode = false }
                    OpeningQA.record("Relay restart completed: " + kind.rawValue)
                    restart = nil; onRestart()
                }
            }
        }
    }
    private var featured: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Discover").font(.largeTitle.bold())
                    Text("Make LumaOS yours.").font(.title3.weight(.semibold))
                    Text("\(visiblePackages.filter { !$0.essential && RelayCatalog.available($0.id, flags: earnedFlags) && sourceIDs.contains($0.source) }.count) available · \(ids.count) installed").font(.subheadline).foregroundColor(.secondary)
                    HStack {
                        Label("\(updates.count) updates", systemImage: "arrow.down.circle")
                        Spacer()
                        Label("\(sourceIDs.count) sources", systemImage: "square.stack.3d.up")
                    }.font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 9) {
                        ForEach(Array(ApprovedArt.theme.prefix(5)), id: \.self) { name in OpeningArt(name: name, size: 42) }
                    }
                }.padding(.vertical, 8)
                if let p = RelayCatalog.package("teal"), visiblePackages.contains(p) { packageRow(p) }
            }
            Section("Saved packages") {
                let saved = visiblePackages.filter { RelayCatalog.ids(wishlist).contains($0.id) }
                if saved.isEmpty { Text("Save packages from their details to find them here.").font(.caption).foregroundColor(.secondary) }
                ForEach(saved) { packageRow($0) }
            }
            Section("Browse packages") {
                Picker("Category",selection:$category) { ForEach(["All"]+Array(Set(visiblePackages.filter{!$0.essential}.map(\.category))).sorted(),id:\.self){Text($0).tag($0)} }
                ForEach(visiblePackages.filter { !$0.essential && $0.id != "teal" && (category=="All" || $0.category==category) }) { packageRow($0) }
            }
            Section("System tools") {
                Button { restart = .respring } label: { Label("Restart LumaShell", systemImage: "arrow.clockwise") }
                Button { restart = .userspace } label: { Label("Reboot Userspace", systemImage: "power") }
                Button { restart = safeMode ? .normal : .safeMode } label: { Label(safeMode ? "Exit Safe Mode" : "Enter Safe Mode", systemImage: "exclamationmark.shield") }
                if safeMode { Text("Tweaks are disabled until Safe Mode is exited. Installed packages are kept.").font(.caption).foregroundColor(.secondary) }
            }
            Section("About") {
                Text("Relay and its packages are part of Last Seen. All changes affect the in-game phone only.").font(.footnote).foregroundColor(.secondary)
            }
        }.listStyle(.insetGrouped)
    }
    private var sourcePage: some View {
        List {
            Section {
                Button { showSources = true } label: { Label("Add Source", systemImage: "plus.circle") }
                Button {
                    recoverSources()
                    refresh = true
                    lastRefresh = Date().timeIntervalSince1970
                    notice = "All local package indexes are up to date"
                    OpeningQA.record("Relay source refresh")
                } label: { Label("Refresh Sources", systemImage: "arrow.clockwise") }
                Button {
                    recoverSources(); notice = "Baseline sources restored"
                } label: { Label("Restore All Sources", systemImage: "arrow.counterclockwise.circle") }
            }
            Section("Sources") {
                ForEach(RelayCatalog.sources.filter { sourceIDs.contains($0.id) }) { source in
                    VStack(alignment: .leading, spacing: 7) {
                        NavigationLink {
                            List {
                                Section { sourceRow(source) }
                                Section("Available packages") {
                                    ForEach(visiblePackages.filter { $0.source == source.id }) { packageRow($0) }
                                }
                            }.navigationTitle(source.name)
                        } label: { sourceRow(source) }
                        Text("\(visiblePackages.filter { $0.source == source.id }.count) packages").font(.caption).foregroundColor(.secondary)
                        if RelayCatalog.requiredSourceIDs.contains(source.id) { Label("Baseline source",systemImage:"lock.shield").font(.caption).foregroundColor(.secondary) }
                        else { Button("Remove source",role:.destructive){sources=RelayCatalog.encoded(sourceIDs.subtracting([source.id]));notice="Repository removed. Installed packages kept."}.font(.caption) }
                    }.padding(.vertical, 4)
                }
            }
            if lastRefresh > 0 { Section { LabeledContent("Last local refresh") { Text(Date(timeIntervalSince1970: lastRefresh), style: .relative) } } }
        }.listStyle(.insetGrouped)
    }
    private var changesPage: some View {
        List {
            Section("Available upgrades") {
                if updates.isEmpty { Text("All installed packages are up to date.").foregroundColor(.secondary) }
                else {
                    Button("Queue all upgrades") {
                        for p in updates { enqueue(p, .upgrade) }
                    }
                    ForEach(updates) { packageRow($0) }
                }
            }
            Section("Recent additions") {
                ForEach(visiblePackages.filter { !$0.essential }.reversed()) { packageRow($0) }
            }
            Section("Transaction history") {
                let entries = history.split(separator: "\n").map(String.init)
                if entries.isEmpty { Text("No changes yet.").foregroundColor(.secondary) }
                ForEach(Array(entries.enumerated()), id: \.offset) { entry in Text(entry.element).font(.caption.monospaced()) }
            }
        }.listStyle(.insetGrouped)
    }
    private var installedPage: some View {
        List {
            Section("User packages") {
                let user = visiblePackages.filter { !$0.essential && ids.contains($0.id) }
                if user.isEmpty { Text("No tweaks installed yet.").foregroundColor(.secondary) }
                ForEach(user) { packageRow($0) }
            }
            Section("Essential packages") {
                ForEach(RelayCatalog.packages.filter(\.essential)) { packageRow($0) }
            }
        }.listStyle(.insetGrouped)
    }
    private var searchPage: some View {
        List {
            Section {
                TextField("Search packages, sources or categories", text: $query).autocorrectionDisabled()
            }
            Section("Packages") {
                let results = visiblePackages.filter { p in
                    query.isEmpty || [p.title, p.id, p.category, p.summary, RelayCatalog.source(p.source)?.name ?? ""].contains { $0.localizedCaseInsensitiveContains(query) }
                }
                if results.isEmpty { Text("No packages found.").foregroundColor(.secondary) }
                ForEach(results) { packageRow($0) }
            }
        }.listStyle(.insetGrouped)
    }
    private func sourceRow(_ source: RelaySource) -> some View {
        HStack(spacing: 12) {
            Image(systemName: source.icon).font(.title2).foregroundColor(.teal).frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name).font(.headline)
                Text(source.address).font(.caption).foregroundColor(.secondary)
                Text(source.description).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            if source.essential { Image(systemName: "lock.fill").font(.caption).foregroundColor(.secondary) }
        }
    }
    private func packageRow(_ p: RelayPackage) -> some View {
        Button { selected = p } label: {
            HStack(spacing: 12) {
                packageIcon(p)
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.title).font(.headline).foregroundColor(.primary)
                    Text(p.summary).font(.caption).foregroundColor(.secondary)
                    Text(p.category + " • " + p.version).font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                if let change = queue.first(where: { $0.id == p.id }) { Text(change.action.rawValue).font(.caption).foregroundColor(.teal) }
                else if RelayCatalog.installed(p.id, userIDs: ids) { Image(systemName: "checkmark.circle.fill").foregroundColor(.teal) }
                Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
            }.padding(.vertical, 4)
        }.buttonStyle(.plain).accessibilityIdentifier("relay.package." + p.id)
    }
    @ViewBuilder private func packageIcon(_ p: RelayPackage) -> some View {
        if let tool = LumaUtility(rawValue: p.id) { OpeningArt(name: tool.art, size: 43) }
        else if p.id == "fieldnotes" { OpeningArt(name: "Jailbreak_FieldNotes", size: 43) }
        else if p.id == "teal" { OpeningArt(name: "Theme_Messages", size: 43) }
        else if p.id == "relay" { OpeningArt(name: "Jailbreak_Relay", size: 43) }
        else if p.id == "bootstrap" || p.id == "loader" { OpeningArt(name: "Jailbreak_Patchline", size: 43) }
        else {
            Image(systemName: p.icon).font(.title2).foregroundColor(.teal).frame(width: 43, height: 43)
                .background(.teal.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    private func detail(_ p: RelayPackage) -> some View {
        List {
            Section {
                HStack(spacing: 13) {
                    packageIcon(p)
                    VStack(alignment: .leading, spacing: 4) { Text(p.title).font(.title3.bold()); Text(p.summary).font(.subheadline).foregroundColor(.secondary) }
                }
                Text(p.detail)
                if !p.essential {
                    Button {
                        var saved = RelayCatalog.ids(wishlist)
                        if !saved.insert(p.id).inserted { saved.remove(p.id) }
                        wishlist = RelayCatalog.encoded(saved)
                    } label: { Label(RelayCatalog.ids(wishlist).contains(p.id) ? "Remove from saved" : "Save package", systemImage: RelayCatalog.ids(wishlist).contains(p.id) ? "bookmark.fill" : "bookmark") }
                }
                if p.id == "teal" {
                    HStack(spacing: 8) { ForEach(Array(ApprovedArt.theme.prefix(5)), id: \.self) { OpeningArt(name: $0, size: 36) } }
                }
                if p.essential { Label("Essential system package", systemImage: "lock.shield").foregroundColor(.secondary) }
                else if ids.contains(p.id) {
                    if updates.contains(p) { Button("Queue Upgrade") { enqueue(p, .upgrade); selected = nil } }
                    Button("Queue Removal", role: .destructive) { enqueue(p, .remove); selected = nil }
                } else { Button("Queue Install") { enqueue(p, .install); selected = nil }.disabled(!sourceIDs.contains(p.source) || !RelayCatalog.available(p.id, flags: earnedFlags)) }
            }
            Section("Package information") {
                LabeledContent("Version", value: p.version)
                if RelayCatalog.installed(p.id, userIDs: ids) { LabeledContent("Installed", value: RelayCatalog.installedVersion(p, versions: versionMap)) }
                LabeledContent("Source", value: RelayCatalog.source(p.source)?.name ?? p.source)
                LabeledContent("Publisher", value: RelayCatalog.publisher(p))
                LabeledContent("Compatibility", value: "LumaOS · Rootless 2.0")
                LabeledContent("Section", value: p.category)
                LabeledContent("Identifier", value: "com.patchline." + p.id)
                LabeledContent("Price", value: "Free")
                LabeledContent("Environment", value: "Rootless")
                LabeledContent("Restart required", value: p.essential ? "No" : "Respring")
                if RelayCatalog.installed(p.id, userIDs: ids) {
                    LabeledContent("Loader status", value: PatchlinePackageHealth.status(p, installed: ids, flags: earnedFlags, safeMode: safeMode).rawValue)
                }
            }
            Section("Requirements & compatibility") {
                let requirements = RelayCatalog.packages.filter { RelayCatalog.requirements(p.id).contains($0.id) && visiblePackages.contains($0) }
                if requirements.isEmpty { Text("No additional package requirements.").foregroundColor(.secondary) }
                ForEach(requirements) { required in
                    Label(required.title, systemImage: RelayCatalog.installed(required.id, userIDs: ids) ? "checkmark.circle" : "circle")
                }
                let conflicts = visiblePackages.filter { RelayCatalog.conflicts(p.id).contains($0.id) }
                ForEach(conflicts) { conflict in
                    Label("Conflicts with " + conflict.title, systemImage: "exclamationmark.triangle").foregroundColor(.orange)
                }
            }
        }
    }
    private func recoverSources() {
        let restored = RelayCatalog.recoveredSources(sources,flags:earnedFlags)
        if sources != restored {
            sources = restored
            notice = "Missing bundled sources restored"
            OpeningQA.record("Relay bundled sources restored")
        }
    }
    private func enqueue(_ p: RelayPackage, _ action: RelayAction) {
        queue = RelayPlan.queue(RelayChange(package: p, action: action), into: queue)
        notice = "\(p.title) queued for \(action.rawValue.lowercased())"
    }
    @discardableResult private func applyConfirmed() -> Bool {
        guard RelayPlan.valid(confirmed, sources: sourceIDs, installed: ids, flags: earnedFlags, versions: versionMap) else {
            confirmed = []; notice = "Transaction cancelled: package state changed"; return false
        }
        let previous = ids
        let (next, nextVersions) = RelayPlan.applying(confirmed, to: ids, versions: versionMap)
        installed = RelayCatalog.encoded(next)
        versions = RelayCatalog.encodedVersions(nextVersions)
        if !previous.contains("midnight") && next.contains("midnight") { wallpaper = 2 }
        if !next.contains("midnight") && wallpaper == 2 { wallpaper = 0 }
        compactIcons = next.contains("compact")
        tealTheme = next.contains("teal")
        let entries = confirmed.map { $0.action.rawValue + " " + $0.package.title + " " + $0.package.version }
        history = (entries + history.split(separator: "\n").map(String.init)).prefix(40).joined(separator: "\n")
        OpeningQA.record("Relay transaction committed: \(confirmed.count) changes")
        notice = "\(confirmed.count) changes completed"
        queue.removeAll(); confirmed = []
        return true
    }
}

enum RelayRestart: String, Identifiable {
    case respring, userspace, safeMode, normal
    var id: String { rawValue }
}
