import SwiftUI

/// Only public, fictional incoming messages. Never exposes a protected record.
struct PhoneAlert: Identifiable, Equatable {
    let neighbor: Neighbor
    let message: NeighborMessage
    let count: Int
    var id: String { message.id }
}

enum PhoneAlertCatalog {
    // Resolve against current unread records, not a stale captured preview.
    static func current(_ snapshot:PhoneAlert?,in world:PhoneWorld)->PhoneAlert? {
        guard let snapshot else{return nil}
        return alerts(in:world,unreadOnly:true).first{$0.id==snapshot.id && $0.neighbor==snapshot.neighbor}
    }
    static func alerts(in world: PhoneWorld, unreadOnly: Bool) -> [PhoneAlert] {
        Neighbor.visible(in:world).compactMap { neighbor in
            let incoming = (world.threads[neighbor.id] ?? []).filter { !$0.fromPlayer }
            let unread = incoming.filter { !$0.read }
            guard let latest = (unreadOnly ? unread : incoming).max(by: { $0.at < $1.at }) else { return nil }
            return PhoneAlert(neighbor: neighbor, message: latest, count: unread.count)
        }.sorted { $0.message.at > $1.message.at }
    }
}

struct PhoneNotificationCard: View {
    let alert: PhoneAlert
    var hidePreview = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 7) {
                    Image("Icon_Messages").resizable().scaledToFit().frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 7))
                    Text("MESSAGES").font(.caption2.weight(.semibold)).tracking(1)
                    Spacer(minLength: 3)
                    Text(alert.message.at, style: .relative).font(.caption2)
                }.foregroundColor(.white.opacity(0.68))
                HStack(alignment: .top, spacing: 10) {
                    if !hidePreview { NeighborAvatar(neighbor: alert.neighbor, size: 36) }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hidePreview ? "New message" : alert.neighbor.name)
                            .font(.subheadline.weight(.semibold))
                        Text(hidePreview ? "Unlock to view message" : alert.message.text)
                            .font(.subheadline).lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if alert.count > 1 { Text("\(alert.count) unread messages").font(.caption2).foregroundColor(.white.opacity(0.64)) }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.caption2).foregroundColor(.white.opacity(0.52))
                }.foregroundColor(.white)
            }
            .padding(13)
            .lumaSurface(radius: 22)
        }.buttonStyle(.plain)
            .accessibilityLabel(hidePreview ? "New message. Unlock to view." : "\(alert.neighbor.name), \(alert.message.text)")
    }
}

struct PhoneSearchResult: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let destination: String
    let detail: String?
    init(_ id: String, _ title: String, _ subtitle: String, _ symbol: String, _ destination: String, detail: String? = nil) {
        self.id = id; self.title = title; self.subtitle = subtitle; self.symbol = symbol; self.destination = destination; self.detail = detail
    }
}

enum PhonePublicSearch {
    static func results(query: String, world: PhoneWorld, documents: [String: String]) -> [PhoneSearchResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        func matches(_ values: String...) -> Bool {
            values.contains { $0.localizedCaseInsensitiveContains(q) }
        }
        var results: [PhoneSearchResult] = []
        for n in Neighbor.visible(in: world) {
            if matches(n.name, n.subtitle) {
                results.append(PhoneSearchResult("contact-" + n.id, n.name, n.subtitle, "person.crop.circle", "Contacts", detail: n.id))
            }
            if let message = world.threads[n.id]?.last(where: { matches($0.text) }) {
                results.append(PhoneSearchResult("message-" + n.id, n.name, message.text, "message.fill", "Messages", detail: n.id))
            }
        }
        for note in world.notes where matches(note.title, note.body) {
            results.append(PhoneSearchResult("note-" + note.id, note.title, "Notes", "note.text", "Notes", detail: note.id))
        }
        // Index public document titles only: no answer-bearing content in search snippets.
        for name in documents.keys.sorted() where matches(name) {
            results.append(PhoneSearchResult("file-" + name, name, "Files • On this phone", "doc.text", "Files", detail: name))
        }
        for document in WorldDocumentCatalog.search(q,world:world) {
            results.append(PhoneSearchResult("document-"+document.id,document.title,"Files · Restored record","doc.richtext","Files",detail:document.id))
        }
        for event in world.events where matches(event.title, event.detail) {
            results.append(PhoneSearchResult("event-" + event.id, event.title, "Calendar", "calendar", "Calendar", detail: event.id))
        }
        return results
    }
}

/// Shared public document catalog. Clue contents are only revealed by opening the file.
enum PhonePublicFiles {
    static let documents = [
        "Building handbook": "Ash Street residents: please keep the entrance clear and contact Denise at the building office for maintenance requests.",
        "Book reservation": "Maple Street Bookshop — reservation held until the end of this week.\nReservation reference: 241607.",
        "Coffee plans": "Meet Maya at the cafe opposite the bookstore. Confirm the day by text.",
        "Desk reminder": "Private folders use the six-digit reference from my book reservation. — Nora"
    ]
    static func available(in world: PhoneWorld) -> [String: String] { world.everydayArchiveRevision == nil ? documents : documents.merging(NoraEverydayArchive.documents) { existing, _ in existing } }
    static func tutorialVisit(for title: String) -> String? {
        switch title {
        case "Desk reminder": return "desk"
        case "Book reservation": return "reservation"
        default: return nil
        }
    }
}

struct PhoneDocumentView: View {
    let title: String
    @EnvironmentObject private var world: PhoneWorldStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "doc.text.fill").font(.system(size: 38)).foregroundColor(.blue)
                Text(title).font(.largeTitle.bold()).fixedSize(horizontal: false, vertical: true)
                Label("On this phone · Restored document", systemImage: "folder").font(.caption).foregroundColor(.secondary)
                Divider()
                Text(PhonePublicFiles.available(in: world.state)[title] ?? "Document unavailable.")
                    .font(.body).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
        }.navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .onAppear { if let visit = PhonePublicFiles.tutorialVisit(for: title) { world.recordTutorialVisit(visit) } }
    }
}
