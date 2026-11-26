import SwiftUI
import Foundation

enum LumaUtility: String, CaseIterable, Identifiable, Codable {
    case pocketclipboard, clipglass, quickpulse, lumaplus, afterglowstudio, rootexplorer, pulseterminal, powerdeck, tweakhub
    var id: String { rawValue }
    var flag: String { "patchline.utility." + rawValue + ".verified" }
    var title: String {
        switch self {
        case .pocketclipboard: return "Pocket Clipboard"
        case .clipglass: return "ClipGlass"
        case .quickpulse: return "QuickPulse"
        case .lumaplus: return "LumaPlus"
        case .afterglowstudio: return "Afterglow Studio"
        case .rootexplorer: return "Root Explorer"
        case .pulseterminal: return "Pulse Terminal"
        case .powerdeck: return "PowerDeck"
        case .tweakhub: return "TweakHub"
        }
    }
    var art: String {
        switch self {
        case .pocketclipboard: return "Jailbreak_PocketClipboard"
        case .clipglass: return "Jailbreak_ClipGlass"
        case .quickpulse: return "Jailbreak_QuickPulse"
        case .lumaplus: return "Jailbreak_LumaPlus"
        case .afterglowstudio: return "Jailbreak_AfterglowStudio"
        case .rootexplorer: return "Jailbreak_RootExplorer"
        case .pulseterminal: return "Jailbreak_PulseTerminal"
        case .powerdeck: return "Jailbreak_PowerDeck"
        case .tweakhub: return "Jailbreak_TweakHub"
        }
    }
    var detail: String {
        switch self {
        case .pocketclipboard: return "Capture selected public text locally."
        case .clipglass: return "Pin a selected record above the phone."
        case .quickpulse: return "Add shortcuts to Control Center."
        case .lumaplus: return "Customize the launcher layout."
        case .afterglowstudio: return "Preview and apply local themes."
        case .rootexplorer: return "Browse the public restored file catalog."
        case .pulseterminal: return "Run invented, local diagnostic commands."
        case .powerdeck: return "Access safe restart and maintenance controls."
        case .tweakhub: return "Review installed packages and service certifications."
        }
    }
    var challenge: (String, [String], String) {
        switch self {
        case .pocketclipboard: return ("Choose the local-only storage route.", ["Network sync","Local journal","Shared account"], "Local journal")
        case .clipglass: return ("Choose what a capture should contain.", ["Selected record","Entire protected archive","All device data"], "Selected record")
        case .quickpulse: return ("A shortcut should open which service?", ["An unavailable package","An active service","A remote account"], "An active service")
        case .lumaplus: return ("Preserve readability when changing layout.", ["Hide every label","Use readable spacing","Overlap controls"], "Use readable spacing")
        case .afterglowstudio: return ("Keep the original appearance recoverable.", ["Overwrite defaults","Save a reversible preset","Remove the original art"], "Save a reversible preset")
        case .rootexplorer: return ("A protected record is not available. Choose the allowed action.", ["Bypass its gate","Read hidden metadata","Leave it protected"], "Leave it protected")
        case .pulseterminal: return ("Choose the read-only diagnostic action.", ["Check local status","Execute a remote script","Erase a folder"], "Check local status")
        case .powerdeck: return ("Restart the interface without deleting records.", ["Erase storage","Restart LumaShell","Remove the backup"], "Restart LumaShell")
        case .tweakhub: return ("A package is essential. Choose the safe action.", ["Remove bootstrap","Keep essential services","Disable all recovery"], "Keep essential services")
        }
    }
    var correct: String { challenge.2 }
    static func next(in flags: Set<String>) -> LumaUtility? {
        guard RecoveryCircuit.unlocked(flags) else { return nil }
        return allCases.first { !flags.contains($0.flag) }
    }
}
struct LumaSnippet: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let source: String
    let text: String
}
enum LumaRecords {
    static func publicRecords(_ state: PhoneWorld) -> [LumaSnippet] {
        var values: [LumaSnippet] = []
        for person in Neighbor.visible(in: state) {
            for message in state.threads[person.id] ?? [] where message.read || message.fromPlayer {
                values.append(LumaSnippet(id:"message:"+message.id,title:person.name,source:"Messages",text:message.text))
            }
        }
        for (title,body) in PhonePublicFiles.available(in: state).sorted(by: { $0.key < $1.key }) {
            values.append(LumaSnippet(id:"file:"+title,title:title,source:"Files",text:body))
        }
        // Do not index protected notes or images. Only explicit public selections.
        return values
    }
    static func visibleSaved(_ state: PhoneWorld) -> [LumaSnippet] {
        let current = publicRecords(state)
        return (state.utilitySnippets ?? []).filter { current.contains($0) }
    }
}
struct UtilityNoticeCard: View {
    let tool: LumaUtility
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(tool.art).resizable().scaledToFit().frame(width:45,height:45).clipShape(RoundedRectangle(cornerRadius:10))
            VStack(alignment:.leading,spacing:4) {
                Text("RELAY · SERVICE CERTIFIED").font(.caption2.bold()).foregroundColor(LumaDesign.accent)
                Text(tool.title).font(.headline)
                Text("Package access earned. Available in Relay.").font(.subheadline).foregroundColor(.secondary)
            }
            Spacer(minLength:0)
        }.padding(14).lumaSurface(radius:18)
    }
}
struct UtilityProgressView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var installed = ""
    @AppStorage("lastseen.relay.safeMode") private var safeMode = false
    let openRelay: () -> Void
    let onRestart: () -> Void
    @State private var feedback = ""
    private var active: [LumaUtility] {
        LumaUtility.allCases.filter { !safeMode && world.state.flags.contains($0.flag) && RelayCatalog.ids(installed).contains($0.rawValue) }
    }
    var body: some View {
        List {
            Section("Service certification") {
                if let next = LumaUtility.next(in: world.state.flags) {
                    Text(next.challenge.0).font(.headline)
                    ForEach(next.challenge.1,id:\.self) { answer in
                        Button(answer) { feedback = world.earnUtility(next,answer:answer) ? "Service verified. Relay updated." : "Configuration rejected. Try again." }
                    }
                } else if RecoveryCircuit.unlocked(world.state.flags) { Label("All local services certified",systemImage:"checkmark.seal.fill") }
                else { Text("Complete Recovery Circuit to begin.").foregroundColor(.secondary) }
                if !feedback.isEmpty { Text(feedback).font(.caption).foregroundColor(.secondary) }
                Button("Open Relay",action:openRelay)
            }
            Section("Installed utilities") {
                if active.isEmpty { Text(safeMode ? "Utilities paused in Safe Mode." : "Install certified packages in Relay.").foregroundColor(.secondary) }
                ForEach(active) { tool in
                    NavigationLink { UtilityDetailView(tool:tool,openRelay:openRelay,onRestart:onRestart) } label: {
                        HStack(spacing:12) {
                            Image(tool.art).resizable().scaledToFit().frame(width:48,height:48).clipShape(RoundedRectangle(cornerRadius:12))
                            VStack(alignment:.leading) { Text(tool.title).font(.headline); Text(tool.detail).font(.caption).foregroundColor(.secondary) }
                        }.padding(.vertical,4)
                    }
                }
            }
            Section("Service records") {
                ForEach(LumaUtility.allCases.filter { world.state.flags.contains($0.flag) }) { tool in
                    Label(tool.title + " · Verified",systemImage:"checkmark.seal")
                }
            }
        }.navigationTitle("Local services").scrollContentBackground(.hidden).background(LumaDesign.background)
    }
}
private struct UtilityDetailView: View {
    let tool: LumaUtility
    let openRelay: () -> Void
    let onRestart: () -> Void
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var installed = ""
    @AppStorage("lastseen.relay.safeMode") private var safeMode = false
    @AppStorage("lastseen.utility.small") private var small = false
    @AppStorage("lastseen.utility.five") private var five = false
    @AppStorage("lastseen.utility.labels") private var labels = true
    @AppStorage("lastseen.utility.glass") private var glass = true
    @AppStorage("lastseen.utility.theme") private var theme = false
    @AppStorage("lastseen.utility.shortcuts") private var shortcuts = true
    @State private var query = ""
    @FocusState private var searchFocused:Bool
    @State private var selected: LumaSnippet?
    @State private var output = "Ready."
    @State private var restart: RelayRestart?
    @State private var confirmation: RelayRestart?
    private var enabled: Bool { !safeMode && world.state.flags.contains(tool.flag) && RelayCatalog.ids(installed).contains(tool.rawValue) }
    private var notesEnabled: Bool { !safeMode && RecoveryCircuit.unlocked(world.state.flags) && RelayCatalog.ids(installed).contains("fieldnotes") }
    private var saved: [LumaSnippet] { LumaRecords.visibleSaved(world.state) }
    var body: some View {
        List {
            Section {
                HStack(spacing:14) {
                    Image(tool.art).resizable().scaledToFit().frame(width:64,height:64).clipShape(RoundedRectangle(cornerRadius:15))
                    VStack(alignment:.leading) { Text(tool.title).font(.title2.bold()); Text(tool.detail).font(.caption).foregroundColor(.secondary) }
                }
            }
            if !enabled { Text("Package unavailable.").foregroundColor(.secondary) }
            else {
                switch tool {
                case .pocketclipboard,.clipglass:
                    Section("Saved selections") {
                        if saved.isEmpty { Text("Select a record below to begin.").foregroundColor(.secondary) }
                        ForEach(saved) { record in
                            Button { selected = record } label: { VStack(alignment:.leading) { Text(record.title); Text(record.source).font(.caption).foregroundColor(.secondary) } }
                            .swipeActions { Button("Delete",role:.destructive) { world.removeSnippet(record.id) } }
                        }
                        if tool == .clipglass { Button("Clear floating clip") { world.pinSnippet(nil) } }
                    }
                    Section("Choose a public record") {
                        TextField("Filter records",text:$query).focused($searchFocused).submitLabel(.search).onSubmit{searchFocused=false}
                        if LumaRecords.publicRecords(world.state).filter({query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.source.localizedCaseInsensitiveContains(query)}).isEmpty {
                            Text("No matching public records.").foregroundColor(.secondary)
                        }
                        ForEach(LumaRecords.publicRecords(world.state).filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.source.localizedCaseInsensitiveContains(query) }) { record in
                            Button { selected = record } label: { VStack(alignment:.leading) { Text(record.title); Text(record.source).font(.caption).foregroundColor(.secondary) } }
                        }
                    }
                case .quickpulse:
                    Toggle("Control Center shortcuts",isOn:$shortcuts)
                    Text("Shortcuts appear in Control Center when their services are active.").foregroundColor(.secondary)
                case .lumaplus:
                    Toggle("Compact icons",isOn:$small)
                    Toggle("Five columns",isOn:$five)
                    Toggle("Show icon labels",isOn:$labels)
                    Toggle("Dock material",isOn:$glass)
                case .afterglowstudio:
                    Section("Afterglow Glass") {
                        HStack { ForEach(Array(ApprovedArt.theme.prefix(4)),id:\.self) { name in OpeningArt(name:name,size:44) } }
                        Toggle("Use Afterglow appearance",isOn:$theme)
                        Text("Turn off to restore the stock appearance unless an earlier theme package is enabled.").font(.caption).foregroundColor(.secondary)
                    }
                case .rootexplorer:
                    Section("On this phone") {
                        TextField("Search documents",text:$query).focused($searchFocused).submitLabel(.search).onSubmit{searchFocused=false}
                        if PhonePublicFiles.available(in:world.state).keys.filter({query.isEmpty || $0.localizedCaseInsensitiveContains(query)}).isEmpty {
                            Text("No matching available documents.").foregroundColor(.secondary)
                        }
                        ForEach(PhonePublicFiles.available(in:world.state).keys.sorted().filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) },id:\.self) { name in
                            NavigationLink { PhoneDocumentView(title:name) } label: { Label(name,systemImage:"doc.text") }
                        }
                    }
                    Section("Protection") { Label("Private records remain protected",systemImage:"lock.shield") }
                case .pulseterminal:
                    Section("Local diagnostic console") {
                        Text(output).font(.system(.body,design:.monospaced)).textSelection(.enabled)
                        ForEach(["status","packages","verify","clear"],id:\.self) { command in
                            Button(command) {
                                switch command {
                                case "status": output = "LumaShell online\nLocal environment ready"
                                case "packages": output = RelayCatalog.ids(installed).sorted().joined(separator:"\n")
                                case "verify": output = "Verified services: \(LumaUtility.allCases.filter { world.state.flags.contains($0.flag) }.count)"
                                default: output = "Ready."
                                }
                            }
                        }
                    }
                case .powerdeck:
                    Section("Maintenance") {
                        Button("Restart LumaShell") { confirmation = .respring }
                        Button("Reboot userspace") { confirmation = .userspace }
                        Button("Enter Safe Mode") { confirmation = .safeMode }
                    }
                case .tweakhub:
                    Section("Installed packages") {
                        ForEach(RelayCatalog.packages.filter { RelayCatalog.installed($0.id,userIDs:RelayCatalog.ids(installed)) }) { package in
                            VStack(alignment:.leading) { Text(package.title); Text(package.essential ? "Essential" : package.version).font(.caption).foregroundColor(.secondary) }
                        }
                        Button("Manage in Relay",action:openRelay)
                    }
                }
            }
            if !output.isEmpty && tool != .pulseterminal { Text(output).font(.caption).foregroundColor(.secondary) }
        }.navigationTitle(tool.title).scrollContentBackground(.hidden).background(LumaDesign.background)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {ToolbarItemGroup(placement:.keyboard){Spacer();Button("Done"){searchFocused=false}}}
            .onChange(of:world.checkpointEpoch){_ in searchFocused=false;query="";selected=nil;confirmation=nil;restart=nil}
            .onChange(of:enabled){if !$0 {searchFocused=false;selected=nil;confirmation=nil}}
            .sheet(item:$selected) { record in
                NavigationStack {
                    ScrollView { VStack(alignment:.leading,spacing:16) {
                        Text(record.title).font(.title2.bold())
                        Text(record.source).font(.caption).foregroundColor(.secondary)
                        Text(record.text).textSelection(.enabled)
                        if enabled {
                            Button("Keep in local clipboard") { world.storeSnippet(record); output = "Selection saved."; selected = nil }.buttonStyle(.borderedProminent)
                            if tool == .clipglass {
                                Button("Pin above phone") { world.storeSnippet(record); world.pinSnippet(record.id); selected = nil }.buttonStyle(.bordered)
                            }
                            if notesEnabled {
                                Button("Add to Field Notes") {
                                    var entry = FieldEntry(); entry.title = record.title; entry.source = record.source; entry.text = record.text
                                    let book = FieldNotebook()
                                    output = book.put(entry) ? "Added to Field Notes." : book.error; selected = nil
                                }.buttonStyle(.bordered)
                            }
                        }
                    }.frame(maxWidth:.infinity,alignment:.leading).padding(20) }.navigationTitle("Selected record").toolbar { ToolbarItem(placement:.cancellationAction) { Button("Done") { selected = nil } } }
                }
            }
            .confirmationDialog("Restart the phone environment?",isPresented:Binding(get:{ confirmation != nil },set:{ if !$0 { confirmation = nil } }),titleVisibility:.visible,presenting:confirmation) { kind in
                Button("Continue") { restart = kind; confirmation = nil }
                Button("Cancel",role:.cancel) { confirmation = nil }
            }
            .fullScreenCover(item:$restart) { kind in
                if kind == .userspace { RelayUserspaceView { restart = nil; onRestart() } }
                else { ThemeRespringView { if kind == .safeMode { safeMode = true }; restart = nil; onRestart() } }
            }
    }
}
