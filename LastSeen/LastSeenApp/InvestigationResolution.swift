import SwiftUI

// SPOILERS: local authored OS-first ending. Never expose this catalog before
// its prerequisite chain. The legacy campaigns have independent saves.
enum InvestigationResolution {
    static let indexID = "archive-session"
    static let noteID = "archive-handoff"
    static let mailID = "local-review-04"
    static let requested = "investigation.review4.requested"
    static let read = "investigation.review4.read"
    static let conclusionID = "archive-disposition"
    static let completed = "investigation.resolution.completed"
    enum Choice: String, CaseIterable, Codable, Identifiable {
        case minimal, retain
        var id: String { rawValue }
        var title: String {
            switch self {
            case .minimal: return "Send a minimal handoff"
            case .retain: return "Keep the review local"
            }
        }
        var detail: String {
            switch self {
            case .minimal: return "Send only the verified service findings to Maya. Exclude private records, images and unverified theories."
            case .retain: return "Keep the verified review on this phone without sending its contents. Maya receives only a brief confirmation that the repair review is finished."
            }
        }
    }
    static func eligible(_ world: PhoneWorld) -> Bool {
        InvestigationReview.ready(world) && world.flags.contains(InvestigationReview.finished) &&
        InvestigationReview.valid(InvestigationReview.visibleSelection(world))
    }
    static func availableMail(_ world: PhoneWorld) -> Bool {
        eligible(world) && world.flags.contains("web.visited." + indexID) &&
        world.flags.contains("web.visited." + noteID) && world.flags.contains(requested)
    }
    static func mail(at date: Date) -> LumaMailRecord {
        .init(id: mailID, peer: "maya", sender: "Maya Brooks", subject: "Something definite, finally",
              body: "I spoke to Nora. Not another message from this number. I heard her voice, and we talked about things that weren't in the backup. She's asked for some time away and doesn't want her location passed around. I won't do that. She said the old phone might still contain the rehearsal she built after someone started sending her copies of her own posts. I'm sorry I didn't know any of this when I first wrote. Thank you for looking after her things. Please don't send me her private photos.\n\nMaya",
              date: date, kind: "inbox")
    }
    static func ready(_ world: PhoneWorld) -> Bool {
        availableMail(world) && world.flags.contains(read) &&
        world.flags.contains("web.visited." + conclusionID) &&
        (world.connectedWorld?.mail.contains { $0.id == mailID && $0.kind == "inbox" } ?? false)
    }
    static func ending(_ world: PhoneWorld) -> Choice? {
        guard ready(world), world.flags.contains(completed) else { return nil }
        return world.connectedWorld?.investigationDisposition
    }
    static func message(_ choice: Choice) -> String {
        switch choice {
        case .minimal:
            return "I got your short review. That's enough. I won't ask you to send any of her personal things. When she's ready, she can decide what happens to the phone herself. Thank you."
        case .retain:
            return "Thanks for letting me know the review is finished. You don't owe me a copy of her life. I'll wait for her to decide what she wants to share."
        }
    }
}

struct InvestigationResolutionPanel: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @State private var selected: InvestigationResolution.Choice?
    @State private var confirming = false
    @State private var feedback = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if phase == .active,let ending=InvestigationResolution.ending(world.state) {
                Label("Review complete", systemImage: "checkmark.seal.fill").font(.title2.bold()).foregroundColor(.teal)
                Text(ending == .minimal ? "A minimal repair summary was handed off." : "The verified review remains local.").font(.subheadline)
                Divider()
                Text("LAST SEEN").font(.system(.largeTitle, design: .serif).weight(.light)).tracking(5).frame(maxWidth: .infinity)
                Text("Some things belong to the person who lived them.").font(.callout).italic().frame(maxWidth: .infinity)
                Text("You can continue exploring the restored phone. Load an earlier checkpoint to revisit the investigation and its decision.").font(.caption).foregroundColor(.secondary)
            } else if phase == .active,InvestigationResolution.ready(world.state) {
                Text("Close the review").font(.title2.bold())
                Text("The service record establishes the origin of the repeated archive activity. The new correspondence reports a separate contact with the owner; it is not independently verified location data. You can finish the repair without exposing her private records.").font(.subheadline)
                ForEach(InvestigationResolution.Choice.allCases) { choice in
                    Button {
                        selected = choice
                        feedback = ""
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: selected == choice ? "largecircle.fill.circle" : "circle")
                            VStack(alignment: .leading, spacing: 6) {
                                Text(choice.title).font(.headline)
                                Text(choice.detail).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }.padding(12).lumaSurface(radius: 12)
                    }.buttonStyle(.plain).accessibilityAddTraits(selected == choice ? .isSelected : [])
                }
                Button("Confirm decision") { confirming = true }.buttonStyle(.borderedProminent).disabled(selected == nil)
                if !feedback.isEmpty { Text(feedback).font(.caption).foregroundColor(.secondary) }
            } else {
                Label("Review unavailable", systemImage: "lock.fill").foregroundColor(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(15).lumaSurface()
            .confirmationDialog("Finish the investigation?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Confirm") {
                    guard phase == .active else{return}
                    if let selected, !world.finishInvestigation(selected) { feedback = "The review is no longer available in this save." }
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Your decision is retained in this save. An earlier checkpoint can be used to revisit it.") }
            .onChange(of:world.checkpointEpoch){_ in selected=nil;confirming=false;feedback=""}
            .onChange(of:phase){if $0 != .active {selected=nil;confirming=false;feedback=""}}
    }
}
