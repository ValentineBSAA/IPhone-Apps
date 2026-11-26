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
    private var shown: [FieldEntry] {
        book.entries.filter { e in
            (filter == "All" || filter == e.status) &&
            (search.isEmpty || [e.title,e.text,e.category,e.source].contains { $0.localizedCaseInsensitiveContains(search) })
        }.sorted { a,b in a.pinned != b.pinned ? a.pinned : a.updated > b.updated }
    }
    var body: some View {
        List {
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
            }
            let findings=ImageInterpretation.recorded(world.state).filter{search.isEmpty || $0.note.localizedCaseInsensitiveContains(search)}
            if filter == "All" && !findings.isEmpty {
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
            if shown.isEmpty && findings.isEmpty { Text("No entries yet").foregroundColor(.secondary) }
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
                .swipeActions {
                    Button(role: .destructive) { deleting = entry } label: { Label("Delete", systemImage: "trash") }
                    Button { var e = entry; e.pinned.toggle(); _ = book.put(e) } label: { Label("Pin", systemImage: "pin") }.tint(.teal)
                }
            }
            if !book.error.isEmpty { Text(book.error).foregroundColor(.secondary) }
        }.scrollContentBackground(.hidden).background(LumaDesign.background.ignoresSafeArea())
            .navigationTitle("Field Notes").searchable(text: $search, prompt: "Search your notes")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { editing = FieldEntry() } label: { Image(systemName: "square.and.pencil").accessibilityLabel("New entry") } } }
            .sheet(item: $editing) { entry in
                NavigationStack { FieldEntryEditor(entry: entry, book: book) }
            }
            .confirmationDialog("Delete this entry?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                Button("Delete", role: .destructive) { if let e = deleting { _ = book.remove(e.id) }; deleting = nil }
                Button("Cancel", role: .cancel) { deleting = nil }
            }
    }
}
private struct FieldEntryEditor: View {
    @State var entry: FieldEntry
    @ObservedObject var book: FieldNotebook
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Form {
            Section("Entry") {
                TextField("Optional title", text: $entry.title)
                Picker("Category", selection: $entry.category) { ForEach(["Observation","Person","Place","Timeline","Question","Theory","To-do","Other"], id: \.self) { Text($0) } }
                Picker("Source", selection: $entry.source) { ForEach(["Unspecified","Messages","Contacts","Phone","Photos","Notes","Files","Mail","Browser","Calendar","Other"], id: \.self) { Text($0) } }
                TextEditor(text: $entry.text).frame(minHeight: 150).accessibilityLabel("Your notes")
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
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { if book.put(entry) { dismiss() } }.disabled(entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
