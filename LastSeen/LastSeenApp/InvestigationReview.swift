import SwiftUI

// SPOILER: authored chapter continuation. Do not expose catalog or answers
// in creator-facing QA, search indexes or unrestricted assistant output.
enum InvestigationReview {
    static let mailID = "local-review-03"
    static let requested = "investigation.review3.requested"
    static let read = "investigation.review3.read"
    static let finished = "investigation.review3.finished"
    static let pageID = "archive-comparison"
    static let sourcePageID = "studio-news"
    static func eligible(_ world: PhoneWorld) -> Bool {
        world.everydayArchiveRevision != nil && [
            "phone-tutorial-finished", "web.visited.studio",
            "investigation.chapter2.reviewed", "web.visited.archive-ledger",
            "investigation.chapter2.ledgerAcknowledged"
        ].allSatisfy { world.flags.contains($0) }
    }
    static func availableMail(_ world: PhoneWorld) -> Bool {
        eligible(world) && world.flags.contains(requested)
    }
    static func mail(at date: Date) -> LumaMailRecord {
        .init(id: mailID, peer: "adrian", sender: "Adrian Cole", subject: "A distinction in the review records",
              body: "I've been checking the terminology in the saved studio journal. A reference label tells us how a file was used, not who captured it. The review ledger also distinguishes import time from original capture. If the recovered index offers a comparison, please mark what each record actually supports. I can't certify a photograph or a person's whereabouts from a copy alone.\n\nAdrian",
              date: date, kind: "inbox")
    }
    static func ready(_ world: PhoneWorld) -> Bool {
        availableMail(world) && world.flags.contains(read) &&
        world.flags.contains("web.visited." + pageID) &&
        world.flags.contains("web.visited." + sourcePageID) &&
        (world.connectedWorld?.mail.contains { $0.id == mailID && $0.kind == "inbox" } ?? false)
    }
    struct Item: Identifiable {
        let id: String
        let source: String
        let statement: String
    }
    static let items: [Item] = [
        .init(id: "a", source: "Studio production note", statement: "The import label records the copy entering the index."),
        .init(id: "b", source: "Recovered review ledger", statement: "The original capture has not been independently confirmed."),
        .init(id: "c", source: "Received correspondence", statement: "The technical lead cannot certify a person's whereabouts from a copy.")
    ]
    static let classifications = ["Supported record label", "Unresolved origin", "Limit of a witness claim"]
    static func valid(_ selection: [String: Int]) -> Bool {
        selection.count == 3 && selection["a"] == 0 && selection["b"] == 1 && selection["c"] == 2
    }
    static func visibleSelection(_ world: PhoneWorld) -> [String: Int] {
        guard ready(world) else { return [:] }
        return (world.connectedWorld?.investigationReviewSelection ?? [:]).filter { key, value in
            items.contains { $0.id == key } && classifications.indices.contains(value)
        }
    }
}

struct InvestigationComparisonPanel: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var feedback = ""
    @State private var hint = false
    private var selected: [String: Int] { InvestigationReview.visibleSelection(world.state) }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Record comparison").font(.title2.bold())
            if InvestigationReview.ready(world.state) {
                Text("Classify each statement according to what its source actually establishes. This review does not identify a person or establish a location.").font(.subheadline)
                ForEach(InvestigationReview.items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.source).font(.caption.bold()).foregroundColor(.secondary)
                        Text(item.statement).font(.subheadline)
                        Picker("Classification", selection: Binding(get: { selected[item.id] ?? -1 }, set: { value in
                            world.setInvestigationReviewChoice(item.id, value: value)
                            feedback = ""
                        })) {
                            Text("Choose a classification").tag(-1)
                            ForEach(Array(InvestigationReview.classifications.enumerated()), id: \.offset) { entry in
                                Text(entry.element).tag(entry.offset)
                            }
                        }.pickerStyle(.menu).disabled(world.state.flags.contains(InvestigationReview.finished))
                    }.padding(12).lumaSurface(radius: 12)
                }
                if world.state.flags.contains(InvestigationReview.finished) {
                    Label("Review accepted", systemImage: "checkmark.seal.fill").foregroundColor(.teal)
                } else {
                    Button("Submit comparison") {
                        feedback = world.completeInvestigationReview() ? "Review accepted." : "Compare what each source establishes. Your selections are retained."
                    }.buttonStyle(.borderedProminent).disabled(selected.count != InvestigationReview.items.count)
                    Button(hint ? "Hide hint" : "Show hint") { hint.toggle() }
                    if hint { Text("Separate a recorded label from an unresolved fact and from a person's statement about the limits of their knowledge.").font(.caption).foregroundColor(.secondary) }
                }
                if !feedback.isEmpty { Text(feedback).font(.caption).foregroundColor(.secondary) }
            } else {
                Label("The necessary records have not yet been reviewed.", systemImage: "lock.fill").font(.subheadline).foregroundColor(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(15).lumaSurface()
    }
}
