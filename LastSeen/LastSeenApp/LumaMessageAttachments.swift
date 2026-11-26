import SwiftUI

/// Stable local references only. No external URLs, file paths, or real-device
/// photo library identifiers are accepted or persisted.
struct LumaMessageAttachment: Codable, Hashable, Identifiable {
    enum Kind: String, Codable { case photo, document, supportGuide }
    let kind: Kind
    let recordID: String
    var id: String { kind.rawValue + ":" + recordID }
}

struct LumaSupportGuide: Identifiable {
    let id: String
    let title: String
    let sections: [String]
}

enum LumaSupportGuides {
    static let all: [LumaSupportGuide] = [
        .init(id: "relay-basics", title: "Relay: Package basics", sections: [
            "Relay is the fictional phone's package manager. A repository lists available packages; a package can require other packages before it works.",
            "Review the description, version, requirements and conflicts before confirming an installation. If the transaction is rejected, read its explanation rather than trying the same installation repeatedly.",
            "An installed package is not necessarily active. Patchline can disable tweaks in Safe Mode. Check the package status before assuming an installation failed."
        ]),
        .init(id: "patchline-recovery", title: "Patchline: Recovery and diagnostics", sections: [
            "Patchline reports the fictional phone's runtime and package health. Safe Mode prevents installed tweaks from loading while preserving the installed list.",
            "A respring reloads the simulated interface. A userspace reboot performs the longer simulated recovery sequence. Neither restarts your real iPhone.",
            "If a tweak conflicts with another package, review the reported conflict and use Relay to make an intentional change. Check the resulting state before leaving Safe Mode."
        ]),
        .init(id: "protected-storage", title: "Protected storage and authentication", sections: [
            "Some restored records require separate owner verification. Finding a file or receiving a message does not automatically unlock it.",
            "Use the fictional owner passcode only. Never type your real iPhone passcode into the game. Optional device biometrics are used only through the system prompt.",
            "If a record is unavailable, return to the restored collection and check its recovery status. Technical support cannot provide private credentials or bypass individual discovery requirements."
        ]),
        .init(id: "checkpoints", title: "Saving and restoring progress", sections: [
            "The fictional phone keeps live progress locally and offers manual and automatic checkpoints. A checkpoint restores the world as it was when saved.",
            "Loading an earlier checkpoint can remove later discoveries and messages from the active game. Review the slot and its date before confirming.",
            "After restoring, protected areas may require verification again. Pending fictional conversations and active timers preserve their remaining time."
        ])
    ]
    static func guide(_ id: String) -> LumaSupportGuide? { all.first { $0.id == id } }
}

enum LumaMessageAttachmentCatalog {
    // Initial sharing scope deliberately excludes recovered/private photographs
    // and investigation documents, even when the player can read them.
    static func shareable(_ world: PhoneWorld) -> [LumaMessageAttachment] {
        guard world.everydayArchiveRevision != nil else { return [] }
        let photos = NoraPhotoCatalog.photos.filter { $0.gate == .publicPhoto && $0.available(flags: world.flags) }
            .map { LumaMessageAttachment(kind: .photo, recordID: $0.id) }
        let docs = WorldDocumentCatalog.visible(world).filter {
            ["WorldDoc_01_01","WorldDoc_01_02","WorldDoc_01_03"].contains($0.id)
        }.map { LumaMessageAttachment(kind: .document, recordID: $0.id) }
        return photos + docs
    }
    static func canSend(_ items: [LumaMessageAttachment], to neighbor: Neighbor, world: PhoneWorld) -> Bool {
        if items.isEmpty { return true }
        guard neighbor != .unknown, items.count <= 3, Set(items).count == items.count else { return false }
        return Set(items).isSubset(of: Set(shareable(world)))
    }
    static func title(_ item: LumaMessageAttachment, world: PhoneWorld) -> String? {
        switch item.kind {
        case .photo:
            return shareable(world).contains(item) ? NoraPhotoCatalog.photos.first { $0.id == item.recordID }?.title : nil
        case .document:
            return shareable(world).contains(item) ? WorldDocumentCatalog.document(item.recordID, world: world)?.title : nil
        case .supportGuide:
            return LumaSupportGuides.guide(item.recordID)?.title
        }
    }
    static func canRead(_ item: LumaMessageAttachment, thread: Neighbor, world: PhoneWorld) -> Bool {
        guard (world.threads[thread.id] ?? []).contains(where: { ($0.attachments ?? []).contains(item) }) else { return false }
        return title(item, world: world) != nil
    }
}

struct LumaMessageAttachmentPicker: View {
    let thread: Neighbor
    @Binding var selection: [LumaMessageAttachment]
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    private var eligible:[LumaMessageAttachment] {
        thread == .unknown ? []:LumaMessageAttachmentCatalog.shareable(world.state)
    }
    private func reconcile() {
        selection=Array(selection.filter{eligible.contains($0)}.prefix(3))
    }
    var body: some View {
        List {
            Section("Select up to 3") {
                if eligible.isEmpty {Text("No eligible attachments").foregroundColor(.secondary)}
                ForEach(phase == .active ? eligible:[]) { item in
                    Button {
                        guard phase == .active,eligible.contains(item) else{return}
                        if selection.contains(item) { selection.removeAll { $0 == item } }
                        else if selection.count < 3 { selection.append(item) }
                    } label: {
                        HStack {
                            if item.kind == .photo {
                                Image(item.recordID).resizable().scaledToFill().frame(width: 44, height: 44).clipped().clipShape(RoundedRectangle(cornerRadius: 7))
                            } else { Image(systemName: "doc.text").frame(width: 44) }
                            Text(LumaMessageAttachmentCatalog.title(item, world: world.state) ?? "Unavailable")
                            Spacer()
                            Image(systemName: selection.contains(item) ? "checkmark.circle.fill" : "circle")
                        }
                    }.disabled(selection.count >= 3 && !selection.contains(item))
                }
            }
            Section { Text("Only eligible fictional phone records can be attached. Private or unrecovered items and real-device files are excluded.").font(.caption).foregroundColor(.secondary) }
        }.navigationTitle("Attachments")
            .onAppear{reconcile()}
            .onChange(of:eligible){_ in reconcile()}
            .onChange(of:world.checkpointEpoch){_ in selection=[];dismiss()}
            .onChange(of:phase){if $0 != .active {selection=[];dismiss()}}
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
}

struct LumaMessageAttachmentTile: View {
    let attachment: LumaMessageAttachment
    let thread: Neighbor
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var preview = false
    @Environment(\.scenePhase) private var phase
    private var readable:Bool {phase == .active && LumaMessageAttachmentCatalog.canRead(attachment,thread:thread,world:world.state)}
    var body: some View {
        Group {
        if readable {
            Button {if readable {preview=true}} label: {
                VStack(alignment: .leading, spacing: 6) {
                    if attachment.kind == .photo {
                        Image(attachment.recordID).resizable().scaledToFit().frame(maxHeight: 150).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Label(LumaMessageAttachmentCatalog.title(attachment, world: world.state) ?? "Attachment",
                          systemImage: attachment.kind == .photo ? "photo" : "doc.richtext")
                        .font(.subheadline.weight(.medium))
                }.padding(10).lumaSurface(radius: 14)
            }.buttonStyle(.plain)
                .sheet(isPresented: $preview) {
                    NavigationStack {
                        Group {
                            if readable {
                                switch attachment.kind {
                                case .photo:
                                    ScrollView { Image(attachment.recordID).resizable().scaledToFit().padding() }
                                case .document:
                                    WorldDocumentReader(id: attachment.recordID).environmentObject(world)
                                case .supportGuide:
                                    if let guide = LumaSupportGuides.guide(attachment.recordID) {
                                        ScrollView {
                                            VStack(alignment: .leading, spacing: 18) {
                                                Label("RECOVERY SUPPORT", systemImage: "headset").font(.caption.bold()).foregroundColor(LumaDesign.accent)
                                                Text(guide.title).font(.largeTitle.bold())
                                                ForEach(guide.sections, id: \.self) { Text($0).textSelection(.enabled) }
                                            }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            } else { Text("Attachment unavailable").foregroundColor(.secondary) }
                        }.navigationTitle("Attachment").navigationBarTitleDisplayMode(.inline)
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { preview = false } } }
                    }.preferredColorScheme(.dark)
                }
        } else {
            Label("Attachment unavailable", systemImage: "lock.doc").font(.caption).foregroundColor(.secondary)
        }
        }.onChange(of:readable){if !$0 {preview=false}}
         .onChange(of:world.checkpointEpoch){_ in preview=false}
    }
}
