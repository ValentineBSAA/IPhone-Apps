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
    private static let all:[Reference] = [
        .init(id:"directory-reference",filename:"directory.onion",pageID:"directory",gate:VeilArchive.discovery,note:"Recovered local directory bookmark."),
        .init(id:"board-reference",filename:"discussion-cache.onion",pageID:"boards",gate:"veil.correspondence.opened",note:"Archived discussion reference. The directory may be incomplete."),
        .init(id:"private-index-reference",filename:"fragment-04.onion",pageID:"fragment-04",gate:"web.visited.archive-ledger",note:"Partial saved reference. Its source has not been authenticated.")
    ]
    static func visible(_ world:PhoneWorld)->[Reference] {
        guard VeilArchive.authorized(world) else { return [] }
        return all.filter{world.flags.contains($0.gate)}
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
