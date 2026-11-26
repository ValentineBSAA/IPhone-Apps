import SwiftUI
import UIKit

/// Fictional historical material, separate from live conversations.
enum VeilArchive {
    static let discovery = "web.visited.veil-guide"
    static let contactName = "Unknown Number"
    static func authorized(_ world: PhoneWorld) -> Bool {
        world.everydayArchiveRevision != nil && ["phone-tutorial-finished","web.visited.archive",discovery].allSatisfy { world.flags.contains($0) }
    }
    static func installed(_ world: PhoneWorld, packages: String, safeMode: Bool) -> Bool {
        authorized(world) && RelayCatalog.tweakActive("veil", installed: packages, safeMode: safeMode, flags: world.flags)
    }
    struct Message: Identifiable {
        let id: String
        let day: Int
        let fromNora: Bool
        let text: String
        var attachment: String? = nil
    }
    private static let transcript: [Message] = [
        .init(id:"v01",day:14,fromNora:false,text:"A copy for your collection.",attachment:"Nora_Archive_08"),
        .init(id:"v02",day:14,fromNora:true,text:"I don't know this number. Who is this?"),
        .init(id:"v03",day:13,fromNora:true,text:"Please stop sending me things."),
        .init(id:"v04",day:12,fromNora:false,text:"Another reference.",attachment:"Nora_Archive_09"),
        .init(id:"v05",day:12,fromNora:true,text:"This isn't funny. I didn't agree to any of this."),
        .init(id:"v06",day:10,fromNora:false,text:"You have not answered.",attachment:"Nora_Archive_10"),
        .init(id:"v07",day:10,fromNora:true,text:"Answered what? None of your messages make sense."),
        .init(id:"v08",day:9,fromNora:true,text:"I am keeping these messages. Don't contact me again."),
        .init(id:"v09",day:8,fromNora:false,text:"[Recovered message incomplete]",attachment:"Nora_Archive_11"),
        .init(id:"v10",day:8,fromNora:true,text:"I don't understand what you're asking me to give up."),
        .init(id:"v11",day:6,fromNora:false,text:"The reference is still here.",attachment:"Nora_Archive_05"),
        .init(id:"v12",day:6,fromNora:true,text:"No. I won't agree to anything. Leave me alone."),
        .init(id:"v13",day:4,fromNora:false,text:"[Attachment recovered; original text unavailable]",attachment:"Nora_Archive_06"),
        .init(id:"v14",day:4,fromNora:true,text:"I have asked someone for help."),
        .init(id:"v15",day:2,fromNora:false,text:"[Attachment recovered; original text unavailable]",attachment:"Nora_Archive_07"),
        .init(id:"v16",day:2,fromNora:true,text:"I'm not discussing this with you anymore.")
    ]
    static func messages(_ world: PhoneWorld) -> [Message] { authorized(world) ? transcript : [] }
    static func date(_ message: Message, in world: PhoneWorld) -> Date {
        world.createdAt.addingTimeInterval(-Double(message.day)*86400)
    }
    struct Page: Identifiable {
        let id: String
        let title: String
        let text: String
        var address: String { "veil://" + id }
    }
    private static let catalog: [Page] = [
        .init(id:"directory",title:"Local directory",text:"Recovered offline index. Some archived sources are incomplete."),
        .init(id:"boards",title:"Discussion boards",text:"Cached discussions refer to missing copies and disputed archive entries. A matching username does not establish a person's identity."),
        .init(id:"records",title:"Correspondence cache",text:"An older message export is available in the restored phone. Keep original correspondence distinct from copied media."),
        .init(id:"media",title:"Recovered media",text:"Reference copies only. Their appearance, origin and capture dates are not authenticated. Some images may be unsettling.")
    ]
    static func pages(_ world: PhoneWorld) -> [Page] { authorized(world) ? catalog : [] }
    static func media(_ world: PhoneWorld) -> [String] {
        authorized(world) ? (1...11).map { String(format:"Nora_Archive_%02d",$0) } : []
    }
}
struct VeilRecoveredImage: View {
    let asset: String
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @State private var revealed = false
    var body: some View {
        if VeilArchive.media(world.state).contains(asset) {
            VStack(alignment:.leading,spacing:8) {
                if revealed && phase == .active {
                    if let image = UIImage(named:asset) {
                        Image(uiImage:image).resizable().scaledToFit().accessibilityLabel("Recovered fictional photograph, origin unverified")
                    } else { Text("Image unavailable. Text remains accessible.").font(.caption) }
                }
                Button(revealed ? "Hide image" : "Reveal recovered image") {
                    revealed.toggle()
                    if revealed, UIImage(named:asset) != nil { world.recordVeilObservation(asset) }
                }.buttonStyle(.bordered)
                Text("Unverified reference image").font(.caption2).foregroundColor(.secondary)
            }.onChange(of:phase) { if $0 != .active { revealed = false } }.onDisappear { revealed = false }
        }
    }
}
struct VeilHistoricalConversation: View {
    @EnvironmentObject private var world: PhoneWorldStore
    var body: some View {
        ScrollView {
            if VeilArchive.authorized(world.state) {
                VStack(spacing:14) {
                    Image(systemName:"person.crop.circle.badge.questionmark").font(.system(size:48)).foregroundColor(.secondary)
                    Text(VeilArchive.contactName).font(.title2.bold())
                    Text("Recovered historical conversation · Read-only").font(.caption).foregroundColor(.secondary)
                    Text("Contains references to harassment and unwanted photographs. Images remain hidden until revealed.").font(.caption).foregroundColor(.secondary)
                    ForEach(VeilArchive.messages(world.state)) { message in
                        VStack(alignment:message.fromNora ? .trailing : .leading,spacing:5) {
                            Text(VeilArchive.date(message,in:world.state),format:.dateTime.month().day()).font(.caption2).foregroundColor(.secondary)
                            Text(message.text).padding(12).background(message.fromNora ? Color.teal.opacity(0.28) : Color.secondary.opacity(0.15),in:RoundedRectangle(cornerRadius:14))
                            if let asset = message.attachment { VeilRecoveredImage(asset:asset) }
                        }.frame(maxWidth:.infinity,alignment:message.fromNora ? .trailing : .leading)
                    }
                    Text("End of recovered correspondence. Not a live contact.").font(.caption).foregroundColor(.secondary)
                }.padding(18)
            } else { Text("Conversation unavailable").padding() }
        }.navigationTitle("Recovered conversation").navigationBarTitleDisplayMode(.inline)
            .onAppear { world.recordVeilCorrespondenceOpened() }
    }
}
struct VeilBrowser: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.relay.installed") private var packages = ""
    @AppStorage("lastseen.relay.safeMode") private var safeMode = false
    @State private var connected = false
    @State private var address = ""
    @State private var selected = "directory"
    @State private var notice = ""
    @State private var history: [String] = []
    @State private var bookmarks: Set<String> = []
    private var allowed: Bool { VeilArchive.installed(world.state,packages:packages,safeMode:safeMode) }
    private var pages: [VeilArchive.Page] { VeilArchive.pages(world.state) }
    private func visit(_ raw: String) {
        guard allowed,connected,phase == .active else { return }
        guard let p = pages.first(where:{$0.address == raw || $0.id == raw}) else { notice = "Address unavailable in this local archive."; return }
        if selected != p.id { history.append(selected); history = Array(history.suffix(30)) }
        selected = p.id; address = p.address; notice = ""
    }
    var body: some View {
        ScrollView {
            if allowed {
                VStack(alignment:.leading,spacing:18) {
                    HStack {
                        if UIImage(named:"Icon_Veil") != nil { Image("Icon_Veil").resizable().scaledToFit().frame(width:56,height:56) }
                        else { Image(systemName:"eye.slash").font(.largeTitle) }
                        VStack(alignment:.leading) {
                            Text("V E I L").font(.title.bold())
                            Text(connected ? "Local session connected" : "Local session disconnected").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    Text("Fictional anonymous browser. All pages are bundled offline.").font(.caption).foregroundColor(.secondary)
                    Button(connected ? "Disconnect session" : "Connect local session") {
                        connected.toggle()
                        if connected { selected = "directory"; address = "veil://directory" }
                        else { address = ""; history = []; notice = "" }
                    }.buttonStyle(.borderedProminent).tint(.purple)
                    if connected {
                        HStack {
                            TextField("Local address",text:$address).textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder).submitLabel(.go).onSubmit { visit(address) }
                            Button("Go") { visit(address) }
                        }
                        HStack {
                            Button("Back") {
                                if let previous = history.popLast(),let p = pages.first(where:{$0.id == previous}) { selected = p.id; address = p.address; notice = "" }
                            }.disabled(history.isEmpty)
                            Spacer()
                            Button(bookmarks.contains(selected) ? "Remove bookmark" : "Bookmark") {
                                if bookmarks.contains(selected) { bookmarks.remove(selected) } else { bookmarks.insert(selected) }
                            }
                        }.font(.caption)
                        if !notice.isEmpty { Text(notice).font(.caption).foregroundColor(.secondary) }
                        if let page = pages.first(where:{$0.id == selected}) {
                            Text(page.title).font(.title2.bold())
                            Text(page.text)
                            if page.id == "records" {
                                NavigationLink { VeilHistoricalConversation() } label: { Label("Open recovered correspondence",systemImage:"message") }
                            }
                            if page.id == "media" {
                                ForEach(VeilArchive.media(world.state),id:\.self) { asset in VeilRecoveredImage(asset:asset).padding(10).lumaSurface() }
                            }
                        }
                        ForEach(pages) { page in
                            Button { visit(page.id) } label: {
                                HStack { Text(page.title); Spacer(); if bookmarks.contains(page.id) { Image(systemName:"bookmark.fill") }; Image(systemName:"chevron.right") }.padding(12).lumaSurface(radius:12)
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(18)
            } else { Text("Application unavailable").padding() }
        }.tint(.purple).navigationTitle("VEIL").navigationBarTitleDisplayMode(.inline)
            .onChange(of:phase) { if $0 != .active { connected = false; address = ""; history = [] } }
            .onChange(of:allowed) { if !$0 { connected = false; address = ""; history = []; bookmarks = [] } }
            .onDisappear { connected = false; history = [] }
    }
}
