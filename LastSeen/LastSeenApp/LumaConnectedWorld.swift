import Foundation
import SwiftUI

struct LumaMailRecord: Codable, Identifiable, Equatable {
    let id:String
    let peer:String
    let sender:String
    let subject:String
    let body:String
    let date:Date
    let kind:String
    var attachments:[String] = []
}
struct LumaPendingMail: Codable, Equatable {
    var record:LumaMailRecord
    var dueAt:Date
}
enum LumaSocialChannel:String,CaseIterable,Codable,Identifiable {
    case afterframe="Afterframe", connective="Connective", commonGround="CommonGround"
    var id:String {rawValue}
    var icon:String {"Icon_"+rawValue}
    var tagline:String {
        switch self {
        case .afterframe:return "Moments worth keeping"
        case .connective:return "People, work and ideas"
        case .commonGround:return "A place for conversation"
        }
    }
    var accent:Color {
        switch self {
        case .afterframe:return .purple
        case .connective:return .blue
        case .commonGround:return .teal
        }
    }
}
struct LumaSocialPost:Codable,Identifiable,Equatable {
    let id:String
    let channel:LumaSocialChannel
    let author:String
    let handle:String
    let body:String
    let date:Date
    let portrait:String?
    let photo:String?
    let gate:String?
}
struct LumaSocialComment:Codable,Identifiable,Equatable {
    let id:String
    let postID:String
    let author:String
    let body:String
    let date:Date
}
enum LumaSocialAction {case like,save,follow}
struct LumaConnectedState:Codable,Equatable {
    var mail:[LumaMailRecord]=[]
    var pendingMail:[LumaPendingMail]=[]
    var mailFolders:[String:String]=[:]
    var likes:Set<String>=[]
    var savedPosts:Set<String>=[]
    var follows:Set<String>=[]
    var comments:[LumaSocialComment]=[]
    var posts:[LumaSocialPost]=[]
    var socialPreferences: [String: LumaSocialPreferences]? = nil
    var havenWatch: HavenWatchPreferences? = nil
    var activityJournal: [LumaActivityNotice]? = nil
    var pendingSocialReplies: [LumaPendingSocialReply]? = nil
    var workbenchConnected=false
    var workbenchSelections:[String:[String]]=[:]
    var workbenchVerified:Set<String>=[]
}
enum LumaMailCatalog {
    static func recipients(_ world:PhoneWorld)->[Neighbor] {
        Neighbor.visible(in:world).filter{$0 != .unknown}
    }
    static func visible(_ world:PhoneWorld)->[LumaMailRecord] {
        let date=world.createdAt
        let originals=[
            LumaMailRecord(id:"building-update",peer:"denise",sender:"Ash Street Building Office",subject:"Upcoming elevator maintenance",body:"Hello residents,\n\nThis is an advance notice that an elevator inspection is being arranged for this week. We will post the confirmed time in the lobby and notify residents when the contractor has approved the schedule.\n\nThe front entrance and stairwell remain available.\n\nThank you,\nDenise\nBuilding Office",date:date.addingTimeInterval(-3600),kind:"inbox",attachments:["WorldDoc_01_08"]),
            LumaMailRecord(id:"bookstore",peer:"",sender:"Maple Street Bookshop",subject:"Your reservation is ready",body:"Hi Nora,\n\nThe book you reserved is ready for pickup. We'll hold it through the end of the week.\n\nThanks for shopping locally,\nMaple Street Bookshop",date:date.addingTimeInterval(-10800),kind:"inbox",attachments:["WorldDoc_01_10"]),
            LumaMailRecord(id:"building-bulletin",peer:"denise",sender:"Ash Street Neighbors",subject:"Community notice",body:"Hi neighbors,\n\nThe lobby noticeboard has a new calendar for building maintenance and community events. Please check for updates before making plans.\n\nHave a good week,\nAsh Street Neighbors",date:date.addingTimeInterval(-86400),kind:"inbox")
        ]
        guard world.everydayArchiveRevision != nil else{return originals}
        let old=NoraEverydayArchive.mail.map{ item in
            let peer=Neighbor.allCases.first{$0.name==item.sender}?.id ?? ""
            let attachments:[String]
            switch item.id {
            case "b27-studio-qa":attachments=["WorldDoc_01_02"]
            case "b27-art-review":attachments=["WorldDoc_01_03"]
            case "b27-family":attachments=[]
            default:attachments=[]
            }
            return LumaMailRecord(id:item.id,peer:peer,sender:item.sender,subject:item.subject,body:item.body,date:date.addingTimeInterval(item.offset),kind:"inbox",attachments:attachments)
        }
        let work=[
            LumaMailRecord(id:"cw-mail-agenda",peer:"adrian",sender:"Adrian Cole",subject:"Friday review agenda received",body:"I've added the test cable and larger-text checks to my list. The 3 PM review still works for me. Please confirm any changed decisions by email so we have a record.",date:date.addingTimeInterval(-54000),kind:"inbox",attachments:["WorldDoc_01_01"]),
            LumaMailRecord(id:"cw-mail-team",peer:"tessa",sender:"Tessa Reed",subject:"Team working agreement",body:"Thanks for putting the availability rules in writing. I'll keep the palette exports together and send a short summary after Friday. Please don't answer this tonight.",date:date.addingTimeInterval(-210000),kind:"inbox",attachments:["WorldDoc_01_07"]),
            LumaMailRecord(id:"cw-mail-spending",peer:"adrian",sender:"Adrian Cole",subject:"Equipment approval",body:"The existing test cable can get us through the morning, but I've set aside the replacement request. I won't order extra storage until the review is complete.",date:date.addingTimeInterval(-65000),kind:"inbox",attachments:["WorldDoc_01_06"])
        ]
        return (originals+old+work+LivingPhoneHistory.mail(anchor: date)+(world.connectedWorld?.mail ?? [])).sorted{$0.date>$1.date}
    }
    static func response(to peer:Neighbor,subject:String,body:String)->String {
        let words=Set((subject+" "+body).lowercased().split{!$0.isLetter && !$0.isNumber}.map(String.init))
        if !words.isDisjoint(with:["password","passcode","credentials","pin"]) {
            return "Thank you for the message. I cannot authorize private account access by email. Please keep the restored records separate from live accounts.\n\n"+peer.name
        }
        switch peer {
        case .adrian:
            if !words.isDisjoint(with:["build","review","qa","prototype","file","records","document"]) {return "Thanks for getting in touch. The local review documents are the best starting point. Please distinguish an actual test result from a copied reference; I can't confirm material I haven't examined.\n\nAdrian"}
            return "Received. Could you send a little more detail about which studio matter you mean? I don't want to guess.\n\nAdrian"
        case .tessa:
            if !words.isDisjoint(with:["art","palette","review","photos","image","reference"]) {return "Thanks for the update. I've kept the approved palette work separate from the reference intake. If you're looking through Nora's restored files, please keep the original labels intact.\n\nTessa"}
            return "Thanks for writing. I'm still going through the ordinary production handoff. Let me know which record you mean.\n\nTessa"
        case .denise:return "Thank you for contacting the building office. The elevator appointment remains tentative. Please let me know if your enquiry concerns a specific maintenance notice or parcel. I cannot disclose private resident information.\n\nDenise"
        case .maya:return "Thanks for keeping me informed. I wish I had something more useful to tell you. Please let me know how you're getting on with the phone.\n\nMaya"
        case .helen:return "Thank you for writing. I'd rather hear something definite than speculate. Please be careful with her things.\n\nHelen"
        case .lily:return "Thanks for the email. Sorry, I'm a little distracted right now. Please keep Nora's photos safe.\n\nLily"
        case .daniel:return "Received. Please keep a record of what you actually find. I appreciate the update.\n\nDaniel"
        case .unknown:return "Message received."
        }
    }
}
enum LumaSocialCatalog {
    static func visible(_ channel:LumaSocialChannel,world:PhoneWorld)->[LumaSocialPost] {
        guard world.everydayArchiveRevision != nil else{return []}
        let d=world.createdAt
        func post(_ id:String,_ ch:LumaSocialChannel,_ author:String,_ handle:String,_ body:String,_ offset:Double,_ portrait:String?=nil,_ photo:String?=nil,_ gate:String?=nil)->LumaSocialPost {
            LumaSocialPost(id:id,channel:ch,author:author,handle:handle,body:body,date:d.addingTimeInterval(-offset),portrait:portrait,photo:photo,gate:gate)
        }
        let base=[
            post("af-01",.afterframe,"Nora Bennett","nora.b","A little moment from my camera roll. Trying to remember to stop and enjoy the day.",98000,"Nora_Profile","Nora_Photo_01"),
            post("af-02",.afterframe,"Maya Brooks","maya.b","Coffee soon, please. I need a reason to get out of the house that isn't groceries.",145000,"Contact_Maya"),
            post("af-03",.afterframe,"Lily Bennett","lily.b","Borrowing outfit inspiration again. Apparently I am not allowed to call it theft.",220000,"Contact_B27_03"),
            post("af-04",.afterframe,"Nora Bennett","nora.b","Weekend goal: read an entire chapter without checking my laptop.",320000,"Nora_Profile","Nora_Photo_02"),
            post("co-01",.connective,"Blue Hour Interactive","bluehour","Internal prototype review this Friday. Our focus is accessibility, persistence and visual consistency before release.",70000),
            post("co-02",.connective,"Adrian Cole","adrian.c","A reliable save is worth more than a beautiful demo that cannot resume.",125000,"Contact_B27_06"),
            post("co-03",.connective,"Tessa Reed","tessa.r","Testing a palette on the same device is more useful than comparing screenshots at different brightness levels.",156000,"Contact_B27_07"),
            post("co-04",.connective,"Nora Bennett","nora.b","We are a small team. A realistic schedule and a proper review are more important than pretending to ship early.",260000,"Nora_Profile"),
            post("cg-01",.commonGround,"Maple Street Bookshop","maplebooks","Wednesday reading group at six. Everyone is welcome; no purchase required.",130000),
            post("cg-02",.commonGround,"Ash Street Residents","ashstreet","Elevator inspection is still awaiting confirmation. Please use the front entrance and stairs as usual.",39000),
            post("cg-03",.commonGround,"Maple Cafe","maplecafe","Fresh cinnamon pastries at the counter today. The window seats are open.",82000),
            post("cg-04",.commonGround,"Adrian Cole","adrian.c","Anyone else keeping a separate note for original capture dates and imported copies? It saves a surprising amount of confusion.",190000,"Contact_B27_06")
        ]
        return (base+LivingPhoneHistory.posts(anchor: d)+LumaSocialCommunity.posts(anchor: d)+(world.connectedWorld?.posts ?? [])).filter{$0.channel==channel && ($0.gate.map{world.flags.contains($0)} ?? true)}.sorted{$0.date>$1.date}
    }
    static func comments(_ postID: String, channel: LumaSocialChannel, world: PhoneWorld) -> [LumaSocialComment] {
        guard let post = visible(channel, world: world).first(where: { $0.id == postID }) else { return [] }
        return (LivingPhoneHistory.comments(for: post) + (world.connectedWorld?.comments ?? []).filter { $0.postID == postID }).sorted { $0.date < $1.date }
    }
    static func visiblePhoto(_ post:LumaSocialPost,world:PhoneWorld)->String? {
        guard world.everydayArchiveRevision != nil, post.gate.map({ world.flags.contains($0) }) ?? true else { return nil }
        if let media = LumaSocialCommunity.publicPhoto(post) { return media }
        guard let id=post.photo,let record=NoraPhotoCatalog.photos.first(where:{$0.id==id}),!record.privateAlbum,
              record.available(flags:NoraPhotoCatalog.discoveryFlags(from:world.flags)) else{return nil}
        return id
    }
}

enum WorkbenchChallenge:String,CaseIterable,Identifiable {
    case routing, integrity
    var id:String{rawValue}
    var title:String{self == .routing ? "Service routing" : "Integrity reconstruction"}
    var instructions:String {
        self == .routing ? "Connect the read-only input to the verified index, then the index to the output. Choose two compatible links." : "Choose the two fragments that share the same record identifier and revision. Ignore the newer unrelated fragment."
    }
    var options:[String] {
        self == .routing ? ["Read-only input → Index","Index → Output","Output → Input","Unverified module → Output"] : ["Record K · revision 2 · header","Record M · revision 3 · body","Record K · revision 2 · body","Record K · revision 1 · body"]
    }
    var required:Int{2}
    func valid(_ choices:[String])->Bool {
        guard choices.count==2,Set(choices).count==2 else{return false}
        return self == .routing ? Set(choices)==Set(options.prefix(2)) : Set(choices)==Set([options[0],options[2]])
    }
}

struct LumaConnectedMailView:View {
    @EnvironmentObject private var world:PhoneWorldStore
    @AppStorage("lastseen.restored.mail.read") private var readRaw=""
    @State private var folder="inbox"
    @State private var query=""
    @State private var compose=false
    @AppStorage("lastseen.relay.installed") private var relayInstalled=""
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    private var attachmentsAvailable:Bool {RelayCatalog.tweakActive("mailattach",installed:relayInstalled,safeMode:safeMode,flags:world.state.flags)}
    private var folders:[String] {["inbox","sent","draft","archive","trash"]+(attachmentsAvailable ? ["attachments"]:[])}
    private var read:Set<String>{Set(readRaw.split(separator:"|").map(String.init))}
    private var items:[LumaMailRecord]{
        LumaMailCatalog.visible(world.state).filter {
            (folder=="attachments" ? attachmentsAvailable && world.connected.mailFolders[$0.id] != "trash" && $0.attachments.contains{WorldDocumentCatalog.available($0,world:world.state)} : (world.connected.mailFolders[$0.id] ?? $0.kind)==folder) &&
            (query.isEmpty || [$0.subject,$0.sender,$0.body].contains{$0.localizedCaseInsensitiveContains(query)})
        }
    }
    var body:some View {
        List {
            LumaHeader(title:"Mail",detail:"Restored correspondence",symbol:"envelope.fill").listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            Picker("Mailbox",selection:$folder){ForEach(folders,id:\.self){Text($0=="draft" ? "Drafts" : $0.capitalized).tag($0)}}.pickerStyle(.menu)
            if items.isEmpty {Text("No messages in this mailbox").foregroundColor(.secondary)}
            ForEach(items){item in
                NavigationLink {
                    if item.kind=="draft" {
                        LumaMailComposer(existing:item)
                    } else {
                        LumaMailDetail(id:item.id)
                    }
                } label:{
                    VStack(alignment:.leading,spacing:5){
                        HStack {
                            if item.kind=="inbox" && !item.id.hasPrefix("b32-mail-") && !read.contains(item.id) {Circle().fill(Color.blue).frame(width:8,height:8)}
                            Text(item.kind=="sent" || item.kind=="draft" ? "To: "+(Neighbor(rawValue:item.peer)?.name ?? item.peer) : item.sender).font(.headline)
                            Spacer()
                            Text(item.date,style:.date).font(.caption2).foregroundColor(.secondary)
                        }
                        Text(item.subject.isEmpty ? "(No subject)" : item.subject).font(.subheadline.weight(.medium))
                        Text(item.body).lineLimit(2).font(.caption).foregroundColor(.secondary)
                    }.padding(.vertical,5)
                }
            }
            if !world.connected.pendingMail.isEmpty {Label("Correspondence pending",systemImage:"clock").font(.caption).foregroundColor(.secondary)}
        }.navigationTitle("Mail").searchable(text:$query,prompt:"Search mail")
            .toolbar{ToolbarItem(placement:.navigationBarTrailing){Button{compose=true}label:{Image(systemName:"square.and.pencil").accessibilityLabel("Compose mail")}}}
            .sheet(isPresented:$compose){NavigationStack{LumaMailComposer()}.environmentObject(world)}
    }
}
struct LumaMailDetail:View {
    let id:String
    @EnvironmentObject private var world:PhoneWorldStore
    @AppStorage("lastseen.restored.mail.read") private var readRaw=""
    @State private var reply=false
    @State private var forward=false
    private var item:LumaMailRecord?{LumaMailCatalog.visible(world.state).first{$0.id==id}}
    var body:some View {
        ScrollView{
            if let item {
                VStack(alignment:.leading,spacing:16){
                    Text(item.subject).font(.largeTitle.bold()).fixedSize(horizontal:false,vertical:true)
                    Text("From: "+item.sender).font(.headline)
                    Text(item.date,format:.dateTime.month().day().hour().minute()).font(.caption).foregroundColor(.secondary)
                    Divider()
                    Text(item.body).textSelection(.enabled).fixedSize(horizontal:false,vertical:true)
                    ForEach(item.attachments,id:\.self){id in
                        if let doc=WorldDocumentCatalog.document(id,world:world.state) {
                            NavigationLink {WorldDocumentReader(id:doc.id)}label:{Label(doc.title,systemImage:"paperclip").padding(10).lumaSurface(radius:12)}
                        }
                    }
                    HStack{
                        if let peer=Neighbor(rawValue:item.peer),LumaMailCatalog.recipients(world.state).contains(peer){Button("Reply"){reply=true}.buttonStyle(.borderedProminent)}
                        Button("Forward"){forward=true}.buttonStyle(.bordered)
                    }
                    HStack{
                        Button("Archive"){world.moveConnectedMail(id,folder:"archive")}
                        Button("Trash",role:.destructive){world.moveConnectedMail(id,folder:"trash")}
                        if world.connected.mailFolders[id] != nil {Button("Restore"){world.moveConnectedMail(id,folder:"original")}}
                    }.font(.subheadline)
                }.frame(maxWidth:.infinity,alignment:.leading).padding(20)
            }else{Text("Message unavailable").padding()}
        }.navigationTitle("Message").navigationBarTitleDisplayMode(.inline)
            .onAppear{
                if item?.kind=="inbox" {var ids=Set(readRaw.split(separator:"|").map(String.init));ids.insert(id);readRaw=ids.sorted().joined(separator:"|")}
            }
            .sheet(isPresented:$reply){NavigationStack{if let item {LumaMailComposer(recipient:Neighbor(rawValue:item.peer),initialSubject:item.subject.hasPrefix("Re:") ? item.subject : "Re: "+item.subject)}}.environmentObject(world)}
            .sheet(isPresented:$forward){NavigationStack{if let item{LumaMailComposer(initialSubject:"Fwd: "+item.subject,initialBody:"\n\nForwarded local message:\n"+item.sender+"\n"+item.body)}}.environmentObject(world)}
    }
}
struct LumaMailComposer:View {
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.dismiss) private var dismiss
    @State private var peer:Neighbor?
    @State private var subject:String
    @State private var message:String
    @State private var notice=""
    private let draftID:String?
    init(existing:LumaMailRecord?=nil,recipient:Neighbor?=nil,initialSubject:String="",initialBody:String=""){
        draftID=existing?.id
        _peer=State(initialValue:existing.flatMap{Neighbor(rawValue:$0.peer)} ?? recipient)
        _subject=State(initialValue:existing?.subject ?? initialSubject)
        _message=State(initialValue:existing?.body ?? initialBody)
    }
    var body:some View {
        Form{
            Section("From"){Text("Repair desk · Local correspondence").font(.subheadline)}
            Section("To"){Picker("Recipient",selection:$peer){Text("Choose contact").tag(Optional<Neighbor>.none);ForEach(LumaMailCatalog.recipients(world.state)){contact in Text(contact.name).tag(Optional(contact))}}}
            Section("Subject"){TextField("Subject",text:$subject)}
            Section("Message"){TextEditor(text:$message).frame(minHeight:180)}
            Section{
                Button("Send local message"){
                    if let peer,world.sendConnectedMail(draftID:draftID,peer:peer,subject:subject,body:message){dismiss()}else{notice="Could not send. Check recipient, subject and message."}
                }.disabled(peer==nil || subject.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || message.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                Button("Save draft"){if let peer,world.saveMailDraft(id:draftID,peer:peer,subject:subject,body:message) != nil{dismiss()}else{notice="Could not save draft."}}.disabled(peer==nil)
                if !notice.isEmpty{Text(notice).foregroundColor(.secondary)}
                Text("Messages are fictional, local to Last Seen, and sent as the repair desk, not as Nora.").font(.footnote).foregroundColor(.secondary)
            }
        }.navigationTitle("Compose").toolbar{ToolbarItem(placement:.cancellationAction){Button("Cancel"){dismiss()}}}
    }
}

struct LumaSocialView:View {
    let channel:LumaSocialChannel
    @EnvironmentObject private var world:PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var relayInstalled=""
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    private var timestamps:Bool {RelayCatalog.tweakActive("socialtime",installed:relayInstalled,safeMode:safeMode,flags:world.state.flags)}
    @State private var query=""
    @State private var filter="Feed"
    @State private var compose=false
    @State private var draft=""
    @State private var feedback=""
    private var posts:[LumaSocialPost]{
        LumaSocialCatalog.visible(channel,world:world.state).filter{p in
            (filter == "Saved" || !world.socialPreferences(channel).mutedAuthors.contains(p.author)) &&
            (filter != "Saved" || world.connected.savedPosts.contains(p.id)) &&
            (filter != "Following" || world.connected.follows.contains(channel.rawValue+"|"+p.author)) &&
            (query.isEmpty || [p.author,p.handle,p.body].contains{$0.localizedCaseInsensitiveContains(query)})
        }
    }
    var body:some View{
        ScrollView{
            LazyVStack(alignment:.leading,spacing:16){
                HStack(spacing:12){
                    Image(channel.icon).resizable().scaledToFit().frame(width:56,height:56).clipShape(RoundedRectangle(cornerRadius:15))
                    VStack(alignment:.leading,spacing:4){Text(channel.rawValue).font(.largeTitle.bold());Text(channel.tagline).font(.caption).foregroundColor(.secondary)}
                    Spacer()
                }
                Picker("View",selection:$filter){ForEach(["Feed","Following","Saved"],id:\.self){Text($0).tag($0)}}.pickerStyle(.segmented)
                if posts.isEmpty{Text("Nothing to display").foregroundColor(.secondary).padding()}
                ForEach(posts){post in
                    VStack(alignment:.leading,spacing:12){
                        HStack(spacing:9){
                            LumaSocialAvatar(post: post, size: 42)
                            NavigationLink{LumaSocialProfile(channel:channel,author:post.author)}label:{
                                VStack(alignment:.leading,spacing:3){Text(post.author).font(.headline);Text("@"+post.handle).font(.caption).foregroundColor(.secondary)}
                            }.buttonStyle(.plain)
                            Spacer()
                            if timestamps {Text(post.date,format:.dateTime.month().day().hour().minute()).font(.caption2).foregroundColor(.secondary)}
                            else {Text(post.date,style:.date).font(.caption2).foregroundColor(.secondary)}
                        }
                        Text(post.body).font(.body).textSelection(.enabled)
                        if let photo=LumaSocialCatalog.visiblePhoto(post,world:world.state){
                            Image(photo).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius:12))
                        }
                        Divider()
                        HStack{
                            Button{world.toggleSocial(.like,postID:post.id,channel:channel)}label:{Label("Like",systemImage:world.connected.likes.contains(post.id) ? "heart.fill":"heart")}.foregroundColor(world.connected.likes.contains(post.id) ? .pink:.secondary)
                            Spacer()
                            NavigationLink{LumaSocialDiscussion(channel:channel,postID:post.id)}label:{Label("Comments (\(LumaSocialCatalog.comments(post.id, channel: channel, world: world.state).count))",systemImage:"bubble.left")}
                            Spacer()
                            Button{world.toggleSocial(.save,postID:post.id,channel:channel)}label:{Image(systemName:world.connected.savedPosts.contains(post.id) ? "bookmark.fill":"bookmark").accessibilityLabel("Save post")}
                        }.font(.subheadline).buttonStyle(.plain)
                    }.padding(16).lumaSurface(radius:18)
                }
            }.padding(16)
        }.navigationTitle(channel.rawValue).navigationBarTitleDisplayMode(.inline).searchable(text:$query)
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink { LumaSocialAccountView(channel: channel) } label: { Image(systemName: "person.crop.circle").accessibilityLabel("Account and settings") }
                }
                ToolbarItem(placement:.navigationBarTrailing){Button{compose=true}label:{Image(systemName:"square.and.pencil").accessibilityLabel("Compose post")}}
            }
            .sheet(isPresented:$compose){
                NavigationStack{
                    Form{
                        Text("Posting locally as Repair desk, not as Nora.").font(.subheadline)
                        TextEditor(text:$draft).frame(minHeight:180)
                        Button("Publish local post"){if world.publishSocial(channel:channel,text:draft){draft="";compose=false;feedback=""}else{feedback="Enter a shorter message."}}
                        if !feedback.isEmpty{Text(feedback).foregroundColor(.secondary)}
                    }.navigationTitle("New post").toolbar{ToolbarItem(placement:.cancellationAction){Button("Cancel"){compose=false}}}
                }.environmentObject(world)
            }
    }
}
struct LumaSocialProfile:View{
    let channel:LumaSocialChannel
    let author:String
    @EnvironmentObject private var world:PhoneWorldStore
    private var posts:[LumaSocialPost]{LumaSocialCatalog.visible(channel,world:world.state).filter{$0.author==author}}
    var body:some View{
        List{
            if let first=posts.first{
                Section {
                    HStack(spacing: 14) {
                        LumaSocialAvatar(post: first, size: 64)
                        VStack(alignment: .leading, spacing: 4) { Text(author).font(.title2.bold()); Text("@" + first.handle).foregroundColor(.secondary) }
                    }
                    if let bio = LumaSocialCommunity.bio(author: author, channel: channel) { Text(bio) }
                    LabeledContent("Restored posts", value: String(posts.count))
                }
                if author != "Nora Bennett" && author != "Repair desk" {
                    Button(world.socialPreferences(channel).mutedAuthors.contains(author) ? "Unmute profile" : "Mute profile") { world.toggleSocialMute(author, channel: channel) }
                }
                Button(world.connected.follows.contains(channel.rawValue+"|"+author) ? "Unfollow":"Follow"){world.toggleSocial(.follow,postID:first.id,channel:channel)}
                let media = posts.filter { LumaSocialCatalog.visiblePhoto($0, world: world.state) != nil }
                if !media.isEmpty {
                    Section("Photos") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                            ForEach(media) { post in
                                if let asset = LumaSocialCatalog.visiblePhoto(post, world: world.state) {
                                    NavigationLink { LumaSocialDiscussion(channel: channel, postID: post.id) } label: {
                                        GeometryReader { geometry in
                                            Image(asset).resizable().scaledToFill()
                                                .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                                        }.aspectRatio(1, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 5))
                                    }.buttonStyle(.plain).accessibilityLabel("Open photo post: " + post.body)
                                }
                            }
                        }
                    }
                }
                Section("Posts"){ForEach(posts){post in NavigationLink{LumaSocialDiscussion(channel:channel,postID:post.id)}label:{VStack(alignment:.leading){Text(post.body);Text(post.date,style:.date).font(.caption).foregroundColor(.secondary)}}}}
            }else{Text("Profile unavailable")}
        }.navigationTitle("Profile")
    }
}
struct LumaSocialDiscussion:View{
    let channel:LumaSocialChannel
    let postID:String
    @EnvironmentObject private var world:PhoneWorldStore
    @State private var text=""
    @State private var error=""
    var body:some View{
        List{
            if let post=LumaSocialCatalog.visible(channel,world:world.state).first(where:{$0.id==postID}){
                Section {
                    HStack(spacing: 10) { LumaSocialAvatar(post: post, size: 42); Text(post.author).font(.headline) }
                    Text(post.body)
                    if let photo = LumaSocialCatalog.visiblePhoto(post, world: world.state) {
                        Image(photo).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                Section("Comments"){
                    let comments=LumaSocialCatalog.comments(postID,channel:channel,world:world.state)
                    if comments.isEmpty{Text("No restored comments").foregroundColor(.secondary)}
                    ForEach(comments){c in VStack(alignment:.leading){Text(c.author).font(.headline);Text(c.body);Text(c.date,style:.time).font(.caption).foregroundColor(.secondary)}}
                }
                Section("Repair desk"){
                    TextField("Write a local comment",text:$text,axis:.vertical)
                    Button("Post comment"){if world.commentSocial(postID:postID,channel:channel,text:text){text="";error=""}else{error="Comment not saved."}}.disabled(text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                    if !error.isEmpty{Text(error).foregroundColor(.secondary)}
                }
            }else{Text("Post unavailable")}
        }.navigationTitle("Discussion")
    }
}

struct LumaWorkbenchView:View{
    @EnvironmentObject private var world:PhoneWorldStore
    let openRelay:()->Void
    let openFiles:()->Void
    @AppStorage("lastseen.relay.installed") private var relayInstalled=""
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    private var metrics:Bool {RelayCatalog.tweakActive("workbenchmetrics",installed:relayInstalled,safeMode:safeMode,flags:world.state.flags)}
    var body:some View{
        ScrollView{
            VStack(alignment:.leading,spacing:16){
                LumaHeader(title:"Repair Workstation",detail:"Local service console",symbol:"desktopcomputer")
                VStack(alignment:.leading,spacing:12){
                    Label(world.connected.workbenchConnected ? "Device connected":"No device connected",systemImage:world.connected.workbenchConnected ? "checkmark.circle.fill":"cable.connector").font(.headline).foregroundColor(world.connected.workbenchConnected ? LumaDesign.accent:.secondary)
                    Text("Simulated connection to the restored phone. No physical computer or cable is required.").font(.caption).foregroundColor(.secondary)
                    Button(world.connected.workbenchConnected ? "Disconnect device":"Connect device"){world.setWorkbenchConnection(!world.connected.workbenchConnected)}.buttonStyle(.borderedProminent)
                }.frame(maxWidth:.infinity,alignment:.leading).padding(16).lumaSurface()
                if world.connected.workbenchConnected{
                    LabeledContent("Restore index",value:"Available")
                    if metrics {
                        LabeledContent("Readable records",value:String(WorldDocumentCatalog.visible(world.state).count+PhonePublicFiles.available(in:world.state).count))
                        LabeledContent("Installed optional packages",value:String(RelayCatalog.ids(relayInstalled).count))
                    }
                    LabeledContent("Completed diagnostics",value:String(world.connected.workbenchVerified.count))
                    Button(action:openFiles){Label("Inspect restored files",systemImage:"folder")}.buttonStyle(.bordered)
                    ForEach(WorkbenchChallenge.allCases){challenge in
                        NavigationLink{LumaWorkbenchChallengeView(challenge:challenge)}label:{
                            LumaHeader(title:challenge.title,detail:world.connected.workbenchVerified.contains(challenge.rawValue) ? "Verified":"Ready for inspection",symbol:challenge == .routing ? "point.3.connected.trianglepath.dotted":"doc.on.doc")
                        }.buttonStyle(.plain)
                    }
                    NavigationLink{RecoveryCircuitView()}label:{LumaHeader(title:"Recovery Circuit",detail:"Existing Patchline service verification",symbol:"cpu")}.buttonStyle(.plain)
                    Button(action:openRelay){LumaHeader(title:"Package preparation",detail:"Review authorized packages in Relay",symbol:"shippingbox.fill")}.buttonStyle(.plain)
                }
            }.padding(18)
        }.navigationTitle("Workstation")
    }
}
struct LumaWorkbenchChallengeView:View{
    let challenge:WorkbenchChallenge
    @EnvironmentObject private var world:PhoneWorldStore
    @State private var feedback=""
    private var selected:[String]{world.connected.workbenchSelections[challenge.rawValue] ?? []}
    var body:some View{
        List{
            if world.connected.workbenchConnected{
                Section{Text(challenge.instructions)}
                Section("Select two"){
                    ForEach(challenge.options,id:\.self){option in
                        Button{
                            var next=selected
                            if next.contains(option){next.removeAll{$0==option}}else if next.count<challenge.required{next.append(option)}
                            world.setWorkbenchSelection(next,for:challenge);feedback=""
                        }label:{HStack{Image(systemName:selected.contains(option) ? "checkmark.circle.fill":"circle");Text(option)}}
                    }
                }
                Section{
                    Button("Verify"){feedback=world.verifyWorkbench(challenge) ? "Diagnostic verified.":"The selected records do not match. No changes were applied."}.disabled(selected.count != challenge.required)
                    Button("Clear selection"){world.setWorkbenchSelection([],for:challenge);feedback=""}
                    if !feedback.isEmpty{Text(feedback).foregroundColor(.secondary)}
                    if world.connected.workbenchVerified.contains(challenge.rawValue){Label("Verified",systemImage:"checkmark.seal.fill").foregroundColor(LumaDesign.accent)}
                }
            }else{Text("Reconnect the simulated phone first.")}
        }.navigationTitle(challenge.title)
    }
}
