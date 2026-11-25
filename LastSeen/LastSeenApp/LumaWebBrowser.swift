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
    func available(_ flags: Set<String>) -> Bool { gate.map { flags.contains($0) } ?? true }
}
enum LumaWebCatalog {
    static let pages: [LumaWebPage] = [
        .init(id:"books",site:"Maple Street Bookshop",title:"Bookshop",address:"maplebooks.test",symbol:"books.vertical.fill",sections:["Independent books, thoughtful gifts and a quiet place to browse. Open 10–6.","Reservations are held for seven days. Bring your reservation reference to the counter."],links:["books-events","cafe"]),
        .init(id:"books-events",site:"Maple Street Bookshop",title:"Events & reading club",address:"maplebooks.test/events",symbol:"calendar",sections:["Wednesday reading group · 6 PM","This month: mysteries, folklore and stories about places we remember. Ask at the counter about the next meeting."],links:["books"]),
        .init(id:"residents",site:"Ash Street Residents",title:"Resident noticeboard",address:"ashstreet.test",symbol:"building.2.fill",sections:["Welcome to the Ash Street residents' noticeboard.","Elevator inspection pending contractor confirmation. Front entrance and stairs remain available."],links:["residents-services","studio"]),
        .init(id:"residents-services",site:"Ash Street Residents",title:"Building services",address:"ashstreet.test/services",symbol:"wrench",sections:["Building office: Denise Hall.","Maintenance enquiries and parcel collection are handled by the office. Private resident records are not published here."],links:["residents"]),
        .init(id:"cafe",site:"Maple Cafe",title:"Coffee & pastries",address:"maplecafe.test",symbol:"cup.and.saucer.fill",sections:["Espresso, cappuccino, pastries and sandwiches.","Across from the bookshop. Seasonal specials and a quiet corner to work."],links:["cafe-menu","books"]),
        .init(id:"cafe-menu",site:"Maple Cafe",title:"Seasonal menu",address:"maplecafe.test/menu",symbol:"fork.knife",sections:["Vanilla latte · lavender tea · cinnamon pastries","Breakfast and lunch served throughout the day."],links:["cafe"]),
        .init(id:"studio",site:"Blue Hour Interactive",title:"Independent games, personal stories",address:"bluehour.test",symbol:"moon.stars.fill",sections:["A small independent studio in the Ash Street complex.","Nora Bennett leads development. The team works on experimental interactive stories, accessibility and thoughtful game design."],links:["studio-team","studio-projects","studio-notes"]),
        .init(id:"studio-team",site:"Blue Hour Interactive",title:"Meet the studio",address:"bluehour.test/team",symbol:"person.2.fill",sections:["Nora Bennett · Founder / development","Adrian Cole · Technical lead","Tessa Reed · Art and production"],links:["studio","studio-projects"]),
        .init(id:"studio-projects",site:"Blue Hour Interactive",title:"Current projects",address:"bluehour.test/projects",symbol:"gamecontroller.fill",sections:["A work-in-progress psychological horror prototype explores memory, familiar places and unreliable observations.","Development material is not a statement of real events. The team keeps experimental references separate from ordinary project notes."],links:["studio","studio-notes"],images:["Recovered_B27_27","Recovered_B27_29"]),
        .init(id:"studio-notes",site:"Blue Hour Interactive",title:"Development journal",address:"bluehour.test/journal",symbol:"doc.text.fill",sections:["The current build review focuses on accessibility, persistence and visual consistency.","Some older reference records are missing from the current index. A recovered local index may be available after the phone's restoration investigation."],links:["studio","archive"],images:["Recovered_B27_26"]),
        .init(id:"archive",site:"Recovered archive",title:"Local archive index",address:"archive.test",symbol:"archivebox.fill",sections:["This is a cached, incomplete collection. Source claims have not been verified.","Some records may be inaccurate, altered or fictional. Compare them with material already available on the phone."],links:["archive-records","studio-notes"],gate:"investigation.contact.received"),
        .init(id:"archive-records",site:"Recovered archive",title:"Recovered attachments",address:"archive.test/records",symbol:"photo.stack",sections:["Local recovered records. Dates and provenance may be unreliable.","Choose whether to reveal individual images. The text-only inspection option records the same discovery."],links:["archive"],gate:"web.visited.archive",images:["Recovered_B27_02","Recovered_B27_03","Recovered_B27_13","Recovered_B27_18"])
    ]
    static func page(_ id: String) -> LumaWebPage? {
        pages.first { $0.id == id || ($0.address == id) || ($0.site == id && !$0.address.contains("/")) }
    }
    static func visible(_ flags: Set<String>) -> [LumaWebPage] { pages.filter { $0.available(flags) } }
    static func attachments(in flags: Set<String>) -> [String] { visible(flags).flatMap(\.images) }
    static func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in:.whitespacesAndNewlines).lowercased().replacingOccurrences(of:"https://",with:"").replacingOccurrences(of:"http://",with:"").trimmingCharacters(in:CharacterSet(charactersIn:"/"))
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
        ]
    }
    static func summary(_ flags: Set<String>) -> String { "\(steps(flags).filter(\.done).count) completed" }
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
    @State private var showHint = false
    private var steps: [InvestigationProgress.Step] { InvestigationProgress.steps(world.state.flags) }
    var body: some View {
        List {
            Section {
                LumaHeader(title:"Investigation",detail:InvestigationProgress.summary(world.state.flags),symbol:"checklist")
                Text("A record of your discoveries, not a solution guide. New leads appear as you explore.").font(.footnote).foregroundColor(.secondary)
            }
            Section("Completed") {
                if !steps.contains(where: \.done) { Text("No completed leads yet.").foregroundColor(.secondary) }
                ForEach(steps.filter(\.done)) { step in Label(step.title,systemImage:"checkmark.circle.fill").foregroundColor(LumaDesign.accent) }
            }
            Section("Current lead") {
                if let step=steps.first(where:{ !$0.done }) {
                    Label(step.title,systemImage:"magnifyingglass")
                    Button(showHint ? "Hide hint" : "I need a hint") { showHint.toggle() }
                    if showHint {
                        Text(step.hint).foregroundColor(.secondary)
                        Button("Open suggested app") {
                            switch step.route {
                            case "browser": openBrowser()
                            case "messages": openMessages()
                            case "notes": openNotes()
                            default: openFiles()
                            }
                        }
                    }
                } else { Text("All currently documented leads completed. Keep exploring.").foregroundColor(.secondary) }
            }
            if steps.contains(where:{ !$0.done }) {
                Section("Not yet uncovered") { Label("Further leads remain unavailable",systemImage:"lock.fill").foregroundColor(.secondary) }
            }
        }.navigationTitle("Investigation progress").scrollContentBackground(.hidden).background(LumaDesign.background)
    }
}
struct LumaWebBrowser: View {
    let wifi: Bool
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage("lastseen.lab.browserPage") private var current = ""
    @AppStorage("lastseen.lab.browserBackStack") private var backRaw = ""
    @AppStorage("lastseen.lab.browserForwardStack") private var forwardRaw = ""
    @AppStorage("lastseen.lab.history") private var history = ""
    @AppStorage("lastseen.lab.bookmarks") private var bookmarks = ""
    @AppStorage("lastseen.lab.browserSeeded") private var seeded = false
    @State private var query = ""
    @State private var showHint = false
    @State private var revealed: Set<String> = []
    private let home = "@home"
    private var page: LumaWebPage? { LumaWebCatalog.page(current).flatMap { $0.available(world.state.flags) ? $0 : nil } }
    private func entries(_ raw:String) -> [String] { raw.split(separator:"|").map(String.init).compactMap { x in x == home ? home : LumaWebCatalog.page(x).flatMap { $0.available(world.state.flags) ? $0.id : nil } } }
    private func encoded(_ values:[String]) -> String { values.joined(separator:"|") }
    private var matches: [LumaWebPage] {
        let q=LumaWebCatalog.normalized(query)
        return LumaWebCatalog.visible(world.state.flags).filter { p in
            q.isEmpty ? !p.address.contains("/") : (p.address.localizedCaseInsensitiveContains(q) || p.site.localizedCaseInsensitiveContains(q) || p.title.localizedCaseInsensitiveContains(q))
        }
    }
    var body: some View {
        VStack(spacing:0) {
            HStack {
                Image(systemName:"magnifyingglass").foregroundColor(.secondary)
                TextField("Search or enter address",text:$query).textInputAutocapitalization(.never).autocorrectionDisabled().submitLabel(.go)
                    .onSubmit { let q=LumaWebCatalog.normalized(query); if let p=LumaWebCatalog.visible(world.state.flags).first(where:{$0.address==q}) ?? matches.first { visit(p.id) } else { showResults() } }
                if !query.isEmpty { Button { query=""; showResults() } label:{ Image(systemName:"xmark.circle.fill").accessibilityLabel("Clear address") } }
                Button("Go") { let q=LumaWebCatalog.normalized(query); if let p=LumaWebCatalog.visible(world.state.flags).first(where:{$0.address==q}) ?? matches.first { visit(p.id) } else { showResults() } }
            }.padding(12).background(.thinMaterial,in:RoundedRectangle(cornerRadius:16)).padding(10)
            ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    if let p=page {
                        LumaHeader(title:p.site,detail:p.address,symbol:p.symbol)
                        Text(p.title).font(.largeTitle.bold()).fixedSize(horizontal:false,vertical:true)
                        ForEach(Array(p.sections.enumerated()),id:\.offset) { _,paragraph in
                            Text(paragraph).frame(maxWidth:.infinity,alignment:.leading).padding(14).lumaSurface(radius:14)
                        }
                        ForEach(p.images,id:\.self) { asset in
                            VStack(alignment:.leading,spacing:12) {
                                if revealed.contains(asset) && LumaWebCatalog.attachments(in:world.state.flags).contains(asset) {
                                    Image(asset).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius:12)).accessibilityLabel("Recovered image")
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
                            siteSection("History",Array(entries(history).reversed()))
                            if !history.isEmpty { Button("Clear history",role:.destructive){history=""} }
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
                Button {
                    guard let p=page else{return}; var values=entries(bookmarks)
                    if values.contains(p.id){values.removeAll{$0==p.id}} else{values.append(p.id)}
                    bookmarks=encoded(values)
                } label:{ Image(systemName:page.map{entries(bookmarks).contains($0.id)} == true ? "bookmark.fill":"bookmark").accessibilityLabel("Bookmark") }.disabled(page==nil)
            }.font(.title3).padding(.horizontal,25).padding(.vertical,14)
            Text(wifi ? "Local browser · Offline":"Local browser · Wi-Fi off").font(.caption2).foregroundColor(.secondary).padding(.bottom,4)
        }.navigationTitle("Browser").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !seeded { if history.isEmpty { history="cafe|books" }; if bookmarks.isEmpty{bookmarks="books"}; seeded=true }
            if let p=page { current=p.id; query=p.address } else { current="" }
        }
        .onChange(of:world.state.flags) { _ in if page==nil { current=""; revealed=[] } }
    }
    private func siteSection(_ title:String,_ ids:[String]) -> some View {
        VStack(alignment:.leading,spacing:10) {
            Text(title).font(.headline)
            ForEach(Array(Set(ids)).sorted(),id:\.self) { id in
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
        current=p.id; query=p.address
        history=encoded(Array((entries(history).filter{$0 != p.id}+[p.id]).suffix(100)))
        world.visitWebRecord(p.id)
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
