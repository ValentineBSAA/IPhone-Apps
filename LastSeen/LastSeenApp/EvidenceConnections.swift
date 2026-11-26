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
        guard a != b, !a.contains("|"), !b.contains("|"),
              a.count <= 200,b.count <= 200 else { return nil }
        let ids=[a,b].sorted()
        let visible=Set(LumaAssistantEvidence.visible(world).map(\.id))
        guard ids.allSatisfy({visible.contains($0)}) else { return nil }
        return .init(first:ids[0],second:ids[1],relation:relation)
    }
    static func visible(_ world:PhoneWorld)->[Self] {
        var seen=Set<String>()
        return (world.connectedWorld?.evidenceConnections ?? []).prefix(40).compactMap { entry in
            guard let valid=make(entry.first,entry.second,relation:entry.relation,in:world),
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
    @AppStorage("lastseen.veil.security") private var security="Standard"
    private var records:[LumaAssistantEvidence.Record] { LumaAssistantEvidence.visible(world.state) }
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
                            } else { notice="Connection could not be saved." }
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
                            Button("Review connection"){
                                first=entry.first;second=entry.second;relation=entry.relation;notice=""
                            }.font(.caption)
                        }
                        .swipeActions {
                            Button(role:.destructive){world.removeEvidenceConnection(entry.id)}label:{Label("Remove",systemImage:"trash")}
                        }
                    }
                }
            }
        }.navigationTitle("Compare records")
            .onAppear{
                if let initialRecordID,records.contains(where:{$0.id==initialRecordID}),first.isEmpty{first=initialRecordID}
            }
            .onChange(of:first){value in if value==second{second=""};notice="";revealOriginals=false}
            .onChange(of:second){_ in notice="";revealOriginals=false}
            .onChange(of:security){_ in revealOriginals=false}
            .onDisappear{revealOriginals=false}
            .onChange(of:relation){_ in notice=""}
            .onChange(of:phase){if $0 != .active{notice="";revealOriginals=false}}
            .onChange(of:records.map(\.id)){_ in
                revealOriginals=false
                // A newly unlocked record must not erase the discovery notice.
                // Clear it only when the selected source actually disappears.
                if !first.isEmpty && !records.contains(where:{$0.id==first}){first="";notice=""}
                if !second.isEmpty && !records.contains(where:{$0.id==second}){second="";notice=""}
            }
    }
}
