import SwiftUI
import Foundation

// All addresses are fictional, local identifiers. No WebView or network calls.
struct LumaWebPage: Identifiable {
    let id: String
    let site: String
    let title: String
    let address: String
    let symbol: String
    let sections: [String]
    let links: [String]
    var gate: String? = nil
    var images: [String] = []
    func available(_ flags: Set<String>) -> Bool {
        guard gate.map({ flags.contains($0) }) ?? true else { return false }
        // Late chapter routes must not survive a temporarily replayed tutorial
        // or an incomplete checkpoint simply because their own flag exists.
        let reviewBase: Set<String> = ["phone-tutorial-finished","web.visited.studio","investigation.chapter2.reviewed","web.visited.archive-ledger","investigation.chapter2.ledgerAcknowledged",InvestigationReview.requested,InvestigationReview.read]
        switch id {
        case InvestigationReview.pageID:
            return reviewBase.isSubset(of: flags)
        case InvestigationResolution.indexID:
            return reviewBase.union([InvestigationReview.finished,"web.visited."+InvestigationReview.pageID]).isSubset(of: flags)
        case InvestigationResolution.noteID:
            return reviewBase.union([InvestigationReview.finished,"web.visited."+InvestigationReview.pageID,"web.visited."+InvestigationResolution.indexID]).isSubset(of: flags)
        case InvestigationResolution.conclusionID:
            return reviewBase.union([InvestigationReview.finished,"web.visited."+InvestigationReview.pageID,"web.visited."+InvestigationResolution.indexID,"web.visited."+InvestigationResolution.noteID,InvestigationResolution.requested,InvestigationResolution.read]).isSubset(of: flags)
        default: return true
        }
    }
}
enum LumaWebCatalog {
    static let pages: [LumaWebPage] = [
        .init(id:"books",site:"Maple Street Bookshop",title:"Bookshop",address:"maplebooks.test",symbol:"books.vertical.fill",sections:["Independent books, thoughtful gifts and a quiet place to browse. Open 10–6.","Reservations are held for seven days. Bring your reservation reference to the counter."],links:["books-events","books-reservations","cafe"]),
        .init(id:"books-events",site:"Maple Street Bookshop",title:"Events & reading club",address:"maplebooks.test/events",symbol:"calendar",sections:["Wednesday reading group · 6 PM","This month: mysteries, folklore and stories about places we remember. Ask at the counter about the next meeting."],links:["books","repo-folio"]),
        .init(id:"residents",site:"Ash Street Residents",title:"Resident noticeboard",address:"ashstreet.test",symbol:"building.2.fill",sections:["Welcome to the Ash Street residents' noticeboard.","Elevator inspection pending contractor confirmation. Front entrance and stairs remain available."],links:["residents-services","studio"]),
        .init(id:"residents-services",site:"Ash Street Residents",title:"Building services",address:"ashstreet.test/services",symbol:"wrench",sections:["Building office: Denise Hall.","Maintenance enquiries and parcel collection are handled by the office. Private resident records are not published here."],links:["residents"]),
        .init(id:"cafe",site:"Maple Cafe",title:"Coffee & pastries",address:"maplecafe.test",symbol:"cup.and.saucer.fill",sections:["Espresso, cappuccino, pastries and sandwiches.","Across from the bookshop. Seasonal specials and a quiet corner to work."],links:["cafe-menu","cafe-journal","books"]),
        .init(id:"cafe-menu",site:"Maple Cafe",title:"Seasonal menu",address:"maplecafe.test/menu",symbol:"fork.knife",sections:["Vanilla latte · lavender tea · cinnamon pastries","Breakfast and lunch served throughout the day."],links:["cafe"]),
        .init(id:"studio",site:"Blue Hour Interactive",title:"Independent games, personal stories",address:"bluehour.test",symbol:"moon.stars.fill",sections:["A small independent studio in the Ash Street complex.","Nora Bennett leads development. The team works on experimental interactive stories, accessibility and thoughtful game design."],links:["studio-team","studio-projects","studio-notes","studio-news"]),
        .init(id:"studio-team",site:"Blue Hour Interactive",title:"Meet the studio",address:"bluehour.test/team",symbol:"person.2.fill",sections:["Nora Bennett · Founder / development","Adrian Cole · Technical lead","Tessa Reed · Art and production"],links:["studio","studio-projects"]),
        .init(id:"studio-projects",site:"Blue Hour Interactive",title:"Current projects",address:"bluehour.test/projects",symbol:"gamecontroller.fill",sections:["A work-in-progress psychological horror prototype explores memory, familiar places and unreliable observations.","Development material is not a statement of real events. The team keeps experimental references separate from ordinary project notes."],links:["studio","studio-notes"],images:["Recovered_B27_27","Recovered_B27_29"]),
        .init(id:"studio-notes",site:"Blue Hour Interactive",title:"Development journal",address:"bluehour.test/journal",symbol:"doc.text.fill",sections:["The current build review focuses on accessibility, persistence and visual consistency.","Some older reference records are missing from the current index. A recovered local index may be available after the phone's restoration investigation."],links:["studio","archive"],images:["Recovered_B27_26"]),
        .init(id:"archive",site:"Recovered archive",title:"Local archive index",address:"archive.test",symbol:"archivebox.fill",sections:["This is a cached, incomplete collection. Source claims have not been verified.","Some records may be inaccurate, altered or fictional. Compare them with material already available on the phone."],links:["archive-records","studio-notes","veil-guide"],gate:"investigation.contact.received"),
        .init(id:"archive-records",site:"Recovered archive",title:"Recovered attachments",address:"archive.test/records",symbol:"photo.stack",sections:["Local recovered records. Dates and provenance may be unreliable.","Choose whether to reveal individual images. The text-only inspection option records the same discovery."],links:["archive","archive-review"],gate:"web.visited.archive",images:["Recovered_B27_02","Recovered_B27_03","Recovered_B27_13","Recovered_B27_18"])
        , .init(id:"books-reservations",site:"Maple Street Bookshop",title:"Reservations & collections",address:"maplebooks.test/reservations",symbol:"bookmark",sections:["Pick up reserved books at the front counter. Bring the confirmation from your order.","Special orders are collected separately from reading-club stock. The shop does not publish customer details."],links:["books","books-events","repo-leaf"])
        , .init(id:"cafe-journal",site:"Maple Cafe",title:"From the counter",address:"maplecafe.test/journal",symbol:"newspaper",sections:["Our window seats are popular with people who bring laptops. Please keep the aisle clear when the reading group arrives.","This week's staff pick: a warm cinnamon pastry with a small coffee. Bring a reusable cup if you have one."],links:["cafe-menu","books-events","repo-chronicle"])
        , .init(id:"studio-news",site:"Blue Hour Interactive",title:"Studio notebook",address:"bluehour.test/news",symbol:"newspaper",sections:["Development update · The team is separating the playable prototype from its reference library. Early builds may contain temporary names and duplicate images.","Production note · The review ledger uses two labels: capture time for the original record and import time for the copy. An imported image is not necessarily a new photograph.","Technical note · The public journal remains the stable reference. Internal review material is available only through the recovered index."],links:["studio","studio-notes","repo-postbox"])
        , .init(id:"archive-review",site:"Recovered archive",title:"Review desk",address:"archive.test/review",symbol:"lock.shield",sections:["The next folder is a restricted review collection. Its index is incomplete; entries cannot be treated as verified evidence.","Review the available record and the studio's public production note before submitting an interpretation."],links:["archive-records","studio-news","archive-collection"],gate:"web.visited.archive-records")
        , .init(id:"archive-collection",site:"Recovered archive",title:"Review collection",address:"archive.test/collection",symbol:"folder.fill",sections:["Two catalog entries refer to the same reference export. Their import labels differ; the original capture field is missing from one.","A copy can circulate without establishing where or when the original was made. The review ledger marks this entry disputed, not resolved.","The next inquiry should establish provenance rather than assume the image depicts an event."],links:["archive-review","archive-ledger"],gate:"investigation.chapter2.reviewed")
        , .init(id:"archive-ledger",site:"Recovered archive",title:"Provenance ledger",address:"archive.test/ledger",symbol:"doc.plaintext",sections:["Review ledger · Original capture: not independently confirmed. Import: recorded in the restored index. Source: unverified.","The collection has been separated into working references and disputed copies. Keep observations distinct from conclusions.","End of the currently recovered ledger. Further records remain unavailable."],links:["archive-collection","studio-news","repo-bench","archive-comparison"],gate:"web.visited.archive-collection")
        , .init(id:InvestigationReview.pageID,site:"Recovered archive",title:"Record comparison",address:"archive.test/comparison",symbol:"list.bullet.rectangle",sections:["Compare the available sources without treating a copy as a verified original. The review retains supported observations separately from unresolved claims."],links:["archive-ledger","studio-news",InvestigationResolution.indexID],gate:InvestigationReview.read)
        , .init(id:InvestigationResolution.indexID,site:"Recovered archive",title:"Local session record",address:"archive.test/session",symbol:"waveform.path",sections:["Session R-04 · mode: rehearsal · source: bundled reference archive. Output: local message presentation. Recipient: restored test phone. Dispatch is driven by review events, not an incoming remote connection.","The sender label is a fixture, not a verified identity. The session contains prewritten reactions to questions about the archive. A matching reply does not establish a person at the other end.","The restored index has imported reference copies more than once. The original capture remains disputed. Read the associated handoff before drawing a conclusion."],links:[InvestigationResolution.noteID,"archive-comparison"],gate:InvestigationReview.finished)
        , .init(id:InvestigationResolution.noteID,site:"Recovered archive",title:"Owner handoff",address:"archive.test/handoff",symbol:"doc.text",sections:["Recovered draft · attributed to Nora Bennett · saved before the repair. Not an independently authenticated statement.","Someone keeps sending me pieces of things I've already posted. Once I started looking for patterns, I was finding them everywhere. I made a rehearsal out of the copies to see how convincing the sequence could become. It was worse than I expected.","If the repair restores the rehearsal, the messages may look new. They are not proof that I am sitting somewhere typing. Please don't mistake an archive for permission to know everything about me.","I'm taking some time away. I'll contact Maya myself when I can. Don't put my address or photographs into another report. If you're the one who got this phone working, thank you. I hope you can stop when you've done enough."],links:[InvestigationResolution.indexID,InvestigationResolution.conclusionID],gate:"web.visited."+InvestigationResolution.indexID)
        , .init(id:InvestigationResolution.conclusionID,site:"Recovered archive",title:"Repair review",address:"archive.test/disposition",symbol:"checkmark.shield",sections:["The rehearsal record, owner-attributed handoff and received correspondence are separate sources. They support closing the phone review without establishing an exact location or accusing an unverified person."],links:[InvestigationResolution.noteID],gate:InvestigationResolution.read)
,
        .init(id:"repo-folio",site:"Folio Works",title:"Local tools",address:"maplebooks.test/tools",symbol:"book",sections:["Readable local web pages.","Relay repository: https://folio-tools.example/","A local index for Reader Focus. Add this address in Relay if you want the optional tool."],links:["books-events"],gate:"web.visited.books-events"),
        .init(id:"repo-postbox",site:"Postbox Labs",title:"Local tools",address:"bluehour.test/mail-tools",symbol:"paperclip",sections:["Local correspondence utilities.","Relay repository: https://postbox-tools.example/","A local index for Attachment Lens. Add this address in Relay if you want the optional tool."],links:["studio-news"],gate:"web.visited.studio-news"),
        .init(id:"repo-leaf",site:"Leaf Paper",title:"Local tools",address:"maplebooks.test/reading-tools",symbol:"doc.richtext",sections:["Document readability tools.","Relay repository: https://leaf-paper.example/","A local index for Document Zoom. Add this address in Relay if you want the optional tool."],links:["books-reservations"],gate:"web.visited.books-reservations"),
        .init(id:"repo-chronicle",site:"Chronicle Works",title:"Local tools",address:"maplecafe.test/timeline-tools",symbol:"clock",sections:["Local timeline and activity display.","Relay repository: https://chronicle-tools.example/","A local index for Post Timestamp. Add this address in Relay if you want the optional tool."],links:["cafe-journal"],gate:"web.visited.cafe-journal"),
        .init(id:"veil-guide",site:"Recovered archive",title:"Local anonymous browser index",address:"archive.test/local-browser",symbol:"eye.slash",sections:["The recovered catalog references a bundled local browser called VEIL. Its package becomes available in Relay after this page is reviewed. It is a local simulation, not a real network service."],links:["archive"],gate:"web.visited.archive"),
        .init(id:"repo-bench",site:"Benchcraft",title:"Local tools",address:"archive.test/bench-tools",symbol:"desktopcomputer",sections:["Repair console extensions.","Relay repository: https://benchcraft-tools.example/","A local index for Diagnostics Strip. Add this address in Relay if you want the optional tool."],links:["archive-ledger"],gate:"web.visited.archive-ledger")
    ]
    static func page(_ id: String) -> LumaWebPage? {
        pages.first { $0.id == id || ($0.address == id) || ($0.site == id && !$0.address.contains("/")) }
    }
    static func visible(_ flags: Set<String>) -> [LumaWebPage] { pages.filter { $0.available(flags) } }
    static func isReviewReady(_ flags: Set<String>) -> Bool {
        flags.contains("web.visited.archive-review") && flags.contains("web.visited.studio-news") &&
        (page("archive-records")?.images.contains { flags.contains("web.inspected." + $0) } ?? false)
    }
    static func search(_ raw: String, flags: Set<String>) -> [LumaWebPage] {
        let q = normalized(raw)
        return visible(flags).filter { p in
            q.isEmpty ? !p.address.contains("/") : ([p.address,p.site,p.title] + p.sections).contains { $0.localizedCaseInsensitiveContains(q) }
        }
    }
    static func attachments(in flags: Set<String>) -> [String] { visible(flags).flatMap(\.images) }
    static func normalized(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in:.whitespacesAndNewlines).lowercased()
        if value.hasPrefix("https://") { value.removeFirst(8) }
        else if value.hasPrefix("http://") { value.removeFirst(7) }
        return value.trimmingCharacters(in:CharacterSet(charactersIn:"/"))
    }
}
struct LumaBrowserVisit: Codable, Equatable {
    let pageID: String
    let date: Date?
}
enum LumaBrowserHistory {
    static func decode(_ raw: String, legacy: String) -> [LumaBrowserVisit] {
        if let data = raw.data(using:.utf8), let rows = try? JSONDecoder().decode([LumaBrowserVisit].self,from:data) {
            return Array(rows.suffix(100))
        }
        return legacy.split(separator:"|").map(String.init).compactMap { id in
            LumaWebCatalog.page(id).map { LumaBrowserVisit(pageID:$0.id,date:nil) }
        }
    }
    static func encode(_ rows: [LumaBrowserVisit]) -> String {
        guard let data = try? JSONEncoder().encode(Array(rows.suffix(100))) else { return "[]" }
        return String(data:data,encoding:.utf8) ?? "[]"
    }
    static func record(_ id: String, in rows: [LumaBrowserVisit], now: Date = Date()) -> [LumaBrowserVisit] {
        Array((rows + [LumaBrowserVisit(pageID:id,date:now)]).suffix(100))
    }
    static func visible(_ rows: [LumaBrowserVisit], flags: Set<String>) -> [LumaBrowserVisit] {
        rows.filter { LumaWebCatalog.page($0.pageID)?.available(flags) == true }
    }
}
enum InvestigationProgress {
    struct Step: Identifiable {
        let id: String
        let title: String
        let hint: String
        let route: String
        let done: Bool
    }
    static func steps(_ flags: Set<String>) -> [Step] {
        [
            .init(id:"contact",title:"Establish contact",hint:"Check the latest conversation in Messages. Explain how you received the phone.",route:"messages",done:flags.contains("phone-tutorial-replied")),
            .init(id:"personal",title:"Follow the first leads",hint:"Read the reminders already mentioned in the conversation, then compare available documents.",route:"notes",done:flags.contains("phone-tutorial-file-guidance")),
            .init(id:"recovery",title:"Complete the initial recovery",hint:"Return to the protected records once you have found the necessary information. Revisit Files if needed.",route:"files",done:flags.contains("phone-tutorial-finished")),
            .init(id:"studio",title:"Explore the restored web records",hint:"The studio's saved website is a useful place to start.",route:"browser",done:flags.contains("web.visited.studio")),
            .init(id:"followup",title:"Review new correspondence",hint:"Check recent messages and the pages they point toward.",route:"messages",done:flags.contains("web.visited.archive")),
            .init(id:"records",title:"Compare recovered records",hint:"Examine an available archive attachment or use its text-only inspection option.",route:"browser",done:flags.contains(where:{$0.hasPrefix("web.inspected.Recovered_B27_") && LumaWebCatalog.page("archive-records")!.images.contains(String($0.dropFirst("web.inspected.".count)))}))
            , .init(id:"review",title:"Review the next collection",hint:"Compare the available web records and complete the review at the restricted collection.",route:"browser",done:flags.contains("investigation.chapter2.reviewed"))
            , .init(id:"ledger",title:"Establish provenance",hint:"Revisit the accessible collection and read its linked ledger.",route:"browser",done:flags.contains("web.visited.archive-ledger"))
            , .init(id:"review3-mail",title:"Check new correspondence",hint:"Look for the next review message in Mail. It may take a little time to arrive.",route:"mail",done:flags.contains(InvestigationReview.read))
            , .init(id:"review3-compare",title:"Compare the available sources",hint:"Return to the recovered ledger and follow the newly available review link.",route:"browser",done:flags.contains(InvestigationReview.finished))
            , .init(id:"review4-session",title:"Examine the next record",hint:"Return to the completed comparison and follow its new link. Read the available related records.",route:"browser",done:flags.contains("web.visited."+InvestigationResolution.noteID))
            , .init(id:"review4-mail",title:"Check for further correspondence",hint:"Check Mail. A reply can arrive after a short delay.",route:"mail",done:flags.contains(InvestigationResolution.read))
            , .init(id:"review4-finish",title:"Complete the review",hint:"Return to the last recovered record and review the available decision.",route:"browser",done:flags.contains(InvestigationResolution.completed))
        ]
    }
    /// Only the contiguous earned prefix is shown. A later flag from an
    /// interrupted checkpoint never exposes a future lead in the overview.
    static func completed(_ flags: Set<String>) -> [Step] {
        Array(steps(flags).prefix(while: { $0.done }))
    }
    static func current(_ flags: Set<String>) -> Step? {
        steps(flags).dropFirst(completed(flags).count).first
    }
    static func summary(_ flags: Set<String>) -> String { "\(completed(flags).count) completed" }

    struct Guidance {
        let text: String
        let route: String
        var pageID: String? = nil
        var waiting = false
    }

    /// Concrete guidance is derived from the current earned lead, never from
    /// a future chapter or a puzzle solution. Browser destinations must still
    /// be visible under the normal catalog policy.
    static func guidance(_ world: PhoneWorld, detailed: Bool) -> Guidance? {
        let flags = world.flags
        guard let step = current(flags) else { return nil }
        if !detailed { return .init(text: step.hint, route: step.route) }
        func page(_ id: String, _ text: String) -> Guidance {
            guard let record = LumaWebCatalog.page(id), record.available(flags) else {
                return .init(text: step.hint, route: step.route)
            }
            return .init(text: text + " Open " + record.title + " in Browser (" + record.address + ").", route: "browser", pageID: record.id)
        }
        func mail(_ id: String) -> Guidance {
            let delivered = LumaMailCatalog.visible(world).contains { $0.id == id && $0.kind == "inbox" }
            if delivered {
                return .init(text: "The expected message is available in Mail. Check Inbox, Archive or Trash if you moved it earlier.", route: "mail")
            }
            return .init(text: "The next message has not arrived yet. You can explore other available apps while the local activity continues.", route: "mail", waiting: true)
        }
        switch step.id {
        case "contact": return .init(text: "Open Messages and return to the introductory conversation. Send a reply before looking for more leads.", route: "messages")
        case "personal":
            if !flags.contains("phone-tutorial-visited-note") { return .init(text: "Open the reminder mentioned in the conversation, not just the Notes app.", route: "notes") }
            return .init(text: "Open both of the documents mentioned in the conversation. Reading only the file list is not enough.", route: "files")
        case "recovery": return .init(text: "Return to the protected record mentioned in Messages. Use information you have already found, or revisit the conversation for context.", route: "files")
        case "studio": return page("studio", "Read the available studio website.")
        case "followup": return page("archive", "Follow the newly available local index.")
        case "records": return page("archive-records", "Inspect one available attachment. The text-only option counts equally.")
        case "review":
            if !flags.contains("web.visited.studio-news") { return page("studio-news", "Read the production note before attempting the comparison.") }
            return page("archive-review", "Compare the sources you have already inspected and submit your own interpretation.")
        case "ledger":
            if !flags.contains("web.visited.archive-collection") { return page("archive-collection", "Read the newly available collection and follow its links.") }
            return page("archive-ledger", "Read the linked ledger.")
        case "review3-mail": return mail(InvestigationReview.mailID)
        case "review3-compare":
            if !flags.contains("web.visited.studio-news") { return page("studio-news", "Read the source note first.") }
            return page(InvestigationReview.pageID, "Complete the comparison using your own observations. Incorrect choices can be revised.")
        case "review4-session":
            if !flags.contains("web.visited." + InvestigationResolution.indexID) { return page(InvestigationResolution.indexID, "Read the newly available record.") }
            return page(InvestigationResolution.noteID, "Read the linked record before moving on.")
        case "review4-mail": return mail(InvestigationResolution.mailID)
        case "review4-finish": return page(InvestigationResolution.conclusionID, "Review the available decision when you are ready.")
        default: return .init(text: step.hint, route: step.route)
        }
    }
    static func unknownReply(words: Set<String>, flags: Set<String>) -> String {
        if !words.isDisjoint(with:["nora","who","name","identity","you"]) { return "A name on a screen isn't proof. Please compare what you can actually verify." }
        if !words.isDisjoint(with:["where","location","address","safe"]) { return "I can't confirm a location. Start with what you already have." }
        if !words.isDisjoint(with:["archive","website","browser","studio","records","photo","photos"]) {
            return flags.contains("web.visited.archive") ? "Keep your own notes. Don't assume every recovered image is an authentic photograph." : "Check the studio's development journal. Look for the recovered local index."
        }
        return "I'm not sure how much of the original backup survived. What have you been able to recover?"
    }
}
struct InvestigationProgressView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    let openBrowser: () -> Void
    let openMessages: () -> Void
    let openNotes: () -> Void
    let openFiles: () -> Void
    let openMail: () -> Void
    @State private var hintLevel = 0
    private var completed: [InvestigationProgress.Step] { InvestigationProgress.completed(world.state.flags) }
    private var lead: InvestigationProgress.Step? { InvestigationProgress.current(world.state.flags) }
    private var guidance: InvestigationProgress.Guidance? { InvestigationProgress.guidance(world.state, detailed: hintLevel >= 2) }
    var body: some View {
        List {
            Section {
                LumaHeader(title:"Investigation",detail:InvestigationProgress.summary(world.state.flags),symbol:"checklist")
                Text("A record of your discoveries, not a solution guide. New leads appear as you explore.").font(.footnote).foregroundColor(.secondary)
            }
            Section("Completed") {
                if completed.isEmpty { Text("No completed leads yet.").foregroundColor(.secondary) }
                ForEach(completed) { step in Label(step.title,systemImage:"checkmark.circle.fill").foregroundColor(LumaDesign.accent) }
            }
            Section("Current lead") {
                if let step = lead {
                    Label(step.title,systemImage:"magnifyingglass")
                    Button(hintLevel == 0 ? "I need a hint" : "Hide hints") { hintLevel = hintLevel == 0 ? 1 : 0 }
                    if hintLevel > 0, let guidance {
                        Text(guidance.text).foregroundColor(.secondary)
                        if hintLevel == 1 { Button("More specific guidance") { hintLevel = 2 } }
                        if guidance.waiting { Label("Awaiting local activity", systemImage: "clock").font(.caption).foregroundColor(.secondary) }
                        Button("Open suggested app") {
                            switch guidance.route {
                            case "browser": openBrowser()
                            case "messages": openMessages()
                            case "notes": openNotes()
                            case "mail": openMail()
                            default: openFiles()
                            }
                        }
                    }
                } else { Text(world.state.flags.contains(InvestigationResolution.completed) ? "Investigation complete. You may continue exploring the phone." : "All currently documented leads completed. Keep exploring.").foregroundColor(.secondary) }
            }
            if lead != nil {
                Section("Not yet uncovered") { Label("Further leads remain unavailable",systemImage:"lock.fill").foregroundColor(.secondary) }
            }
        }.navigationTitle("Investigation progress").scrollContentBackground(.hidden).background(LumaDesign.background)
            .onChange(of: lead?.id) { _ in hintLevel = 0 }
    }
}
struct LumaWebBrowser: View {
    let wifi: Bool
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("lastseen.lab.horrorEffects") private var horrorEffects = true
    @AppStorage("lastseen.lab.atmosphereIntensity") private var atmosphereIntensity = LumaArchiveAtmosphere.Intensity.standard.rawValue
    @AppStorage("lastseen.lab.messageSound") private var messageSound = true
    private func atmosphere(for id: String) -> LumaArchiveAtmosphere.Treatment? {
        LumaArchiveAtmosphere.treatment(pageID: id, flags: world.state.flags,
            intensity: LumaArchiveAtmosphere.Intensity(rawValue: atmosphereIntensity) ?? .off,
            enabled: horrorEffects, reduceMotion: reduceMotion)
    }
    @AppStorage("lastseen.relay.installed") private var relayInstalled=""
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    private var readerFocus:Bool {RelayCatalog.tweakActive("readerfocus",installed:relayInstalled,safeMode:safeMode,flags:world.state.flags)}
    @AppStorage("lastseen.lab.browserPage") private var current = ""
    @AppStorage("lastseen.lab.browserBackStack") private var backRaw = ""
    @AppStorage("lastseen.lab.browserForwardStack") private var forwardRaw = ""
    @AppStorage("lastseen.lab.history") private var history = ""
    @AppStorage("lastseen.lab.bookmarks") private var bookmarks = ""
    @AppStorage("lastseen.lab.browserVisitLog") private var visitRaw = ""
    @State private var showHistory = false
    @State private var confirmClear = false
    @State private var reviewAnswer = ""
    @State private var reviewNotice = ""
    @FocusState private var addressFocused: Bool
    @AppStorage("lastseen.lab.browserSeeded") private var seeded = false
    @State private var query = ""
    @State private var showHint = false
    @State private var revealed: Set<String> = []
    private let home = "@home"
    private var page: LumaWebPage? { LumaWebCatalog.page(current).flatMap { $0.available(world.state.flags) ? $0 : nil } }
    private func entries(_ raw:String) -> [String] { raw.split(separator:"|").map(String.init).compactMap { x in x == home ? home : LumaWebCatalog.page(x).flatMap { $0.available(world.state.flags) ? $0.id : nil } } }
    private func encoded(_ values:[String]) -> String { values.joined(separator:"|") }
    private var matches: [LumaWebPage] { LumaWebCatalog.search(query,flags:world.state.flags) }
    private var visits: [LumaBrowserVisit] { LumaBrowserHistory.decode(visitRaw,legacy:history) }
    private var visibleVisits: [LumaBrowserVisit] { LumaBrowserHistory.visible(visits,flags:world.state.flags) }
    private func submitAddress() {
        addressFocused = false
        let q = LumaWebCatalog.normalized(query)
        if let p = LumaWebCatalog.visible(world.state.flags).first(where:{$0.address == q}) { visit(p.id) }
        else { showResults() }
    }
    private func tint(_ p:LumaWebPage) -> Color {
        switch p.site {
        case "Maple Street Bookshop": return Color(red:0.52,green:0.32,blue:0.22)
        case "Maple Cafe": return Color(red:0.26,green:0.48,blue:0.35)
        case "Ash Street Residents": return Color(red:0.23,green:0.39,blue:0.61)
        case "Blue Hour Interactive": return Color(red:0.28,green:0.30,blue:0.60)
        default: return Color(red:0.20,green:0.37,blue:0.36)
        }
    }
    private func websiteHeader(_ p:LumaWebPage) -> some View {
        VStack(alignment:.leading,spacing:12) {
            HStack {
                Image(systemName:p.symbol).font(.title2)
                Text(p.site).font(.headline)
                Spacer()
                Image(systemName:"globe").accessibilityHidden(true)
            }
            Divider().overlay(.white.opacity(0.3))
            Text(p.title).font(.largeTitle.bold()).fixedSize(horizontal:false,vertical:true)
            Text(p.address).font(.caption).opacity(0.85)
        }.foregroundColor(.white).padding(20)
        .frame(maxWidth:.infinity,alignment:.leading)
        .background(tint(p),in:RoundedRectangle(cornerRadius:18))
    }
    private func websiteParagraph(_ text:String, index:Int, page p:LumaWebPage) -> some View {
        VStack(alignment:.leading,spacing:8) {
            if p.site == "Recovered archive" {
                Text("RECORD " + String(index+1)).font(.caption.monospaced()).foregroundColor(.secondary)
            } else if p.site == "Blue Hour Interactive" {
                Label(index == 0 ? "Studio update" : "Development notes",systemImage:index == 0 ? "newspaper" : "doc.text").font(.caption.bold()).foregroundColor(tint(p))
            } else if p.site == "Ash Street Residents" {
                Label("Resident information",systemImage:"info.circle").font(.caption.bold()).foregroundColor(tint(p))
            }
            Text(text).font(readerFocus ? .title3 : .body)
                .fixedSize(horizontal:false,vertical:true).textSelection(.enabled)
        }.frame(maxWidth:.infinity,alignment:.leading).padding(15).lumaSurface(radius:14)
    }
    private var reviewPanel: some View {
        VStack(alignment:.leading,spacing:12) {
            Label("Restricted collection",systemImage:"lock.shield").font(.headline)
            if world.state.flags.contains("investigation.chapter2.reviewed") {
                Label("Review accepted",systemImage:"checkmark.circle").foregroundColor(LumaDesign.accent)
            } else if LumaWebCatalog.isReviewReady(world.state.flags) {
                Text("Which interpretation is supported by the available records?").font(.subheadline)
                ForEach(["The import date proves when the image was taken.","A copy may have a different import date from its original capture.","Every recovered image is independently verified."],id:\.self) { option in
                    Button { reviewAnswer=option } label: {
                        HStack { Image(systemName:reviewAnswer == option ? "largecircle.fill.circle" : "circle"); Text(option); Spacer() }.frame(maxWidth:.infinity,alignment:.leading)
                    }.buttonStyle(.plain)
                }
                Button("Submit review") {
                    reviewNotice = world.submitWebReview(reviewAnswer) ? "Review accepted." : "Compare the record labels again. Your progress is kept."
                }.buttonStyle(.borderedProminent).disabled(reviewAnswer.isEmpty)
                if !reviewNotice.isEmpty { Text(reviewNotice).font(.caption).foregroundColor(.secondary) }
            } else {
                Text("The review is locked until the necessary records have been examined.").font(.subheadline).foregroundColor(.secondary)
            }
        }.frame(maxWidth:.infinity,alignment:.leading).padding(15).lumaSurface()
    }
    var body: some View {
        VStack(spacing:0) {
            HStack {
                Image(systemName:"magnifyingglass").foregroundColor(.secondary)
                TextField("Search or enter address",text:$query).textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.go)
                    .focused($addressFocused).onSubmit { submitAddress() }.accessibilityIdentifier("luma.browser.address")
                if !query.isEmpty { Button { query=""; showResults() } label:{ Image(systemName:"xmark.circle.fill").accessibilityLabel("Clear address") } }
                Button("Go") { submitAddress() }
                Button { if let p=page { apply(p.id) } else { submitAddress() } } label:{ Image(systemName:"arrow.clockwise").accessibilityLabel("Reload page") }
            }.padding(12).background(.thinMaterial,in:RoundedRectangle(cornerRadius:16)).padding(10)
            ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    if let p=page {
                        websiteHeader(p)
                        if p.site == "Maple Cafe" || p.site == "Maple Street Bookshop" {
                            Label(p.site == "Maple Cafe" ? "Coffee · Food · Community" : "Books · Events · Reservations",systemImage:p.symbol).font(.subheadline).foregroundColor(.secondary)
                        }
                        ForEach(Array(p.sections.enumerated()),id:\.offset) { index,paragraph in
                            websiteParagraph(paragraph,index:index,page:p)
                        }
                        if p.id == "archive-review" { reviewPanel }
                        if p.id == InvestigationReview.pageID { InvestigationComparisonPanel() }
                        if p.id == InvestigationResolution.conclusionID { InvestigationResolutionPanel() }
                        ForEach(p.images,id:\.self) { asset in
                            VStack(alignment:.leading,spacing:12) {
                                if revealed.contains(asset) && LumaWebCatalog.attachments(in:world.state.flags).contains(asset) {
                                    if let photo = PortraitImages.load(asset) {
                                        Image(uiImage: photo).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius:12)).accessibilityLabel("Recovered image")
                                    } else {
                                        Label("Image unavailable. Text inspection remains available.",systemImage:"exclamationmark.triangle").font(.caption)
                                    }
                                    Button("Hide image") { revealed.remove(asset) }
                                } else {
                                    Label("Recovered attachment",systemImage:"photo.on.rectangle")
                                    Button("Reveal image") { revealed.insert(asset); world.inspectWebAttachment(asset) }.buttonStyle(.bordered)
                                    Button("Inspect without image") { world.inspectWebAttachment(asset) }.font(.caption)
                                    if world.state.flags.contains("web.inspected."+asset) { Label("Inspected",systemImage:"checkmark.circle").font(.caption) }
                                }
                            }.frame(maxWidth:.infinity,alignment:.leading).padding(14).lumaSurface()
                        }
                        ForEach(p.links.compactMap { LumaWebCatalog.page($0) }.filter { $0.available(world.state.flags) }) { link in
                            Button { visit(link.id) } label:{ HStack { Text(link.title); Spacer(); Image(systemName:"chevron.right") }.frame(maxWidth:.infinity,alignment:.leading).padding(14).lumaSurface() }.buttonStyle(.plain)
                        }
                        Label("Saved local page",systemImage:"checkmark.circle").font(.caption).foregroundColor(.secondary)
                    } else {
                        LumaHeader(title:query.isEmpty ? "Start page" : "Search results",detail:"Saved sites and bookmarks",symbol:"globe")
                        ForEach(matches) { p in
                            Button { visit(p.id) } label:{ HStack(spacing:12) { Image(systemName:p.symbol).font(.title2).foregroundColor(LumaDesign.accent); VStack(alignment:.leading){ Text(p.site).font(.headline); Text(p.address).font(.caption).foregroundColor(.secondary) }; Spacer(); Image(systemName:"chevron.right") }.padding(14).lumaSurface() }.buttonStyle(.plain)
                        }
                        if matches.isEmpty { Text("No accessible saved pages match.").foregroundColor(.secondary) }
                        if query.isEmpty {
                            siteSection("Bookmarks",entries(bookmarks))
                            Button { showHistory = true } label: { Label("Browsing history",systemImage:"clock.arrow.circlepath") }.buttonStyle(.bordered)
                        }
                    }
                }.padding(18)
            }
            Divider()
            HStack {
                Button { move(back:true) } label:{ Image(systemName:"chevron.backward").accessibilityLabel("Back") }.disabled(entries(backRaw).isEmpty)
                Spacer()
                Button { move(back:false) } label:{ Image(systemName:"chevron.forward").accessibilityLabel("Forward") }.disabled(entries(forwardRaw).isEmpty)
                Spacer()
                Button { showResults(clear:true) } label:{ Image(systemName:"house").accessibilityLabel("Start page") }
                Spacer()
                Button { showHistory = true } label:{ Image(systemName:"clock.arrow.circlepath").accessibilityLabel("History") }
                Spacer()
                Button {
                    guard let p=page else{return}; var values=entries(bookmarks)
                    if values.contains(p.id){values.removeAll{$0==p.id}} else{values.append(p.id)}
                    bookmarks=encoded(values)
                } label:{ Image(systemName:page.map{entries(bookmarks).contains($0.id)} == true ? "bookmark.fill":"bookmark").accessibilityLabel("Bookmark") }.disabled(page==nil)
            }.font(.title3).padding(.horizontal,25).padding(.vertical,14)
            Text(wifi ? "Local browser · Offline":"Local browser · Wi-Fi off").font(.caption2).foregroundColor(.secondary).padding(.bottom,4)
        }.navigationTitle("Browser").navigationBarTitleDisplayMode(.inline)
        .overlay {
            if phase == .active, !showHistory, let page, let treatment = atmosphere(for: page.id) {
                LumaArchiveEdgeTreatment(opacity: treatment.edgeOpacity)
            }
        }
        .onAppear {
            if !seeded { if history.isEmpty { history="cafe|books" }; if bookmarks.isEmpty{bookmarks="books"}; seeded=true }
            if visitRaw.isEmpty { visitRaw=LumaBrowserHistory.encode(visits) }
            if let p=page { current=p.id; query=p.address } else { current="" }
        }
        .onChange(of:world.state.flags) { _ in if page==nil { current=""; revealed=[] } }
        .sheet(isPresented:$showHistory) {
            NavigationStack {
                List {
                    if visibleVisits.isEmpty { Text("No browsing history").foregroundColor(.secondary) }
                    ForEach(Array(visibleVisits.reversed().enumerated()),id:\.offset) { _,entry in
                        if let p=LumaWebCatalog.page(entry.pageID) {
                            Button { showHistory=false; visit(p.id) } label: {
                                VStack(alignment:.leading,spacing:4) {
                                    Text(p.title).font(.headline)
                                    Text(p.address).font(.caption).foregroundColor(.secondary)
                                    if let date=entry.date { Text(date,format:.dateTime.month().day().hour().minute()).font(.caption2).foregroundColor(.secondary) }
                                    else { Text("Restored history · date unavailable").font(.caption2).foregroundColor(.secondary) }
                                }
                            }
                        }
                    }
                    if !visibleVisits.isEmpty { Button("Clear history",role:.destructive) { confirmClear=true } }
                }.navigationTitle("History").toolbar {
                    ToolbarItem(placement:.cancellationAction) { Button("Done") { showHistory=false } }
                }.confirmationDialog("Clear browsing history?",isPresented:$confirmClear,titleVisibility:.visible) {
                    Button("Clear history",role:.destructive) { history=""; visitRaw="[]" }
                    Button("Cancel",role:.cancel) {}
                } message: { Text("Bookmarks and investigation progress will be kept.") }
            }
        }
    }
    private func siteSection(_ title:String,_ ids:[String]) -> some View {
        VStack(alignment:.leading,spacing:10) {
            Text(title).font(.headline)
            ForEach(ids.reduce(into:[String]()) { if !$0.contains($1) { $0.append($1) } },id:\.self) { id in
                if let p=LumaWebCatalog.page(id) { Button { visit(id) } label:{ HStack{Text(p.title); Spacer(); Text(p.site).font(.caption).foregroundColor(.secondary)}.padding(10) }.buttonStyle(.plain) }
            }
        }
    }
    private func visit(_ id:String) {
        guard let p=LumaWebCatalog.page(id),p.available(world.state.flags) else{return}
        let old=page?.id ?? home
        if old != p.id { backRaw=encoded(Array((entries(backRaw)+[old]).suffix(50))); forwardRaw="" }
        apply(p.id)
    }
    private func apply(_ id:String) {
        revealed=[]
        if id==home { current=""; query=""; return }
        guard let p=LumaWebCatalog.page(id),p.available(world.state.flags) else{return}
        current=p.id; query=p.address; addressFocused=false; reviewAnswer=""; reviewNotice=""
        visitRaw=LumaBrowserHistory.encode(LumaBrowserHistory.record(p.id,in:visits))
        history=encoded(Array((entries(history).filter{$0 != p.id}+[p.id]).suffix(100)))
        let previouslyVisited = world.state.flags.contains("web.visited." + p.id)
        world.visitWebRecord(p.id)
        if let cue = LumaArchiveAtmosphere.entryCue(pageID: p.id, previouslyVisited: previouslyVisited,
            active: phase == .active && !showHistory, treatment: atmosphere(for: p.id)) {
            // One optional cue on a deliberate first entry. Never queue a
            // haptic or generate a notification just for atmosphere.
            PhoneSensoryEngine.play(cue, sound: messageSound, haptics: false, horrorEnabled: horrorEffects)
        }
    }
    private func showResults(clear:Bool=false) {
        let old=page?.id
        if let old { backRaw=encoded(Array((entries(backRaw)+[old]).suffix(50))); forwardRaw="" }
        current=""; revealed=[]; if clear{query=""}
    }
    private func move(back:Bool) {
        var stack=entries(back ? backRaw:forwardRaw)
        guard let target=stack.popLast() else{return}
        let old=page?.id ?? home
        if back{backRaw=encoded(stack);forwardRaw=encoded(entries(forwardRaw)+[old])}
        else{forwardRaw=encoded(stack);backRaw=encoded(entries(backRaw)+[old])}
        apply(target)
    }
}
