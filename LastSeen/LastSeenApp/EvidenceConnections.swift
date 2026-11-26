import SwiftUI
import Foundation
import UIKit

/// Optional player-authored links between already opened records. Store only
/// stable references and a bounded observation type, never copied private text.
struct EvidenceConnection: Codable, Equatable, Identifiable {
    enum Relation: String, Codable, CaseIterable, Identifiable {
        case source, chronology, wording, uncertainty
        var id: String { rawValue }
        var title: String {
            switch self {
            case .source: return "Compare origins"
            case .chronology: return "Compare dates or order"
            case .wording: return "Compare descriptions"
            case .uncertainty: return "Keep an open question"
            }
        }
    }
    let first: String
    let second: String
    let relation: Relation
    var id: String { first + "|" + second }
    static func make(_ a: String,_ b: String,relation: Relation,in world: PhoneWorld) -> Self? {
        canonical(a,b,relation:relation,visible:Set(LumaAssistantEvidence.visible(world).map(\.id)))
    }
    private static func canonical(_ a:String,_ b:String,relation:Relation,visible:Set<String>)->Self? {
        guard a != b, !a.contains("|"), !b.contains("|"),
              a.count <= 200,b.count <= 200 else{return nil}
        let ids=[a,b].sorted()
        guard ids.allSatisfy({visible.contains($0)}) else{return nil}
        return .init(first:ids[0],second:ids[1],relation:relation)
    }
    /// Retain temporarily hidden comparisons without exposing their contents.
    /// Access is still enforced by visible() and make().
    static let capacity=40
    /// Canonical storage only; no visibility checks or recursive gate calls.
    /// Every dependency predicate must use the same first occurrence policy.
    static func stored(_ world:PhoneWorld)->[Self] {
        var seen=Set<String>()
        return (world.connectedWorld?.evidenceConnections ?? []).prefix(capacity).compactMap { entry in
            let ids=[entry.first,entry.second].sorted()
            guard ids[0] != ids[1],ids.allSatisfy({!$0.isEmpty && !$0.contains("|") && $0.count<=200}) else{return nil}
            let valid=Self(first:ids[0],second:ids[1],relation:entry.relation)
            return seen.insert(valid.id).inserted ? valid:nil
        }
    }
    private static func replacing(_ entries:[Self],in world:PhoneWorld)->PhoneWorld {
        var next=world
        var connected=next.connectedWorld ?? LumaConnectedState()
        connected.evidenceConnections=entries
        next.connectedWorld=connected
        return next
    }
    /// These predicates use raw saved pairs and earned prerequisites, not
    /// visible(), so evaluating an eviction cannot recurse through evidence.
    private static func milestones(_ world:PhoneWorld)->[Bool] {
        [VeilReferences.homeIndexReady(world),HavenCrossArchiveReview.ready(world),
         SocialArchiveReview.ready(world),NoraFriendArchive.ready(world),
         VeilCommunity.reconstructionReady(world)]
    }
    static func revokesMilestone(_ id:String,in world:PhoneWorld)->Bool {
        let before=milestones(world)
        let after=milestones(replacing(stored(world).filter{$0.id != id},in:world))
        return zip(before,after).contains{$0.0 && !$0.1}
    }
    /// Potential dependencies are protected from implicit edits even while
    /// prerequisites are dormant. This classification never grants access.
    static func supportsAuthoredDependency(_ entry:Self)->Bool {
        let ids=Set([entry.first,entry.second])
        guard ids.count == 2 else{return false}
        if entry.relation == .wording {
            if ids.contains("veil:thread:ordinary-hours") && (1...6).contains(where:{ids.contains(String(format:"image:VEIL_Home_%02d",$0))}) {return true}
            if ids == Set([SocialArchiveReview.readingID,"image:VEIL_Home_03"]) ||
               ids == Set([SocialArchiveReview.recordID,"veil:conversation"]) ||
               ids == Set([HavenWatchEvents.followupRecordID,"veil:thread:last-annotation"]) {return true}
        }
        if entry.relation == .chronology && ids == Set([SocialArchiveReview.datesID,"veil:home-index"]) {return true}
        return HavenCrossArchiveReview.potentialPair(entry)
    }
    static func requiresExplicitRemoval(_ entry:Self,in world:PhoneWorld)->Bool {
        stored(world).contains{$0.id == entry.id && $0.relation != entry.relation && supportsAuthoredDependency($0)}
    }
    static func saving(_ entry:Self,in world:PhoneWorld)->[Self]? {
        guard make(entry.first,entry.second,relation:entry.relation,in:world)==entry else{return nil}
        guard !requiresExplicitRemoval(entry,in:world) else{return nil}
        var values=stored(world).filter{$0.id != entry.id}
        values.insert(entry,at:0)
        if values.count<=capacity {return values}
        // A full notebook must not silently revoke an available discovery.
        // Predicates consume a bounded prefix, so evaluate each candidate's
        // removal in a separate full-size world. The new entry stays first.
        let baseline=milestones(world)
        for index in values.indices.reversed() where index != 0 && !supportsAuthoredDependency(values[index]) {
            var candidate=values
            candidate.remove(at:index)
            let after=milestones(replacing(candidate,in:world))
            if !zip(baseline,after).contains(where:{$0.0 && !$0.1}) {return candidate}
        }
        return nil
    }
    static func visible(_ world:PhoneWorld)->[Self] {
        let entries=stored(world)
        guard !entries.isEmpty else{return []}
        let available=Set(LumaAssistantEvidence.visible(world).map(\.id))
        var seen=Set<String>()
        return entries.compactMap { entry in
            guard let valid=canonical(entry.first,entry.second,relation:entry.relation,visible:available),
                  seen.insert(valid.id).inserted else {return nil}
            return valid
        }
    }
    func records(in world:PhoneWorld)->[LumaAssistantEvidence.Record] {
        [first,second].compactMap{LumaAssistantEvidence.selected($0,in:world)}
    }
    /// A comparison may describe an explicitly authored association; it
    /// cannot authenticate an image, person, event, or a player's hypothesis.
    func discussion(in world:PhoneWorld)->String? {
        guard Self.make(first,second,relation:relation,in:world) != nil else{return nil}
        let ids=Set([first,second])
        if ids == Set([SocialArchiveReview.readingID,"image:VEIL_Home_03"]) {
            return "The public post describes an ordinary reading goal. The recovered photograph shows a similar activity, but is not established as the photograph Nora published. Compare the descriptions without assuming shared provenance."
        }
        if ids == Set([SocialArchiveReview.datesID,"veil:home-index"]) {
            return "The public discussion distinguishes original capture from import; the index describes a revision of the collection. These records support comparing dates and order, not assigning an original capture date."
        }
        if ids == Set([HavenWatchEvents.followupRecordID,"veil:thread:last-annotation"]) {
            return "Both records preserve the same annotation wording separately from the camera field. Compare the descriptions, keeping the missing author unresolved."
        }
        if ids == Set([NoraFriendArchive.recordID,"veil:conversation"]) {
            return "Nora's historical account disputes language used in the anonymous correspondence. The recovered exchange gives her own perspective, but does not authenticate the anonymous sender."
        }
        if ids == Set([SocialArchiveReview.recordID,"veil:conversation"]) {
            return "The local draft and historical correspondence both describe a wish to set boundaries and retain records. The draft was not published. This is a connection between recovered statements, not confirmation of the sender's identity."
        }
        if HavenCrossArchiveReview.matchingPair(self,in:world) {
            return "These two records describe comparable rooms but belong to different collections. Examine their source labels; neither collection supplies a verified original capture date."
        }
        if ids == Set(VeilCommunity.disputedThreads.map { "veil:thread:"+$0 }) {
            return VeilCommunity.disputeReviewed(world) ? VeilCommunity.disputeNote :
                "The two writers remember the revision differently. Read their accounts and use the conflicting-accounts review to record what the disagreement supports."
        }
        if ids == Set(["web:studio-news","web:archive-ledger"]) {
            return "Both records discuss the distinction between original capture and import. The ledger leaves the source uncertain. A shared terminology is useful context, not independent authentication."
        }
        if ids == Set(["image:VEIL_Home_01","image:VEIL_Home_03"]) {
            return "Both copies show a white kitchen island and dark cabinetry, but the activities and framing differ. Similar interiors support a comparison, not a verified shared camera or capture date."
        }
        if ids == Set(["image:VEIL_Home_02","image:VEIL_Home_05"]) ||
           ids == Set(["image:VEIL_Home_02","image:VEIL_Home_06"]) {
            return "The beige seating and wooden furnishings provide a visible point of comparison. The framing differs; do not assign these copies to a HavenWatch camera without independent support."
        }
        if ids.contains("veil:thread:ordinary-hours"), ids.contains(where: { $0.hasPrefix("image:VEIL_Home_") }) {
            return "The discussion expresses an intrusive interest in everyday moments. The selected copy illustrates an ordinary activity; the discussion does not establish who obtained the image or when."
        }
        if ids.contains("veil:conversation"),let imageID=ids.first(where:{$0.hasPrefix("image:")}) {
            let asset=String(imageID.dropFirst(6))
            if VeilArchive.messages(world).contains(where:{$0.attachment==asset}) {
                return "The recovered correspondence includes this attachment. That establishes an association inside the restored copy, not who captured it or when."
            }
        }
        if let imageID=ids.first(where:{$0.hasPrefix("image:")}),let webID=ids.first(where:{$0.hasPrefix("web:")}),
           let page=LumaWebCatalog.page(String(webID.dropFirst(4))),
           page.images.contains(String(imageID.dropFirst(6))) {
            return "This image is listed as an attachment on the selected page. That is a relationship between records, not proof that the claims on the page are true."
        }
        switch relation {
        case .source:return "Compare the source labels. Do these records trace back to one copy, or are their origins actually independent? Leave any missing source information unresolved."
        case .chronology:return "Read the dates in each record, if present. A recorded message, import or publication date may not be the original event date."
        case .wording:return "Compare the specific wording. Similar phrasing may reflect a shared source, repetition or coincidence. The two records do not establish a conclusion by themselves."
        case .uncertainty:return "It is reasonable to keep both records together as an open question. I don't have a verified association beyond what the available records support."
        }
    }
}

struct EvidenceComparisonView: View {
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    var initialRecordID:String? = nil
    @State private var first=""
    @State private var second=""
    @State private var relation=EvidenceConnection.Relation.uncertainty
    @State private var notice=""
    @State private var revealOriginals=false
    @State private var removing:EvidenceConnection?
    @State private var confirmRemoval=false
    @AppStorage("lastseen.veil.security") private var security="Standard"
    private var records:[LumaAssistantEvidence.Record] { phase == .active ? LumaAssistantEvidence.visible(world.state):[] }
    private var selection:EvidenceConnection? { EvidenceConnection.make(first,second,relation:relation,in:world.state) }
    var body: some View {
        List {
            Section {
                Text("Compare discoveries you've already opened. A connection is a working observation, not a verified conclusion.").font(.subheadline)
                Picker("First record",selection:$first) {
                    Text("Choose record").tag("")
                    ForEach(records){Text($0.title).tag($0.id)}
                }
                Picker("Second record",selection:$second) {
                    Text("Choose record").tag("")
                    ForEach(records.filter{$0.id != first}){Text($0.title).tag($0.id)}
                }
                Picker("What are you comparing?",selection:$relation) {
                    ForEach(EvidenceConnection.Relation.allCases){Text($0.title).tag($0)}
                }
            }
            if let selection,phase == .active {
                if let challenge=PhotoFeatureMatch.challenge(selection.first,selection.second,in:world.state) {
                    Section("Recurring detail challenge") {
                        NavigationLink { PhotoFeatureMatchView(challengeID:challenge.id) } label:{
                            Label(challenge.title,systemImage:"viewfinder")
                        }
                        if PhotoFeatureMatch.completed(challenge,in:world.state) {
                            Label("Detail comparison recorded",systemImage:"checkmark.circle").font(.caption)
                        }
                    }
                }
                if let cameraID=[selection.first,selection.second].first(where:{$0.hasPrefix("haven:HavenWatch_")}),
                   let photoID=[selection.first,selection.second].first(where:{$0.hasPrefix("image:VEIL_Home_")}) {
                    Section("Original image comparison") {
                        if VeilArchive.allowsImages(security) {
                            Toggle("Reveal both originals",isOn:$revealOriginals)
                            if revealOriginals {
                                ForEach([cameraID,photoID],id:\.self) { id in
                                    VStack(alignment:.leading,spacing:6) {
                                        Text(id.hasPrefix("haven:") ? "HavenWatch saved still" : "VEIL recovered copy").font(.caption.bold())
                                        if let image=UIImage(named:String(id.dropFirst(6))) {
                                            Image(uiImage:image).resizable().scaledToFit()
                                        } else { Text("Original unavailable").font(.caption) }
                                    }
                                }
                            }
                        } else { Text("Image previews hidden by security preference. Text comparison remains available.").font(.caption) }
                        Text("Unmodified originals. Similar rooms do not establish a shared camera.").font(.caption).foregroundColor(.secondary)
                    }
                }
                ForEach(selection.records(in:world.state)){record in
                    Section(record.title) {
                        // Bounded local source excerpts, not generated summaries.
                        ForEach(Array(record.excerpts.prefix(8).enumerated()),id:\.offset){ entry in
                            Text(String(entry.element.prefix(420))).font(.subheadline).textSelection(.enabled)
                        }
                        if record.excerpts.count>8 {Text("Additional passages remain in the original record.").font(.caption).foregroundColor(.secondary)}
                    }
                }
                if let discussion=selection.discussion(in:world.state) {
                    Section("Luma · comparison") {
                        Text(discussion)
                        Text("Local record comparison. No new access or identity verification.").font(.caption).foregroundColor(.secondary)
                        Button("Save connection") {
                            guard phase == .active else{return}
                            let readyBefore=VeilReferences.homeIndexReady(world.state)
                            let socialBefore=SocialArchiveReview.ready(world.state)
                            let friendBefore=NoraFriendArchive.ready(world.state)
                            let annotationBefore=VeilCommunity.reconstructionReady(world.state)
                            if world.saveEvidenceConnection(first,second,relation:relation) {
                                if !readyBefore && VeilReferences.homeIndexReady(world.state) {
                                    notice="Connection saved. A new recovered reference is available in Files."
                                } else if !socialBefore && SocialArchiveReview.ready(world.state) {
                                    notice="Connection saved. Additional restored account material is available in Afterframe."
                                } else if !friendBefore && NoraFriendArchive.ready(world.state) {
                                    notice="Connection saved. A recovered conversation is available in Messages."
                                } else if !annotationBefore && VeilCommunity.reconstructionReady(world.state) {
                                    notice="Connection saved. The annotation review is available in VEIL."
                                } else { notice="Connection saved to the current checkpoint." }
                            } else if EvidenceConnection.requiresExplicitRemoval(selection,in:world.state) {
                                notice="Remove the existing saved comparison explicitly before changing its type. Related discoveries may become unavailable."
                            } else { notice="Connection could not be saved without losing a protected comparison. Review existing comparisons." }
                        }.buttonStyle(.borderedProminent)
                        if !notice.isEmpty {Text(notice).font(.caption)}
                    }
                }
            } else if records.count<2 {
                Text("Open at least two accessible records to compare them.").foregroundColor(.secondary)
            }
            let saved=EvidenceConnection.visible(world.state)
            if !saved.isEmpty && phase == .active {
                Section("Saved connections") {
                    ForEach(saved){entry in
                        VStack(alignment:.leading,spacing:5){
                            Text(entry.records(in:world.state).map(\.title).joined(separator:" + ")).font(.headline)
                            Text(entry.relation.title).font(.caption).foregroundColor(.secondary)
                            if EvidenceConnection.revokesMilestone(entry.id,in:world.state) {
                                Label("Supports a current discovery",systemImage:"link").font(.caption).foregroundColor(.secondary)
                            } else if EvidenceConnection.supportsAuthoredDependency(entry) {
                                Label("Protected comparison",systemImage:"link").font(.caption).foregroundColor(.secondary)
                            }
                            Button("Review connection"){
                                first=entry.first;second=entry.second;relation=entry.relation;notice=""
                            }.font(.caption)
                        }
                        .swipeActions(allowsFullSwipe:false) {
                            Button(role:.destructive){removing=entry;confirmRemoval=true}label:{Label("Remove",systemImage:"trash")}
                        }
                    }
                }
            }
        }.navigationTitle("Compare records")
            .confirmationDialog("Remove saved connection?",isPresented:$confirmRemoval,titleVisibility:.visible){
                Button("Remove",role:.destructive){
                    guard phase == .active,let entry=removing,EvidenceConnection.visible(world.state).contains(entry) else{return}
                    world.removeEvidenceConnection(entry.id);removing=nil
                }
                Button("Cancel",role:.cancel){removing=nil}
            } message:{
                Text(removing.map{EvidenceConnection.supportsAuthoredDependency($0) || EvidenceConnection.revokesMilestone($0.id,in:world.state)} == true
                     ? "Related discoveries may become unavailable. Restoring this comparison can recover access."
                     : "This removes your saved observation from the current checkpoint.")
            }
            .onChange(of:world.checkpointEpoch){_ in first="";second="";relation = .uncertainty;notice="";revealOriginals=false;removing=nil;confirmRemoval=false}
            .onAppear{
                if let initialRecordID,records.contains(where:{$0.id==initialRecordID}),first.isEmpty{first=initialRecordID}
            }
            .onChange(of:first){value in if value==second{second=""};notice="";revealOriginals=false}
            .onChange(of:second){_ in notice="";revealOriginals=false}
            .onChange(of:security){_ in revealOriginals=false}
            .onDisappear{revealOriginals=false}
            .onChange(of:relation){_ in notice=""}
            .onChange(of:phase){if $0 != .active{notice="";revealOriginals=false;removing=nil;confirmRemoval=false}}
            .onChange(of:records.map(\.id)){_ in
                revealOriginals=false
                // A newly unlocked record must not erase the discovery notice.
                // Clear it only when the selected source actually disappears.
                if !first.isEmpty && !records.contains(where:{$0.id==first}){first="";notice=""}
                if !second.isEmpty && !records.contains(where:{$0.id==second}){second="";notice=""}
            }
    }
}


/// Curated observations from the hash-pinned six home-copy originals.
/// Regions are approximate 3x3 image cells, not camera calibration.
enum PhotoFeatureMatch {
    struct Challenge:Identifiable {
        let id:String
        let title:String
        let assets:[String]
        let target:String
        let regions:[Set<Int>]
        let textClues:[String]
        let note:String
    }
    static let all:[Challenge] = [
        .init(id:"home-counter",title:"The kitchen counter",
              assets:["VEIL_Home_01","VEIL_Home_03"],target:"Find the central expanse of the white island countertop in each photograph.",
              regions:[[4,7],[7,8]],textClues:["The broad white surface crosses the center and lower center of the frame.","The white surface is in the lower portion, primarily beneath and to the right of the open book."],
              note:"Both copies include a broad white kitchen island; the framing and activities differ."),
        .init(id:"home-table",title:"The living room table",
              assets:["VEIL_Home_02","VEIL_Home_05"],target:"Find the center of the wooden coffee table in each photograph.",
              regions:[[7,8],[8]],textClues:["The tabletop occupies the lower middle and right of the frame.","The tabletop sits to the lower right of the seated figure."],
              note:"Both copies depict a wooden coffee table by beige seating, with different visible activities and framing."),
        .init(id:"home-seating",title:"A familiar seat",
              assets:["VEIL_Home_02","VEIL_Home_06"],target:"Find the beige sofa cushions on the left side of each photograph.",
              regions:[[0,3],[3,6]],textClues:["The beige back and seat cushions fill the left side around the upper and middle rows.","The beige cushions occupy the middle and lower left side of the view."],
              note:"Both copies show beige seating beside a coffee table; similar furnishings are not unique identifiers."),
        .init(id:"archive-door-locks",title:"Recurring hardware",assets:["Recovered_B27_23","Recovered_B27_25"],
              target:"Locate the two round dark door locks on both originals.",
              regions:[[4],[4]],textClues:["The locks sit one above the other on the door frame, in the central cell.","The corresponding pair of round locks is again in the central cell."],
              note:"Both frames show the same arrangement of two round locks. The dark outline differs, but this does not establish capture order or identity."),
        .init(id:"veil-reflection-case",title:"A recurring circular marking",assets:["Recovered_B27_24","Recovered_B27_28"],
              target:"Locate the circular marking on the back of the dark phone in both copies.",
              regions:[[4],[4]],textClues:["The circular marking is on the phone in the center cell.","The circular marking is near the center of the frame, on the back of the phone."],
              note:"Both images show a dark phone with a circular case marking. Similar hardware is not a unique identifier and does not establish the relationship between the copies.")
    ]
    static func available(_ world:PhoneWorld)->[Challenge] {
        let home=VeilArchive.authorized(world) ? Set(VeilArchive.homeMedia(world).filter{world.flags.contains("veil.viewed."+$0)}) : []
        let browser=Set(RecoveredImageAnalysis.visible(world).filter{$0.source == .browser}.map(\.id))
        let reflection=Set(VeilArchive.reflectionMedia(world).filter{world.flags.contains("veil.viewed."+$0)})
        return all.filter { c in
            let visible:Set<String>
            switch c.id {
            case "archive-door-locks":visible=browser
            case "veil-reflection-case":visible=reflection
            default:visible=home
            }
            return c.assets.allSatisfy{visible.contains($0)}
        }
    }
    static func challenge(_ a:String,_ b:String,in world:PhoneWorld)->Challenge? {
        available(world).first{Set($0.assets.map{"image:"+$0}) == Set([a,b])}
    }
    static func accepts(_ id:String,first:Int,second:Int,in world:PhoneWorld)->Challenge? {
        guard let c=available(world).first(where:{$0.id==id}),
              c.regions[0].contains(first),c.regions[1].contains(second) else{return nil}
        return c
    }
    static func selectionCurrent(_ id:String,epoch:UUID?,currentEpoch:UUID,active:Bool,in world:PhoneWorld)->Bool {
        active && epoch==currentEpoch && available(world).contains{$0.id==id}
    }
    static func completed(_ c:Challenge,in world:PhoneWorld)->Bool {
        available(world).contains{$0.id==c.id} &&
        world.connectedWorld?.photoFeatureMatches?.contains(c.id)==true
    }
    static func notes(_ asset:String,in world:PhoneWorld)->[String] {
        available(world).filter{$0.assets.contains(asset) && completed($0,in:world)}
            .map{"Recorded visible-detail comparison: "+$0.note+" This does not authenticate a shared source."}
    }
}
struct PhotoFeatureMatchView:View {
    let challengeID:String
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.veil.security") private var security="Standard"
    @State private var reveal=false
    @State private var textOnly=false
    @State private var first:Int?
    @State private var second:Int?
    @State private var selectionEpoch:UUID?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var notice=""
    private var canSelect:Bool {phase == .active && (reveal || textOnly || !VeilArchive.allowsImages(security))}
    private var currentSelection:Bool {PhotoFeatureMatch.selectionCurrent(challengeID,epoch:selectionEpoch,currentEpoch:world.checkpointEpoch,active:canSelect,in:world.state)}
    private func reset(){reveal=false;first=nil;second=nil;notice="";selectionEpoch=nil}
    var body:some View {
        List {
            if let c=PhotoFeatureMatch.available(world.state).first(where:{$0.id==challengeID}),phase == .active {
                Section {
                    Text(c.target).font(.headline)
                    Text("Mark the corresponding region in both original images. Different framing may place the detail in different cells.").font(.subheadline)
                    Toggle("Text-only comparison",isOn:$textOnly)
                    if !textOnly && VeilArchive.allowsImages(security) {
                        Toggle("Reveal original photographs",isOn:$reveal)
                    }
                }
                ForEach(0..<2,id:\.self) { i in
                    Section(VeilArchive.mediaTitle(c.assets[i],in:world.state) ?? RecoveredImageAnalysis.record(c.assets[i],in:world.state)?.title ?? "Recovered photograph") {
                        let selected=i==0 ? first:second
                        if reveal && !textOnly && VeilArchive.allowsImages(security),
                           let image=PortraitImages.load(c.assets[i]) {
                            Image(uiImage:image).resizable().scaledToFit()
                                .overlay {
                                    GeometryReader { g in
                                        Path { path in
                                            for n in 1...2 {
                                                let x=g.size.width*CGFloat(n)/3
                                                let y=g.size.height*CGFloat(n)/3
                                                path.move(to:CGPoint(x:x,y:0));path.addLine(to:CGPoint(x:x,y:g.size.height))
                                                path.move(to:CGPoint(x:0,y:y));path.addLine(to:CGPoint(x:g.size.width,y:y))
                                            }
                                        }.stroke(.white.opacity(0.7),style:StrokeStyle(lineWidth:1,dash:[4,3]))
                                        if let selected {
                                            Rectangle().stroke(Color.yellow,lineWidth:3)
                                                .frame(width:g.size.width/3,height:g.size.height/3)
                                                .position(x:(CGFloat(selected%3)+0.5)*g.size.width/3,
                                                          y:(CGFloat(selected/3)+0.5)*g.size.height/3)
                                        }
                                    }.allowsHitTesting(false).accessibilityHidden(true)
                                }.accessibilityLabel("Original photograph with region grid")
                        } else if textOnly || !VeilArchive.allowsImages(security) || (reveal && PortraitImages.load(c.assets[i])==nil) {
                            Text(c.textClues[i]).font(.subheadline)
                        } else {
                            Text("Reveal the original or choose text-only comparison.").font(.caption)
                        }
                        if reveal || textOnly || !VeilArchive.allowsImages(security) {
                            LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:dynamicTypeSize.isAccessibilitySize ? 1:3),spacing:6) {
                                ForEach(0..<9,id:\.self) { cell in
                                    Button {
                                        guard canSelect,PhotoFeatureMatch.available(world.state).contains(where:{$0.id==challengeID}) else{return}
                                        if selectionEpoch != world.checkpointEpoch {first=nil;second=nil;selectionEpoch=world.checkpointEpoch}
                                        if i==0 {first=cell} else {second=cell}
                                        notice=""
                                    } label:{
                                        Text(ImageInterpretation.regions[cell]).font(.caption)
                                            .frame(maxWidth:.infinity,minHeight:44)
                                    }.buttonStyle(.bordered).tint(selected==cell ? .purple:.secondary)
                                        .accessibilityAddTraits(selected==cell ? .isSelected:[])
                                }
                            }
                        }
                    }
                }
                Section {
                    Button("Record matched detail") {
                        guard currentSelection,let first,let second else{return}
                        notice=world.recordPhotoFeatureMatch(c.id,first:first,second:second) ?
                            "Visible detail recorded.":"Revisit both frames and locate the described feature."
                    }.buttonStyle(.borderedProminent).disabled(!currentSelection || first==nil || second==nil)
                    if !notice.isEmpty {Text(notice).font(.caption)}
                    if PhotoFeatureMatch.completed(c,in:world.state) {
                        Label(c.note,systemImage:"checkmark.seal").foregroundColor(.teal)
                    }
                    Text("A recurring detail supports comparison, not a verified camera, date or identity.").font(.caption).foregroundColor(.secondary)
                }
            } else { Text("Comparison unavailable.") }
        }.navigationTitle("Match visible details")
        .onChange(of:world.checkpointEpoch){_ in reset()}
        .onChange(of:PhotoFeatureMatch.available(world.state).contains{$0.id==challengeID}){if !$0 {reset()}}
        .onChange(of:phase){if $0 != .active {reset()}}
        .onChange(of:security){_ in reset()}
        .onChange(of:textOnly){_ in reset()}
        .onChange(of:reveal){if !$0 {first=nil;second=nil;notice="";selectionEpoch=nil}}
        .onDisappear{reset()}
    }
}
