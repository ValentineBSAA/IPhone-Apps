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
    static func title(_ event: HavenWatchEvent) -> String { "Recovered index updated" }
    static func detail(_ event: HavenWatchEvent) -> String { "An existing archive record was indexed again. Original capture time is unavailable." }
}
struct HavenWatchEventDetail: View {
    @EnvironmentObject private var world: PhoneWorldStore
    var body: some View {
        List {
            if let event = HavenWatchEvents.visible(world.state) {
                Section {
                    LumaHeader(title: HavenWatchEvents.title(event), detail: "Local archive activity", symbol: "shield.lefthalf.filled")
                    Text(HavenWatchEvents.detail(event))
                    LabeledContent("Index update") { Text(event.due, format: .dateTime.month().day().hour().minute()) }
                    LabeledContent("Original capture", value: "Unavailable")
                    LabeledContent("Connection", value: "Archive only")
                }
                Section {
                    Text("This entry describes a restored index operation, not a new camera capture. It cannot establish that anyone is currently at the property.").font(.subheadline).foregroundColor(.secondary)
                }
            } else { Text("Activity unavailable").foregroundColor(.secondary) }
        }.navigationTitle("Archive activity")
    }
}
