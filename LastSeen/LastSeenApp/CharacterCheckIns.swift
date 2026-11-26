import Foundation

/// Optional, finite social follow-ups. Characters respond only to established
/// contact; no access to the player's browsing, photos or notebook is implied.
enum CharacterCheckIns {
    struct Pending: Codable, Equatable {
        let id:String
        let dueAt:Date
    }
    struct Event {
        let id:String
        let contact:Neighbor
        let delay:TimeInterval
        let text:String
    }
    static let events:[Event] = [
        .init(id:"b32-maya-check-in",contact:.maya,delay:105,
              text:"Just checking in. No need to reply right away. I know it's a lot to sort through. I hope you've had a chance to get something to drink."),
        .init(id:"b32-denise-check-in",contact:.denise,delay:190,
              text:"A quick note from the building office: I may be away from my desk for a bit. If you have another question, leave me a message and I'll check when I'm back.")
    ]
    static func eligible(_ event:Event,in world:PhoneWorld)->Bool {
        guard world.everydayArchiveRevision != nil,
              world.flags.contains("phone-tutorial-finished"),
              !world.flags.contains(InvestigationResolution.read),
              !world.flags.contains(InvestigationResolution.completed),
              (world.threads[event.contact.id] ?? []).contains(where:{$0.fromPlayer})
              else{return false}
        return true
    }
    static func delivered(_ event:Event,in world:PhoneWorld)->Bool {
        (world.threads[event.contact.id] ?? []).contains{$0.id==event.id}
    }
    static func blocked(_ event:Event,in world:PhoneWorld)->Bool {
        (world.pendingReplies ?? []).contains{$0.neighbor==event.contact} ||
        (world.threads[event.contact.id] ?? []).contains{ !$0.fromPlayer && !$0.read &&
            $0.id.hasPrefix("phone-tutorial-") }
    }
    static func scheduled(in world:PhoneWorld,now:Date)->[Pending] {
        let existing=world.connectedWorld?.characterCheckIns ?? []
        return events.compactMap { event in
            guard eligible(event,in:world),!delivered(event,in:world) else{return nil}
            if let saved=existing.first(where:{$0.id==event.id}) {return saved}
            return .init(id:event.id,dueAt:now.addingTimeInterval(event.delay))
        }
    }
    static func rebase(_ pending:[Pending]?,by delta:TimeInterval)->[Pending]? {
        pending?.map{.init(id:$0.id,dueAt:$0.dueAt.addingTimeInterval(delta))}
    }
}
