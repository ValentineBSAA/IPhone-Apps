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
        , .init(id:"b33-maya-social",contact:.maya,delay:75,text:"Hey, I noticed your account has been active again. Is everything okay? No pressure to answer right away, I just wanted to check.")
        , .init(id:"b33-tessa-social",contact:.tessa,delay:210,text:"Saw the account activity. Is Nora back at her desk, or is somebody helping her with the phone? The studio can wait. Just wanted to make sure.")
    ]
    static func eligible(_ event:Event,in world:PhoneWorld)->Bool {
        guard world.everydayArchiveRevision != nil,
              world.flags.contains("phone-tutorial-finished"),
              !world.flags.contains(InvestigationResolution.read),
              !world.flags.contains(InvestigationResolution.completed) else{return false}
        if event.id.hasPrefix("b33-") {
            return (world.connectedWorld?.posts ?? []).contains { $0.author == RestoredPhoneBackup.ownerName && $0.date >= world.createdAt }
        }
        return (world.threads[event.contact.id] ?? []).contains(where:{$0.fromPlayer && $0.at >= world.createdAt})
    }
    static func delivered(_ event:Event,in world:PhoneWorld)->Bool {
        (world.threads[event.contact.id] ?? []).contains{$0.id==event.id}
    }
    /// Due player-requested replies and unread tutorial instructions have
    /// priority across contacts, not merely inside the optional event's thread.
    static func foregroundPriority(in world:PhoneWorld,now:Date)->Bool {
        (world.pendingReplies ?? []).contains{$0.dueAt<=now} ||
        world.threads.values.contains { messages in
            messages.contains{ !$0.fromPlayer && !$0.read && $0.id.hasPrefix("phone-tutorial-") }
        }
    }
    static func blocked(_ event:Event,in world:PhoneWorld)->Bool {
        (world.pendingReplies ?? []).contains{$0.neighbor==event.contact}
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
