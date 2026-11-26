import SwiftUI

// An authored archive import event, never a real motion detection or live feed.
// Capture time remains unknown. Delivery is tied to the restored review.
struct HavenWatchEvent: Codable, Equatable, Identifiable {
    let id: String
    let due: Date
    var delivered = false
}
enum HavenWatchEvents {
    static let archiveID = "haven-archive-refresh-32"
    static let followupID = "haven-retained-label-32"
    static let followupOpened = "haven.retained-label.opened"
    static let followupRecordID = "haven:retained-label"
    static func followupEligible(_ world:PhoneWorld)->Bool {
        NoraFriendArchive.opened(world)
    }
    static func followup(_ world:PhoneWorld)->HavenWatchEvent? {
        guard followupEligible(world),let event=world.connectedWorld?.havenFollowupEvent,
              event.id == followupID,event.delivered else{return nil}
        return event
    }
    static func event(_ id:String?,in world:PhoneWorld)->HavenWatchEvent? {
        switch id {
        case archiveID:return visible(world)
        case followupID:return followup(world)
        default:return nil
        }
    }
    static let retainedNote = "A retained archive entry contains a user-assigned annotation: “personal collection”. The original camera directory does not contain this label. The restored index preserves the annotation and camera field separately; the annotation author is unavailable."
    static func openedFollowup(_ world:PhoneWorld)->Bool {
        followup(world) != nil && world.flags.contains(followupOpened)
    }
    static func eligible(_ world: PhoneWorld) -> Bool {
        world.everydayArchiveRevision != nil &&
        InvestigationReview.eligible(world) &&
        world.flags.contains(InvestigationReview.finished) &&
        InvestigationReview.valid(InvestigationReview.visibleSelection(world))
    }
    static func visible(_ world: PhoneWorld) -> HavenWatchEvent? {
        guard eligible(world), let event = world.connectedWorld?.havenEvent,
              event.id == archiveID, event.delivered else { return nil }
        return event
    }
    static func title(_ event: HavenWatchEvent) -> String {
        event.id == followupID ? "Retained label recovered" : "Recovered index updated"
    }
    static func detail(_ event: HavenWatchEvent) -> String {
        event.id == followupID ? "A separate label was retained during the restored archive review." :
            "An existing archive record was indexed again. Original capture time is unavailable."
    }
}
struct HavenWatchEventDetail: View {
    var eventID:String = HavenWatchEvents.archiveID
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    var body: some View {
        List {
            if let event = HavenWatchEvents.event(eventID,in:world.state),phase == .active {
                Section {
                    LumaHeader(title: HavenWatchEvents.title(event), detail: "Local archive activity", symbol: "shield.lefthalf.filled")
                    Text(HavenWatchEvents.detail(event))
                    LabeledContent("Index update") { Text(event.due, format: .dateTime.month().day().hour().minute()) }
                    LabeledContent("Original capture", value: "Unavailable")
                    LabeledContent("Connection", value: "Archive only")
                }
                Section {
                    Text("This entry describes a restored index operation, not a new camera capture. It cannot establish that anyone is currently at the property.").font(.subheadline).foregroundColor(.secondary)
                    if event.id == HavenWatchEvents.followupID {
                        Text(HavenWatchEvents.retainedNote)
                        if HavenWatchEvents.openedFollowup(world.state) {
                            NavigationLink { EvidenceComparisonView(initialRecordID:HavenWatchEvents.followupRecordID) } label:{
                                Label("Compare the retained record",systemImage:"rectangle.split.2x1")
                            }
                            NavigationLink { VeilBrowser(initialReference:"board-reference") } label:{
                                Label("Revisit related VEIL discussions",systemImage:"eye.slash")
                            }
                        }
                    }
                }
            } else { Text("Activity unavailable").foregroundColor(.secondary) }
        }.navigationTitle("Archive activity")
        .onAppear { if phase == .active && eventID == HavenWatchEvents.followupID { world.recordHavenFollowupOpened() } }
        .onChange(of:phase) { if $0 == .active && eventID == HavenWatchEvents.followupID { world.recordHavenFollowupOpened() } }
    }
}
