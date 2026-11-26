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
        var address: String {
            let hosts = [
                "directory":"k7v3m2q5j6w4n7xb3t2p5h6r4z7c2f5d6y3g4s7k2q5m6v3j4n7x",
                "boards":"b4q7s2j5m6z3v4n7w2r5k6x3g4c7t2h5p6d3y4f7b2q5s6j3m4z",
                "records":"p6h3r7c2f5d4y6g3s7k2q5m4v6j3n7x2b5t4w6z3r7h2p5c4f6d",
                "media":"t2w5z6r3h4p7c2f5d6y3g4s7k2q5m6v3j4n7x2b5t6w3z4r7h",
                "fragment-04":"f4k7m2x5c6v3r4p7y2b5t6j3w4q7n2s5g6h3z4d7f2k5m6x3c4v",
                "home-index":"m4x7q2v5b6t3h4r7p2z5k6s3w4n7c2f5d6j3g4y7q2v5m6x3b4t7"
            ]
            return "veil://"+(hosts[id] ?? "unavailable")+".invalid/"+id
        }
    }
    private static let catalog: [Page] = [
        .init(id:"directory",title:"Local directory",text:"Recovered offline index. Some archived sources are incomplete."),
        .init(id:"boards",title:"Discussion boards",text:"Cached discussions refer to missing copies and disputed archive entries. A matching username does not establish a person's identity."),
        .init(id:"records",title:"Correspondence cache",text:"An older message export is available in the restored phone. Keep original correspondence distinct from copied media."),
        .init(id:"media",title:"Recovered media",text:"Reference copies only. Their appearance, origin and capture dates are not authenticated. Some images may be unsettling.")
    ]
    static func pages(_ world: PhoneWorld) -> [Page] {
        guard authorized(world) else { return [] }
        var result=catalog.filter{$0.id != "boards" || VeilReferences.inspected("board-reference",in:world) != nil}
        if VeilReferences.inspected("private-index-reference",in:world) != nil {
            result.append(.init(id:"fragment-04",title:"Recovered index fragment",text:"Partial index. The original source is disputed. Compare the available record with the restored browser's review ledger rather than assume the archive is a complete account."))
        }
        if VeilReferences.inspected(VeilReferences.homeIndexID,in:world) != nil {
            result.append(.init(id:"home-index",title:"Secondary revision cache",text:"Two labels appear on the recovered index: an earlier personal collection label and a later reference-copy label. The revision note says the images were regrouped, not newly captured. The original author field is blank. A later annotation uses familiar language, but no signature survives. Compare the correspondence and archive ledger before drawing conclusions."))
        }
        return result
    }
    static func isHidden(_ id:String)->Bool { ["fragment-04","home-index"].contains(id) }
    static func directoryPages(_ world:PhoneWorld)->[Page] { pages(world).filter{!isHidden($0.id) || pageBookmarkIDs(world).contains($0.id)} }
    static func resolve(_ raw:String,in world:PhoneWorld)->Page? {
        let value=raw.trimmingCharacters(in:.whitespacesAndNewlines)
        return pages(world).first { $0.address == value || (!isHidden($0.id) && ($0.id == value || "veil://"+$0.id == value)) }
    }
    static func pageBookmarkIDs(_ world:PhoneWorld)->Set<String> {
        (world.connectedWorld?.veilPageBookmarks ?? []).intersection(Set(pages(world).map(\.id)))
    }
    static func allowsImages(_ security:String)->Bool { ["Standard","Safer"].contains(security) }
    static func backTarget(_ history:[String],in world:PhoneWorld)->(Page?,[String]) {
        let valid=Dictionary(uniqueKeysWithValues:pages(world).map{($0.id,$0)})
        var remaining=Array(history.filter{valid[$0] != nil}.suffix(30))
        guard let id=remaining.popLast() else{return (nil,remaining)}
        return (valid[id],remaining)
    }
    // The home cache is separate from authenticated camera snapshots.
    static let homeAssets = (1...6).map { String(format:"VEIL_Home_%02d",$0) }
    static let homeDescriptions: [String:String] = [
        "VEIL_Home_01":"Food preparation at a white kitchen island.",
        "VEIL_Home_02":"Laptop use beside a beige sectional and wooden coffee table.",
        "VEIL_Home_03":"A paperback and mug at a kitchen island.",
        "VEIL_Home_04":"A balcony with string lights and a city skyline at dusk.",
        "VEIL_Home_05":"A person resting on a beige sofa with a mug.",
        "VEIL_Home_06":"Plant care beside a living room television."
    ]
    static func homeMedia(_ world:PhoneWorld) -> [String] {
        guard authorized(world), world.flags.contains("veil.correspondence.opened"),
              world.flags.contains("veil.viewed.Nora_Archive_08") else { return [] }
        let reviewed = world.connectedWorld?.recoveredImageReviews ?? []
        let first = Array(homeAssets.prefix(3))
        let advanced = first.prefix(2).allSatisfy {
            world.flags.contains("veil.viewed."+$0) && reviewed.contains($0)
        }
        return advanced ? homeAssets : first
    }
    static func mediaTitle(_ asset:String,in world:PhoneWorld)->String? {
        guard let index=media(world).firstIndex(of:asset) else{return nil}
        return "Recovered photograph "+String(index+1)
    }
    static func media(_ world: PhoneWorld) -> [String] {
        guard authorized(world) else { return [] }
        return (1...11).map { String(format:"Nora_Archive_%02d",$0) } + homeMedia(world)
    }
}
struct VeilRecoveredImage: View {
    let asset: String
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @State private var revealed = false
    @State private var revealEpoch:UUID?
    @AppStorage("lastseen.veil.security") private var security = "Standard"
    private var currentReveal:Bool {revealed && revealEpoch==world.checkpointEpoch}
    var body: some View {
        if VeilArchive.media(world.state).contains(asset) {
            VStack(alignment:.leading,spacing:8) {
                Text(VeilArchive.mediaTitle(asset,in:world.state) ?? "Recovered photograph").font(.headline)
                if currentReveal && phase == .active && VeilArchive.allowsImages(security) {
                    if let image = UIImage(named:asset) {
                        Image(uiImage:image).resizable().scaledToFit().accessibilityLabel("Recovered fictional photograph, origin unverified")
                    } else { Text("Image unavailable. Text remains accessible.").font(.caption) }
                }
                if VeilArchive.allowsImages(security) {
                    Button(currentReveal ? "Hide image" : "Reveal recovered image") {
                        guard phase == .active,VeilArchive.allowsImages(security),
                              VeilArchive.media(world.state).contains(asset) else { return }
                        revealed = !currentReveal
                        revealEpoch = revealed ? world.checkpointEpoch : nil
                        if revealed, UIImage(named:asset) != nil { world.recordVeilObservation(asset) }
                    }.buttonStyle(.bordered)
                } else { Label("Image hidden by security preference",systemImage:"shield").font(.caption) }
                Text("Unverified reference image").font(.caption2).foregroundColor(.secondary)
                if RecoveredImageAnalysis.record(asset,in:world.state) != nil {
                    if let description=VeilArchive.homeDescriptions[asset] {
                        Text(description).font(.caption).foregroundColor(.secondary)
                    }
                    if RecoveredImageAnalysis.completed(asset,in:world.state) {
                        Label("Source review recorded",systemImage:"checkmark.circle").font(.caption)
                    }
                    NavigationLink { RecoveredImageAnalysisView(asset:asset) } label:{
                        Label("Analyze image",systemImage:"viewfinder")
                    }.buttonStyle(.bordered)
                    SendImageToLumaButton(asset:asset)
                } else {
                    Button("Inspect text only"){
                        guard phase == .active else{return}
                        world.recordVeilObservation(asset)
                    }.font(.caption)
                }
            }.onChange(of:phase) { if $0 != .active { revealed = false;revealEpoch=nil } }
                .onChange(of:security) { _ in revealed = false;revealEpoch=nil }
                .onChange(of:world.checkpointEpoch) { _ in revealed=false;revealEpoch=nil }
                .onDisappear { revealed = false;revealEpoch=nil }
        }
    }
}
struct VeilHistoricalConversation: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    private func markOpened(){if phase == .active && VeilArchive.authorized(world.state){world.recordVeilCorrespondenceOpened()}}
    var body: some View {
        ScrollView {
            if phase == .active,VeilArchive.authorized(world.state) {
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
            .onAppear {markOpened()}
            .onChange(of:phase){if $0 == .active {markOpened()}}
    }
}
struct VeilBrowser: View {
    var initialReference:String? = nil
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.relay.installed") private var packages = ""
    @AppStorage("lastseen.relay.safeMode") private var safeMode = false
    @State private var connected = false
    @State private var connecting = false
    @State private var connectionStep = 0
    @State private var didOpenInitial = false
    @AppStorage("lastseen.lab.wifi") private var wifi = true
    @State private var routeGeneration = 1
    @State private var showNewIdentity = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("lastseen.lab.horrorEffects") private var horrorEffects = true
    @AppStorage("lastseen.lab.atmosphereIntensity") private var atmosphereIntensity = LumaArchiveAtmosphere.Intensity.standard.rawValue
    @State private var atmosphereOwner = UUID()
    @AppStorage("lastseen.veil.security") private var security = "Standard"
    @AppStorage("lastseen.lab.messageSound") private var messageSound = true
    @State private var address = ""
    @State private var selected = "directory"
    @State private var notice = ""
    @State private var history: [String] = []
    @State private var pageSession=UUID()
    @FocusState private var addressFocused:Bool
    private var bookmarks:Set<String> { VeilArchive.pageBookmarkIDs(world.state) }
    private var allowed: Bool { VeilArchive.installed(world.state,packages:packages,safeMode:safeMode) }
    private var pages: [VeilArchive.Page] { VeilArchive.pages(world.state) }
    private var treatment:LumaArchiveAtmosphere.Treatment? {
        guard !showNewIdentity else { return nil }
        return LumaArchiveAtmosphere.veilTreatment(pageID:selected,world:world.state,
            installed:packages,safeMode:safeMode,connected:connected,active:phase == .active,
            wifi:wifi,security:security,intensity:LumaArchiveAtmosphere.Intensity(rawValue:atmosphereIntensity) ?? .off,
            enabled:horrorEffects,reduceMotion:reduceMotion)
    }
    private func recordIndex() {
        guard selected == "home-index",allowed,connected,wifi,phase == .active else { return }
        let previous=world.state.flags.contains("veil.home-index.opened")
        world.recordVeilHomeIndexOpened()
        if let cue=LumaArchiveAtmosphere.indexRecordingCue(previouslyRecorded:previous,
            recorded:world.state.flags.contains("veil.home-index.opened"),treatment:treatment,
            intensity:LumaArchiveAtmosphere.Intensity(rawValue:atmosphereIntensity) ?? .off,security:security) {
            PhoneSensoryEngine.playOptionalAtmosphere(cue, owner: atmosphereOwner,sound:messageSound,horrorEnabled:horrorEffects)
        }
    }
    private func disconnect() {
        PhoneSensoryEngine.stopOptionalAtmosphere(owner: atmosphereOwner)
        connecting=false; connected=false; connectionStep=0; address=""; history=[]; notice=""
        selected="directory";pageSession=UUID();addressFocused=false
    }
    private func visit(_ raw: String) {
        guard allowed,connected,wifi,phase == .active else { return }
        guard let p = VeilArchive.resolve(raw,in:world.state) else {
            notice = raw.hasPrefix("veil://") ? "Service unreachable in this recovered directory." : "Invalid local service address. VEIL does not open external sites."
            return
        }
        if selected != p.id {
            PhoneSensoryEngine.stopOptionalAtmosphere(owner: atmosphereOwner)
            history.append(selected); history = Array(history.suffix(30));pageSession=UUID()
        }
        selected = p.id; address = p.address; notice = "";addressFocused=false
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
                            Text(connected ? "Local session connected" : connecting ? "Establishing local session" : "Local session disconnected").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    Text("Fictional anonymous browser. All pages are bundled offline.").font(.caption).foregroundColor(.secondary)
                    Button(connected ? "Disconnect session" : connecting ? "Cancel connection" : "Connect local session") {
                        if connected || connecting { disconnect(); return }
                        guard wifi else { notice="Simulated Wi-Fi is off."; return }
                        guard phase == .active else { return }
                        notice=""; connectionStep=0; connecting=true
                    }.buttonStyle(.borderedProminent).tint(.purple)
                    if connecting {
                        ProgressView(value:Double(connectionStep),total:3)
                        Text(["Preparing local session","Checking cached directory","Opening local route","Ready"][min(3,connectionStep)]).font(.caption)
                    }
                    if !connected && !notice.isEmpty { Text(notice).font(.caption).foregroundColor(.secondary) }
                    if connected && wifi && phase == .active {
                        DisclosureGroup("Session privacy") {
                            LabeledContent("Local circuit",value:"Session "+String(routeGeneration))
                            Picker("Security level",selection:$security) {
                                ForEach(["Standard","Safer","Safest"],id: \.self) { Text($0) }
                            }
                            Text("Simulated security preference. Safest displays text instead of archive images; no actual encryption or network routing takes place.").font(.caption).foregroundColor(.secondary)
                            Button("New circuit for this page") {
                                routeGeneration = routeGeneration >= 999 ? 1 : routeGeneration+1
                                notice = "Local circuit refreshed. Current page retained."
                            }
                            Button("New identity") { showNewIdentity = true }
                        }.padding(12).lumaSurface()
                        HStack {
                            TextField("Local address",text:$address).textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder).submitLabel(.go).focused($addressFocused).onSubmit { visit(address) }
                            Button("Go") { visit(address) }
                        }
                        HStack {
                            Button("Back") {
                                let (target,remaining)=VeilArchive.backTarget(history,in:world.state)
                                history=remaining
                                if let p=target {selected=p.id;address=p.address;notice="";pageSession=UUID();addressFocused=false}
                            }.disabled(history.isEmpty)
                            Spacer()
                            Button(bookmarks.contains(selected) ? "Remove bookmark" : "Bookmark") {
                                world.toggleVeilPageBookmark(selected,packages:packages,safeMode:safeMode)
                            }
                        }.font(.caption)
                        if !notice.isEmpty { Text(notice).font(.caption).foregroundColor(.secondary) }
                        if let page = pages.first(where:{$0.id == selected}) {
                            Text(page.title).font(.title2.bold())
                            Text(page.text)
                            if page.id == "boards" {
                                NavigationLink { VeilCommunityView() } label: { Label("Browse archived boards",systemImage:"text.bubble") }
                            }
                            if page.id == "records" {
                                NavigationLink { VeilHistoricalConversation() } label: { Label("Open recovered correspondence",systemImage:"message") }
                            }
                            if page.id == "home-index" {
                                Button("Record recovered index") { recordIndex() }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(world.state.flags.contains("veil.home-index.opened"))
                                if world.state.flags.contains("veil.home-index.opened") {
                                    NavigationLink { VeilDisputeReviewView() } label: {
                                        Label("Read related accounts",systemImage:"text.bubble")
                                    }
                                    NavigationLink { EvidenceComparisonView(initialRecordID:"veil:home-index") } label: {
                                        Label("Compare index with opened records",systemImage:"rectangle.split.2x1")
                                    }
                                }
                            }
                            if page.id == "media" {
                                if !VeilArchive.homeMedia(world.state).isEmpty {
                                    NavigationLink { EvidenceComparisonView() } label: {
                                        Label("Compare opened archive records",systemImage:"rectangle.split.2x1")
                                    }
                                    if VeilReferences.homeIndexReady(world.state) {
                                        NavigationLink { VeilReferenceReader(id:VeilReferences.homeIndexID) } label:{
                                            Label("Open recovered Files reference",systemImage:"doc.badge.ellipsis")
                                        }
                                    } else if VeilArchive.homeMedia(world.state).count < 6 {
                                        let initial=VeilArchive.homeAssets.prefix(2)
                                        let completed=initial.filter{RecoveredImageAnalysis.completed($0,in:world.state)}.count
                                        Text("Initial home-copy reviews: "+String(completed)+" of "+String(initial.count)+". Review the first two home copies to recover more material.").font(.caption)
                                    } else {
                                        Text("Compare a reviewed home copy's description with the opened discussion about ordinary moments.").font(.caption)
                                        if VeilCommunity.thread("ordinary-hours",in:world.state) != nil {
                                            NavigationLink { VeilThreadView(id:"ordinary-hours") } label:{
                                                Label("Open related archived discussion",systemImage:"text.bubble")
                                            }
                                        } else if VeilReferences.visible(world.state).contains(where:{$0.id=="board-reference"}) {
                                            NavigationLink { VeilReferenceReader(id:"board-reference") } label:{
                                                Label("Inspect discussion bookmark",systemImage:"doc.badge.ellipsis")
                                            }
                                        }
                                    }
                                }
                                if !VeilArchive.allowsImages(security) {Label("Images hidden at this security level",systemImage:"shield").font(.caption)}
                                VStack(spacing:12) {
                                    ForEach(VeilArchive.media(world.state),id:\.self){asset in VeilRecoveredImage(asset:asset).padding(10).lumaSurface()}
                                }.id(pageSession)
                            }
                        }
                        ForEach(VeilArchive.directoryPages(world.state)) { page in
                            Button { visit(page.address) } label: {
                                HStack { Text(page.title); Spacer(); if bookmarks.contains(page.id) { Image(systemName:"bookmark.fill") }; Image(systemName:"chevron.right") }.padding(12).lumaSurface(radius:12)
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(18)
            } else { Text("Application unavailable").padding() }
        }.tint(.purple).navigationTitle("VEIL").navigationBarTitleDisplayMode(.inline)
            .overlay {
                if let treatment {
                    LumaArchiveEdgeTreatment(opacity: treatment.edgeOpacity)
                }
            }
            .confirmationDialog("Start a new local identity?",isPresented:$showNewIdentity,titleVisibility:.visible) {
                Button("Clear session",role:.destructive) {
                    guard allowed,connected,wifi,phase == .active else{return}
                    history=[];selected="directory";address=VeilArchive.resolve("directory",in:world.state)?.address ?? "";notice="";pageSession=UUID();addressFocused=false
                    routeGeneration = routeGeneration >= 999 ? 1 : routeGeneration+1
                }
                Button("Cancel",role:.cancel) {}
            } message: { Text("Clears temporary browsing history. Saved threads and investigation progress remain.") }
            .task(id:connecting) {
                guard connecting else { return }
                for step in 1...3 {
                    do { try await Task.sleep(nanoseconds:250_000_000) } catch { return }
                    guard !Task.isCancelled,connecting,allowed,wifi,phase == .active else { return }
                    connectionStep=step
                }
                connected=true; connecting=false
                selected="directory"; address=VeilArchive.resolve("directory",in:world.state)?.address ?? ""
                if !didOpenInitial,let initialReference {
                    didOpenInitial=true
                    if let target=VeilReferences.target(initialReference,in:world.state) { visit(target.address) }
                    else { notice="Recovered reference unavailable." }
                }
            }
            .onChange(of:world.checkpointEpoch) { _ in
                disconnect(); atmosphereOwner=UUID(); showNewIdentity=false
            }
            .onChange(of:phase) { if $0 != .active { disconnect() } }
            .onChange(of:allowed) { if !$0 { disconnect() } }
            .onChange(of:pages.map(\.id)) { _ in
                guard allowed,connected else{return}
                let valid=Set(pages.map(\.id))
                history=history.filter{valid.contains($0)}
                if !valid.contains(selected) {
                    selected="directory";pageSession=UUID()
                    address=VeilArchive.resolve("directory",in:world.state)?.address ?? ""
                    notice="This recovered service is no longer available."
                }
            }
            .onChange(of:wifi) { if !$0 { disconnect(); notice="Simulated Wi-Fi is off." } }
            .onChange(of:selected) { _ in PhoneSensoryEngine.stopOptionalAtmosphere(owner: atmosphereOwner) }
            .onChange(of:showNewIdentity) { if $0 { PhoneSensoryEngine.stopOptionalAtmosphere(owner: atmosphereOwner) } }
            .onChange(of:security) { _ in PhoneSensoryEngine.stopOptionalAtmosphere(owner: atmosphereOwner) }
            .onChange(of:messageSound) { if !$0 { PhoneSensoryEngine.stopOptionalAtmosphere(owner: atmosphereOwner) } }
            .onChange(of:treatment) { if $0 == nil { PhoneSensoryEngine.stopOptionalAtmosphere(owner: atmosphereOwner) } }
            .onChange(of:atmosphereIntensity) { if $0 != LumaArchiveAtmosphere.Intensity.standard.rawValue { PhoneSensoryEngine.stopOptionalAtmosphere(owner: atmosphereOwner) } }
            // A push into a board, correspondence or image workspace is
            // still part of this local session. The parent state is discarded
            // when its navigation entry is removed; cancel unfinished connects.
            .onDisappear {
                PhoneSensoryEngine.stopOptionalAtmosphere(owner: atmosphereOwner)
                if connecting { disconnect() }
            }
    }
}
