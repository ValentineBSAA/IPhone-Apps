import SwiftUI

/// Local fictional bookmark documents, not executable files or actual onion
/// addresses. Only authored reference IDs can resolve into the offline catalog.
enum VeilReferences {
    struct Reference:Identifiable {
        let id:String
        let filename:String
        let pageID:String
        let gate:String
        let note:String
    }
    static let homeIndexID = "home-index-reference"
    // Check raw saved stable IDs against independent gates. Do not call
    // EvidenceConnection.visible here: assistant evidence also reads VEIL.
    static func homeIndexReady(_ world:PhoneWorld)->Bool {
        guard VeilArchive.homeMedia(world).count == 6,
              world.flags.contains("veil.correspondence.opened"),
              world.flags.contains(marker("board-reference")),
              world.flags.contains(VeilCommunity.openedMarker("ordinary-hours")) else { return false }
        let reviewed = world.connectedWorld?.recoveredImageReviews ?? []
        let images = Set(VeilArchive.homeMedia(world).filter {
            world.flags.contains("veil.viewed."+$0) && reviewed.contains($0)
        }.map { "image:"+$0 })
        return (world.connectedWorld?.evidenceConnections ?? []).prefix(40).contains { pair in
            let ids = Set([pair.first,pair.second])
            return ids.contains("veil:thread:ordinary-hours") && ids.count == 2 &&
                !ids.isDisjoint(with:images) && pair.relation == .wording
        }
    }
    private static let all:[Reference] = [
        .init(id:"directory-reference",filename:"directory.onion",pageID:"directory",gate:VeilArchive.discovery,note:"Recovered local directory bookmark."),
        .init(id:"board-reference",filename:"discussion-cache.onion",pageID:"boards",gate:"veil.correspondence.opened",note:"Archived discussion reference. The directory may be incomplete."),
        .init(id:"private-index-reference",filename:"fragment-04.onion",pageID:"fragment-04",gate:"web.visited.archive-ledger",note:"Partial saved reference. Its source has not been authenticated."),
        .init(id:homeIndexID,filename:"revision-cache.onion",pageID:"home-index",gate:"veil.correspondence.opened",note:"A secondary index associated with the recovered home copies. The original labels are disputed.")
    ]
    static func visible(_ world:PhoneWorld)->[Reference] {
        guard VeilArchive.authorized(world) else { return [] }
        return all.filter{world.flags.contains($0.gate) && ($0.id != homeIndexID || homeIndexReady(world))}
    }
    static func marker(_ id:String)->String { "veil.reference.inspected."+id }
    static func inspected(_ id:String,in world:PhoneWorld)->Reference? {
        visible(world).first{$0.id == id && world.flags.contains(marker(id))}
    }
    static func target(_ id:String,in world:PhoneWorld)->VeilArchive.Page? {
        guard let ref=inspected(id,in:world) else { return nil }
        return VeilArchive.pages(world).first{$0.id == ref.pageID}
    }
}
struct VeilReferenceReader:View {
    let id:String
    @EnvironmentObject private var world:PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var packages=""
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    var body:some View {
        ScrollView {
            if let ref=VeilReferences.visible(world.state).first(where:{$0.id == id}) {
                VStack(alignment:.leading,spacing:18) {
                    Label(ref.filename,systemImage:"doc.badge.ellipsis").font(.title2.bold())
                    Text("Recovered bookmark · On this phone").font(.caption).foregroundColor(.secondary)
                    Text(ref.note)
                    if let target=VeilReferences.target(id,in:world.state) {
                        Text(target.address).font(.system(.caption,design:.monospaced)).textSelection(.enabled)
                        if VeilArchive.installed(world.state,packages:packages,safeMode:safeMode) {
                            NavigationLink { VeilBrowser(initialReference:id) } label: { Label("Open in VEIL",systemImage:"eye.slash") }.buttonStyle(.borderedProminent).tint(.purple)
                        } else {
                            Label("VEIL is not available. Review the local Relay catalog.",systemImage:"lock").font(.caption)
                        }
                    } else {
                        Button("Inspect recovered bookmark") { world.inspectVeilReference(id) }.buttonStyle(.bordered)
                    }
                    Text("Local game reference only. No real network address or executable content.").font(.caption).foregroundColor(.secondary)
                }.padding(20)
            } else { Text("Reference unavailable").padding() }
        }.navigationTitle("Recovered file").navigationBarTitleDisplayMode(.inline)
    }
}
