import SwiftUI
import Foundation

struct WorldDocumentRoute: Hashable { let id: String }
struct WorldDocument: Codable, Identifiable {
    struct Block: Codable {
        let kind: String
        let text: String?
        let rows: [[String]]?
    }
    let id: String
    let title: String
    let author: String
    let role: String
    let relativeDate: String
    let revision: String
    let classification: String
    let blocks: [Block]
    var fullText: String {
        ([title,author,role,relativeDate,revision,classification] + blocks.map { $0.text ?? ($0.rows ?? []).flatMap { $0 }.joined(separator:" ") }).joined(separator:"\n")
    }
}
enum WorldDocumentCatalog {
    private static let all: [WorldDocument] = {
        guard let url = Bundle.main.url(forResource:"ConnectedWorldDocuments",withExtension:"json"),
              let data = try? Data(contentsOf:url),
              let records = try? JSONDecoder().decode([WorldDocument].self,from:data) else { return [] }
        return records
    }()
    static func available(_ id:String, world:PhoneWorld)->Bool {
        guard world.everydayArchiveRevision != nil else { return false }
        switch id {
        case "WorldDoc_01_04": return world.flags.contains("web.visited.archive")
        case "WorldDoc_01_05": return world.flags.contains("investigation.chapter2.reviewed")
        default: return ["WorldDoc_01_01","WorldDoc_01_02","WorldDoc_01_03","WorldDoc_01_06","WorldDoc_01_07","WorldDoc_01_08","WorldDoc_01_09","WorldDoc_01_10"].contains(id)
        }
    }
    static func visible(_ world:PhoneWorld)->[WorldDocument] {
        all.filter { available($0.id,world:world) }
    }
    static func document(_ id:String,world:PhoneWorld)->WorldDocument? {
        visible(world).first { $0.id == id }
    }
    static func search(_ query:String,world:PhoneWorld)->[WorldDocument] {
        let q = query.trimmingCharacters(in:.whitespacesAndNewlines)
        return visible(world).filter { q.isEmpty || $0.fullText.localizedCaseInsensitiveContains(q) }
    }
}
struct WorldDocumentReader: View {
    let id: String
    @EnvironmentObject private var world: PhoneWorldStore
    @AppStorage("lastseen.relay.installed") private var installed=""
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    @State private var largeText=false
    private var zoomAvailable:Bool {RelayCatalog.tweakActive("documentzoom",installed:installed,safeMode:safeMode,flags:world.state.flags)}
    var body: some View {
        ScrollView {
            if let doc = WorldDocumentCatalog.document(id,world:world.state) {
                VStack(alignment:.leading,spacing:18) {
                    Label("RESTORED DOCUMENT",systemImage:"doc.richtext").font(.caption.weight(.semibold)).foregroundColor(LumaDesign.accent)
                    Text(doc.title).font(.largeTitle.bold()).fixedSize(horizontal:false,vertical:true)
                    Text(doc.author + " · " + doc.role).font(.headline)
                    Text(doc.relativeDate + "\nRevision " + doc.revision + " · " + doc.classification).font(.caption).foregroundColor(.secondary)
                    if zoomAvailable {Toggle("Larger reading text",isOn:$largeText)}
                    Divider()
                    ForEach(Array(doc.blocks.enumerated()),id:\.offset) { _,block in
                        if let rows = block.rows {
                            ScrollView(.horizontal) {
                                VStack(alignment:.leading,spacing:1) {
                                    ForEach(Array(rows.enumerated()),id:\.offset) { index,row in
                                        HStack(alignment:.top,spacing:1) {
                                            ForEach(Array(row.enumerated()),id:\.offset) { _,cell in
                                                Text(cell).font(index == 0 ? .subheadline.bold() : .subheadline)
                                                    .fixedSize(horizontal:false,vertical:true)
                                                    .frame(width:zoomAvailable && largeText ? 180 : 126,alignment:.leading).padding(9)
                                                    .background(index == 0 ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                                            }
                                        }
                                    }
                                }.textSelection(.enabled)
                            }
                        } else if let text = block.text {
                            Text(text).font(zoomAvailable && largeText ? .title3 : (block.kind == "heading" ? .headline : .body))
                                .fixedSize(horizontal:false,vertical:true).textSelection(.enabled)
                        }
                    }
                    Label("Local original · Word document",systemImage:"checkmark.seal").font(.caption).foregroundColor(.secondary)
                }.frame(maxWidth:.infinity,alignment:.leading).padding(22)
            } else {
                VStack(spacing:12) {
                    Image(systemName:"lock.doc").font(.largeTitle)
                    Text("Document unavailable").font(.headline)
                    Text("This record is not available in the current restored collection.").font(.subheadline).foregroundColor(.secondary)
                }.padding(30)
            }
        }.navigationTitle("Document").navigationBarTitleDisplayMode(.inline)
    }
}
