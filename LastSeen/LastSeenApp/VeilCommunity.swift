import SwiftUI

enum VeilCommunity {
    struct Board: Identifiable {
        let id:String
        let title:String
        let detail:String
    }
    struct Reply: Identifiable {
        let id:String
        let author:String
        let text:String
    }
    struct Thread: Identifiable {
        let id:String
        let boardID:String
        let title:String
        let author:String
        let daysAgo:Int
        let text:String
        let replies:[Reply]
        let gate:String?
    }
    static let boards:[Board] = [
        .init(id:"lost-media",title:"Lost media",detail:"Incomplete recordings and abandoned pages"),
        .init(id:"after-hours",title:"After hours",detail:"Ordinary conversations and strange familiarity"),
        .init(id:"boundaries",title:"Boundaries",detail:"Privacy and consent"),
        .init(id:"index-room",title:"Index room",detail:"Revisions and disputed copies")
    ]
    static let handles:Set<String> = ["tapeghost","paperindex","moth","greyrelay","stillframe","null","lowlight","hush","cinder","inkveil","saltline"]
    private static func make(_ board:String,_ id:String,_ title:String,_ author:String,_ days:Int,_ text:String,_ replies:[(String,String)],gate:String? = nil) -> Thread {
        .init(id:id,boardID:board,title:title,author:author,daysAgo:days,text:text,replies:replies.enumerated().map { i,r in .init(id:id+"-"+String(i),author:r.0,text:r.1) },gate:gate)
    }
    static let disputedThreads = ["first-copy","second-copy"]
    static func revisionAvailable(_ world:PhoneWorld)->Bool {
        VeilReferences.homeIndexReady(world) &&
        world.flags.contains(VeilReferences.marker(VeilReferences.homeIndexID)) &&
        world.flags.contains("veil.home-index.opened")
    }
    static func disputeAvailable(_ world:PhoneWorld)->Bool {
        revisionAvailable(world) && disputedThreads.allSatisfy { world.flags.contains(openedMarker($0)) }
    }
    static let disputeMarker = "veil.revision-dispute.reviewed"
    static func disputeReviewed(_ world:PhoneWorld)->Bool {
        disputeAvailable(world) && world.flags.contains(disputeMarker)
    }
    static let disputeOptions = [
        "The two accounts disagree about when the collection label changed.",
        "Both accounts establish the original capture date.",
        "The matching language confirms a single author."
    ]
    static func acceptsDispute(_ answer:Int,in world:PhoneWorld)->Bool {
        disputeAvailable(world) && answer == 0
    }
    static let disputeNote = "The accounts assign different revision stages to the same label. Neither establishes the original capture date or author. The disagreement remains useful evidence of an unreliable archive."
    private static let all:[Thread] = [
        make("lost-media","quiet-tapes","A room with no soundtrack","tapeghost",38,"The archive entry has room tone, then nothing. I remember a different ending, but my copy is incomplete.",[("paperindex","My index lists an incomplete recording too."),("moth","The silence is the part that stays with me."),("greyrelay","Marking this as incomplete, not a confirmed alternate version.")]),
        make("lost-media","empty-pages","Pages that outlive their sites","paperindex",31,"Sometimes an old page survives after the rest of a site is gone. Missing context can change the way a sentence reads.",[("tapeghost","Especially when the date belongs to the copy."),("stillframe","I keep those fields separate."),("greyrelay","Please label reconstructed text.")]),
        make("lost-media","broken-title","The thumbnail without a title","stillframe",22,"There is a thumbnail in an old index with no caption. I don't recognize the scene.",[("moth","Familiarity isn't the same as remembering."),("paperindex","The index doesn't give enough context."),("null","An empty field is still a field.")]),
        make("after-hours","night-shift","Anyone else awake?","moth",36,"The house is quiet and I have been listening to the rain. Tell me something completely ordinary.",[("lowlight","I made toast and forgot to butter it."),("hush","My plant has finally grown a new leaf."),("tapeghost","I found an old song I had forgotten about.")]),
        make("after-hours","unfamiliar","Familiar places, unfamiliar feeling","lowlight",27,"A place can feel strange when you visit at a different time. Memory changes the atmosphere.",[("hush","Sometimes the lighting is all that changed."),("moth","And sometimes you're just tired."),("stillframe","A feeling isn't evidence.")]),
        make("after-hours","unfinished","A page with the last sentence missing","hush",17,"I keep revisiting an unfinished entry. It is probably less interesting than whatever I imagined in its place.",[("moth","The imagined ending is usually louder."),("null","It is unfinished."),("lowlight","That is enough of an answer for me tonight.")]),
        make("boundaries","consent","A copy isn't permission","cinder",29,"Finding something in an archive does not mean its subject agreed to share it.",[("inkveil","I wish more boards kept that distinction clear."),("greyrelay","Personal contact details and requests for private material are not accepted."),("hush","Some things are better left unshared.")]),
        make("boundaries","unwanted","An unwanted message","inkveil",19,"Someone mentioned an unwanted message in another discussion. We don't have permission to reproduce the exchange.",[("cinder","A person can refuse contact without explaining why."),("greyrelay","No identifying details."),("lowlight","We can acknowledge something is unsettling without guessing who sent it.")]),
        make("boundaries","recovered-correspondence","An incomplete correspondence record","cinder",3,"The restored index refers to an incomplete correspondence export. It is not an invitation to contact anyone.",[("inkveil","The original context matters more than a username."),("null","A label is not a name."),("greyrelay","No identity claim has been verified.")],gate:"veil.correspondence.opened"),
        make("index-room","revision","Revision labels","saltline",24,"Two exports can carry different revision labels while referring to the same collection.",[("paperindex","The date on a copy is not necessarily the original date."),("stillframe","I've seen indexes where a label was missing."),("greyrelay","Unverified origin remains unverified.")]),
        make("index-room","maintenance","Archive maintenance notice","greyrelay",13,"This is a partial snapshot. Some pages were removed before the cache was made. Empty entries are intentionally retained.",[("saltline","Please leave the blanks visible."),("paperindex","An absence shouldn't become a fabricated record."),("null","Not everything was retained.")]),
        make("index-room","image-index","An entry without a capture date","stillframe",2,"One recovered reference has no authenticated capture date. The entry cannot establish its original source.",[("saltline","The message date and capture date are different fields."),("cinder","A photograph is not permission to identify or contact its subject."),("greyrelay","Source remains unverified.")],gate:"veil.viewed.Nora_Archive_08"),
        make("after-hours","ordinary-hours","The ordinary ones","lowlight",6,"Everyone wants something dramatic. I like the quiet pictures better. Someone in their own world, not performing for anybody. It feels almost like being invited in.",[("hush","Almost is doing a lot of work there."),("lowlight","You know what I mean. The ordinary moments feel more personal."),("cinder","You weren't invited. That is the difference.")],gate:"veil.viewed.Nora_Archive_08"),
        make("after-hours","favorite-frame","A favorite frame?","moth",5,"Somebody keeps talking about the woman in the recovered pictures as though they know her. I can't tell whether it's a joke anymore.",[("lowlight","I have a favorite. She looks comfortable, like she wouldn't expect anyone to be looking."),("stillframe","You're talking about a person, not a character in a collection."),("hush","That reply made this whole thread feel different.")],gate:"veil.viewed.Nora_Archive_08"),
        make("boundaries","not-a-relationship","That isn't familiarity","inkveil",4,"Reading the same archive over and over doesn't mean the person in it knows you. Stop calling the photographs a relationship.",[("lowlight","I never said she knew me. I just like the idea that I know a side of her other people don't."),("cinder","That's entitlement, not affection."),("greyrelay","Thread retained as a historical copy. No contact requests or additional private material.")],gate:"veil.viewed.Nora_Archive_08"),
        make("index-room","first-copy","Before the label changed","paperindex",8,"My saved index already called it a personal collection before the revision. I remember the label changing afterward.",[("saltline","My copy doesn't agree with that order."),("lowlight","The old label felt more honest to me."),("null","A remembered label is not the original file.")],gate:"veil.home-index.opened"),
        make("index-room","second-copy","The other revision","saltline",7,"The earlier index I retained says reference copies. The personal collection label appears later in my notes, not earlier.",[("paperindex","Then one of us retained a different revision."),("stillframe","Neither copy contains a confirmed capture date."),("greyrelay","The original author field is missing in both accounts.")],gate:"veil.home-index.opened")
    ]
    static func visible(_ world:PhoneWorld) -> [Thread] {
        guard VeilArchive.authorized(world),VeilReferences.inspected("board-reference",in:world) != nil else { return [] }
        return all.filter { thread in
            (thread.gate.map { world.flags.contains($0) } ?? true) &&
            (!disputedThreads.contains(thread.id) || revisionAvailable(world))
        }
    }
    static func thread(_ id:String,in world:PhoneWorld) -> Thread? { visible(world).first{$0.id == id} }
    static func openedMarker(_ id:String) -> String { "veil.thread.opened."+id }
    static func opened(_ world:PhoneWorld) -> [Thread] { visible(world).filter{world.flags.contains(openedMarker($0.id))} }
    static func date(_ thread:Thread,in world:PhoneWorld) -> Date { world.createdAt.addingTimeInterval(-Double(thread.daysAgo)*86400) }
    static func bookmarkIDs(_ world:PhoneWorld) -> Set<String> {
        (world.connectedWorld?.veilThreadBookmarks ?? []).intersection(Set(visible(world).map(\.id)))
    }
}

struct VeilCommunityView:View {
    @EnvironmentObject private var world:PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var packages=""
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    @State private var query=""
    @State private var savedOnly=false
    private var allowed:Bool { VeilArchive.installed(world.state,packages:packages,safeMode:safeMode) }
    var body:some View {
        List {
            if allowed {
                Section {
                    Toggle("Saved threads",isOn:$savedOnly)
                    Text("Archived discussions · read-only · handles unverified").font(.caption).foregroundColor(.secondary)
                }
                ForEach(VeilCommunity.boards) { board in
                    let threads=VeilCommunity.visible(world.state).filter {
                        $0.boardID == board.id && (!savedOnly || VeilCommunity.bookmarkIDs(world.state).contains($0.id)) &&
                        (query.isEmpty || [$0.title,$0.text,$0.author].contains{$0.localizedCaseInsensitiveContains(query)})
                    }.sorted{$0.daysAgo < $1.daysAgo}
                    if !threads.isEmpty {
                        Section {
                            ForEach(threads) { thread in
                                NavigationLink { VeilThreadView(id:thread.id) } label: {
                                    VStack(alignment:.leading,spacing:5) {
                                        Text(thread.title).font(.headline)
                                        Text(thread.author+" · "+String(thread.replies.count)+" replies").font(.caption).foregroundColor(.secondary)
                                        Text(VeilCommunity.date(thread,in:world.state),style:.date).font(.caption2).foregroundColor(.secondary)
                                    }
                                }
                            }
                        } header: { Text(board.title) } footer: { Text(board.detail) }
                    }
                }
            } else { Text("Archive unavailable") }
        }.navigationTitle("Discussion boards").searchable(text:$query).tint(.purple)
    }
}

struct VeilThreadView:View {
    let id:String
    @EnvironmentObject private var world:PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var packages=""
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    private var allowed:Bool { VeilArchive.installed(world.state,packages:packages,safeMode:safeMode) }
    var body:some View {
        List {
            if allowed,let thread=VeilCommunity.thread(id,in:world.state) {
                Section {
                    Text(thread.title).font(.title2.bold())
                    Text(thread.author+" · archived handle").font(.caption).foregroundColor(.secondary)
                    Text(thread.text).textSelection(.enabled)
                    Button(VeilCommunity.bookmarkIDs(world.state).contains(id) ? "Remove bookmark" : "Save thread") {
                        world.toggleVeilThreadBookmark(id,packages:packages,safeMode:safeMode)
                    }
                }
                Section("Archived replies") {
                    ForEach(thread.replies) { reply in
                        VStack(alignment:.leading,spacing:8) {
                            Text(reply.author).font(.caption.bold()).foregroundColor(.purple)
                            Text(reply.text).textSelection(.enabled)
                        }.padding(.vertical,4)
                    }
                }
                if VeilCommunity.disputedThreads.contains(id) {
                    NavigationLink { VeilDisputeReviewView() } label: {
                        Label("Review conflicting accounts",systemImage:"arrow.left.arrow.right")
                    }
                }
                Text("No verified identities or live posting.").font(.caption).foregroundColor(.secondary)
            } else { Text("Thread unavailable") }
        }.navigationTitle("Archived thread").navigationBarTitleDisplayMode(.inline)
            .onAppear { world.recordVeilThreadOpened(id,packages:packages,safeMode:safeMode) }
    }
}

struct VeilDisputeReviewView:View {
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.relay.installed") private var packages=""
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    @State private var choice:Int?
    @State private var notice=""
    var body:some View {
        List {
            if VeilArchive.installed(world.state,packages:packages,safeMode:safeMode),
               VeilCommunity.revisionAvailable(world.state),phase == .active {
                ForEach(VeilCommunity.disputedThreads,id:\.self) { id in
                    if let thread=VeilCommunity.thread(id,in:world.state) {
                        NavigationLink { VeilThreadView(id:id) } label: {
                            Label(thread.title,systemImage:world.state.flags.contains(VeilCommunity.openedMarker(id)) ? "checkmark.circle":"circle")
                        }
                    }
                }
                if VeilCommunity.disputeReviewed(world.state) {
                    Section("Recorded observation"){
                        Text(VeilCommunity.disputeNote)
                        Text("Revisit the saved home security archive and compare its source labels with the recovered copies.").font(.caption).foregroundColor(.secondary)
                        NavigationLink { HavenWatchView() } label: { Label("Open HavenWatch",systemImage:"shield.lefthalf.filled") }
                    }
                } else if VeilCommunity.disputeAvailable(world.state) {
                    Section("What do the accounts establish?") {
                        ForEach(VeilCommunity.disputeOptions.indices,id:\.self) { i in
                            Button { choice=i;notice="" } label: {
                                Label(VeilCommunity.disputeOptions[i],systemImage:choice==i ? "largecircle.fill.circle":"circle")
                            }.buttonStyle(.plain)
                        }
                        Button("Record conclusion") {
                            guard let choice,phase == .active else{return}
                            notice=world.recordVeilDispute(choice,packages:packages,safeMode:safeMode) ? "Observation recorded." : "Revisit the wording of both accounts."
                        }.buttonStyle(.borderedProminent).disabled(choice==nil)
                        if !notice.isEmpty {Text(notice).font(.caption)}
                    }
                } else {Text("Read both recovered accounts before recording a conclusion.").font(.caption)}
            } else {Text("Review unavailable.")}
        }.navigationTitle("Conflicting accounts")
        .onChange(of:phase){if $0 != .active {choice=nil;notice=""}}
        .onChange(of:VeilCommunity.disputeAvailable(world.state)){if !$0 {choice=nil;notice=""}}
    }
}
