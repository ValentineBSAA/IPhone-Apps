import SwiftUI
import Foundation

struct FieldEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var title = ""
    var category = "Observation"
    var source = "Unspecified"
    var text = ""
    var confidence = "Uncertain"
    var status = "Open"
    var pinned = false
    var created = Date()
    var updated = Date()
}
enum FieldNotebookBrowsing {
    static func visible(_ entries:[FieldEntry],query:String="",status:String="All",pinnedOnly:Bool=false)->[FieldEntry] {
        let term=query.trimmingCharacters(in:.whitespacesAndNewlines)
        return entries.filter{entry in
            (status=="All" || status==entry.status) && (!pinnedOnly || entry.pinned) &&
            (term.isEmpty || [entry.title,entry.text,entry.category,entry.source,entry.confidence,entry.status].contains{$0.localizedCaseInsensitiveContains(term)})
        }.sorted{
            if $0.pinned != $1.pinned {return $0.pinned}
            return $0.updated == $1.updated ? $0.id.uuidString < $1.id.uuidString:$0.updated > $1.updated
        }
    }
}
@MainActor final class FieldNotebook: ObservableObject {
    @Published private(set) var entries: [FieldEntry] = []
    @Published private(set) var error = ""
    let url: URL
    private var readable = true
    init(url: URL? = nil) {
        self.url = url ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FieldNotes-v1.json")
        if FileManager.default.fileExists(atPath: self.url.path) {
            do { entries = try JSONDecoder().decode([FieldEntry].self, from: Data(contentsOf: self.url)) }
            catch { readable = false; self.error = "Notebook could not be opened. Existing data is protected." }
        }
    }
    @discardableResult func put(_ entry: FieldEntry) -> Bool {
        guard !entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, entry.text.count <= 10000, entry.title.count <= 200 else { error = "Enter a note of up to 10,000 characters and a short title."; return false }
        var next = entries
        var value = entry; value.updated = Date()
        if let i = next.firstIndex(where: { $0.id == value.id }) { next[i] = value }
        else { guard next.count < 500 else { error = "Notebook is full."; return false }; next.append(value) }
        return persist(next)
    }
    @discardableResult func remove(_ id: UUID) -> Bool { persist(entries.filter { $0.id != id }) }
    private func persist(_ next: [FieldEntry]) -> Bool {
        guard readable else { return false }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(next).write(to: url, options: .atomic)
            entries = next; error = ""; return true
        } catch { self.error = "Could not save notebook. Existing entries were retained."; return false }
    }
}
struct FieldNotesView: View {
    @EnvironmentObject private var world:PhoneWorldStore
    @StateObject private var book = FieldNotebook()
    @State private var search = ""
    @State private var filter = "All"
    @State private var editing: FieldEntry?
    @State private var deleting: FieldEntry?
    @State private var pinnedOnly=false
    @AppStorage("lastseen.relay.installed") private var installed=""
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    @Environment(\.scenePhase) private var phase
    private var available:Bool {RecoveryCircuit.unlocked(world.state.flags) && RelayCatalog.tweakActive("fieldnotes",installed:installed,safeMode:safeMode,flags:world.state.flags)}
    private var term:String {search.trimmingCharacters(in:.whitespacesAndNewlines)}
    private var shown:[FieldEntry] {FieldNotebookBrowsing.visible(book.entries,query:term,status:filter,pinnedOnly:pinnedOnly)}
    var body: some View {
        List {
            if available && phase == .active {
            Section {
                HStack(spacing: 12) {
                    Image("Jailbreak_FieldNotes").resizable().scaledToFit().frame(width: 56,height: 56).clipShape(RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading) {
                        Text("Personal notebook").font(.headline)
                        Text("Separate from restored phone records. Retained when loading a checkpoint.").font(.caption).foregroundColor(.secondary)
                    }
                }
                HStack { Label("\(book.entries.filter { $0.status != "Resolved" }.count) open", systemImage: "questionmark.circle"); Spacer(); Label("\(book.entries.filter { $0.pinned }.count) pinned", systemImage: "pin") }.font(.caption).foregroundColor(.secondary)
                Picker("Status", selection: $filter) { ForEach(["All","Open","Follow up","Resolved"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
                Toggle("Pinned notes only",isOn:$pinnedOnly)
            }
            let connections=EvidenceConnection.visible(world.state).filter{entry in
                term.isEmpty || entry.relation.title.localizedCaseInsensitiveContains(term) ||
                entry.records(in:world.state).contains{$0.title.localizedCaseInsensitiveContains(term)}
            }
            if filter == "All" && !pinnedOnly && LumaAssistantEvidence.visible(world.state).count >= 2 {
                Section("Record connections · current checkpoint") {
                    NavigationLink { EvidenceComparisonView() } label:{
                        Label("Compare discoveries",systemImage:"arrow.left.arrow.right")
                    }
                    ForEach(connections){entry in
                        VStack(alignment:.leading,spacing:5){
                            Text(entry.records(in:world.state).map(\.title).joined(separator:" + ")).font(.headline)
                            Text(entry.relation.title).font(.caption)
                            Text("Working observation · not verified").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }
            if filter == "All" && !pinnedOnly && !RecoveredImageAnalysis.visible(world.state).isEmpty {
                Section("Image investigation · current checkpoint") {
                    NavigationLink { ImageReviewOverviewView() } label:{
                        Label("Review opened images",systemImage:"viewfinder")
                    }
                }
            }
            let findings=ImageInterpretation.recorded(world.state).filter{term.isEmpty || $0.note.localizedCaseInsensitiveContains(term)}
            if filter == "All" && !pinnedOnly && !findings.isEmpty {
                Section("Recovered analysis · current checkpoint") {
                    ForEach(findings){finding in
                        VStack(alignment:.leading,spacing:5){
                            Text("Interpretive observation").font(.headline)
                            Text(finding.note)
                            Text(finding.confidence).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            Section("Your notebook") {
            if shown.isEmpty {Text(term.isEmpty ? "No personal entries in this view":"No matching personal entries").foregroundColor(.secondary)}
            ForEach(shown) { entry in
                Button { editing = entry } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            if entry.pinned { Image(systemName: "pin.fill").foregroundColor(LumaDesign.accent) }
                            Text(entry.title.isEmpty ? entry.category : entry.title).font(.headline)
                            Spacer()
                            Text(entry.updated, style: .date).font(.caption)
                        }
                        Text(entry.text).lineLimit(2).foregroundColor(.secondary)
                        Text(entry.category + " • " + entry.status).font(.caption).foregroundColor(LumaDesign.accent)
                    }.padding(.vertical, 6)
                }.buttonStyle(.plain)
                .swipeActions(allowsFullSwipe:false) {
                    Button(role:.destructive){deleting=entry}label:{Label("Delete",systemImage:"trash")}
                    Button {var e=entry;e.pinned.toggle();_ = book.put(e)}label:{Label(entry.pinned ? "Unpin":"Pin",systemImage:entry.pinned ? "pin.slash":"pin")}.tint(.teal)
                }
            }
            }
            if !book.error.isEmpty {Text(book.error).foregroundColor(.secondary)}
            } else {Text("Notebook unavailable in the current environment.").foregroundColor(.secondary)}
        }.scrollContentBackground(.hidden).background(LumaDesign.background.ignoresSafeArea())
            .navigationTitle("Field Notes").searchable(text: $search, prompt: "Search your notes")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button {editing=FieldEntry()}label:{Image(systemName:"square.and.pencil").accessibilityLabel("New entry")}.disabled(!available || phase != .active) } }
            .onChange(of:available){if !$0 {editing=nil;deleting=nil}}
            .sheet(item:$editing){entry in
                NavigationStack {FieldEntryEditor(entry:entry,book:book,canSave:{available && phase == .active})}
            }
            .confirmationDialog("Delete this entry?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                Button("Delete", role: .destructive) { if available && phase == .active,let e=deleting {_ = book.remove(e.id)}; deleting = nil }
                Button("Cancel", role: .cancel) { deleting = nil }
            }
    }
}
private struct FieldEntryEditor: View {
    @State var entry: FieldEntry
    @ObservedObject var book: FieldNotebook
    @Environment(\.dismiss) private var dismiss
    let canSave:()->Bool
    private enum Focus:Hashable {case title,body}
    @FocusState private var focus:Focus?
    var body: some View {
        Form {
            Section("Entry") {
                TextField("Optional title",text:$entry.title).focused($focus,equals:.title)
                Picker("Category", selection: $entry.category) { ForEach(["Observation","Person","Place","Timeline","Question","Theory","To-do","Other"], id: \.self) { Text($0) } }
                Picker("Source", selection: $entry.source) { ForEach(["Unspecified","Messages","Contacts","Phone","Photos","Notes","Files","Mail","Browser","Calendar","VEIL","HavenWatch","Afterframe","Connective","CommonGround","Luma Assistant","Workstation","Relay Support","Other"], id: \.self) { Text($0) } }
                TextEditor(text:$entry.text).frame(minHeight:150).accessibilityLabel("Your notes").focused($focus,equals:.body)
                Text("\(entry.text.count) / 10000 characters").font(.caption).foregroundColor(.secondary)
            }
            Section("Organization") {
                Picker("Confidence", selection: $entry.confidence) { ForEach(["Uncertain","Possible","Confident"], id: \.self) { Text($0) } }
                Picker("Status", selection: $entry.status) { ForEach(["Open","Follow up","Resolved"], id: \.self) { Text($0) } }
                Toggle("Pin entry", isOn: $entry.pinned)
                LabeledContent("Created") { Text(entry.created, style: .date) }
            }
            if !book.error.isEmpty { Text(book.error).foregroundColor(.secondary) }
        }.navigationTitle("Investigation entry").toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItemGroup(placement:.keyboard){Spacer();Button("Done"){focus=nil}}
            ToolbarItem(placement: .confirmationAction) {
                Button("Save"){if canSave(),book.put(entry){dismiss()}}.disabled(!canSave() || entry.text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || entry.text.count>10000 || entry.title.count>200)
            }
        }
    }
}
