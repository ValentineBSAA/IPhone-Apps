import SwiftUI
import UIKit

struct RelaySupportPhotoRequest: Equatable {
    let epoch: UUID
    let messageID: String
    let item: LumaMessageAttachment
    var key: String { messageID + ":" + item.id }
}

/// Alex's support-only adapter. No investigation state is supplied to this adapter.
enum RelaySupportPhotoAnalysis {
    static func valid(_ labels:[String])->Bool {LocalSceneClassifier.valid(labels)}
    static func categories(_ observations:[(String,Float)])->[String] {LocalSceneClassifier.categories(observations)}
    static func classify(_ data:Data) async -> [String]? {await LocalSceneClassifier.classify(data)}
    static func reply(_ labels: [String]) -> String {
        guard !labels.isEmpty else {
            return "I ran a local photo classification, but didn't get a sufficiently confident supported category. I can't reliably describe this photo. Tell me what part you want help with."
        }
        return "The local image classifier suggests these broad categories: " + labels.joined(separator: ", ") +
            ". That's an estimate, not a full description. I can't identify people, read text in the photo or determine what happened. What would you like to discuss?"
    }
}

struct RelaySupportPhotoDetail: View {
    let item: LumaMessageAttachment
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.relay.installed") private var installed = ""
    @State private var request: RelaySupportPhotoRequest? = nil
    @State private var status = ""
    private var eligible: Bool {
        RelaySupportAccess.available(installed: installed, flags: world.state.flags) &&
        RelaySupportAttachmentPolicy.canRead(item, world: world.state)
    }
    var body: some View {
        ScrollView {
            if eligible {
                VStack(spacing: 16) {
                    Image(item.recordID).resizable().scaledToFit()
                    Text("Optional on-device photo classification. Only broad object and scene categories are reported to Alex.").font(.caption).foregroundColor(.secondary)
                    if request != nil {
                        ProgressView("Analyzing photo…")
                        Button("Cancel") { request = nil }
                    } else {
                        Button("Ask Alex to classify this photo") {
                            request = world.relaySupportPhotoRequest(item, installed: installed)
                            status = request == nil ? "This shared photo has already been analyzed or is no longer available." : ""
                        }.buttonStyle(.borderedProminent)
                    }
                    if !status.isEmpty { Text(status).font(.subheadline).foregroundColor(.secondary) }
                }.padding()
            } else { Text("Photo unavailable").padding() }
        }.navigationTitle("Shared photo").navigationBarTitleDisplayMode(.inline)
            .task(id: request?.key) {
                guard let pending = request, eligible,
                      let data = UIImage(named: item.recordID)?.jpegData(compressionQuality: 0.8) else {
                    if request != nil { status = "Photo could not be loaded."; request = nil }
                    return
                }
                let labels = await RelaySupportPhotoAnalysis.classify(data)
                guard !Task.isCancelled, request == pending, phase == .active, eligible else { return }
                if let labels, world.finishRelaySupportPhoto(pending, labels: labels, installed: installed) {
                    status = "Alex's classification reply is in your chat."
                } else { status = "Classification could not be completed." }
                request = nil
            }
            .onDisappear { request = nil }
            .onChange(of: phase) { if $0 != .active { request = nil } }
            .onChange(of: eligible) { if !$0 { request = nil } }
    }
}
