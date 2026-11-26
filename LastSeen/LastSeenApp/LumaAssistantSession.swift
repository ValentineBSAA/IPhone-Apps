import Foundation

/// Only a bounded topic and authored memory cursor persist. No player text,
/// private answer text, generated output or new access authority is retained.
struct LumaAssistantSession: Codable, Equatable {
    let topicID: String
    let memoryID: String?
    let recollectionCount: Int
    var guidanceTrack:LumaGuidanceTrack? = nil
    var topic: LumaConversationTopic? { LumaConversationTopic(rawValue:topicID) }

    static func validated(_ session:Self?,in world:PhoneWorld) -> Self? {
        guard world.everydayArchiveRevision != nil,
              let session, let topic = session.topic, topic != .general,
              LumaAssistantTrust.permits(topic,world:world) else { return nil }
        if LumaOwnerMemory.topics.contains(topic) {
            guard let memory = session.memoryID, LumaOwnerMemory.entries.contains(where:{$0.id == memory && $0.topic == topic}) else { return nil }
            let count = LumaAssistantTrust.level(world) == .established ? min(2,max(0,session.recollectionCount)) : 0
            return .init(topicID:topic.rawValue,memoryID:memory,recollectionCount:count)
        }
        // A saved topic isn't evidence. Recheck archive access before allowing
        // the sensitive conversation to resume, even on a restored checkpoint.
        if [.browser,.pictures,.privacy,.correspondence].contains(topic),
           !VeilArchive.authorized(world) { return nil }
        let track=topic == .nextStep ? session.guidanceTrack:nil
        guard track != .archive || VeilArchive.authorized(world) else{return nil}
        return .init(topicID:topic.rawValue,memoryID:nil,recollectionCount:0,guidanceTrack:track)
    }

    static func from(_ reply:LumaConversationReply,in world:PhoneWorld) -> Self? {
        guard reply.answer.clipID == "conversation", reply.topic != .general else { return nil }
        return validated(.init(topicID:reply.topic.rawValue,memoryID:reply.memoryID,recollectionCount:reply.recollectionCount,guidanceTrack:reply.guidanceTrack),in:world)
    }

    static func resumePrompt(_ session:Self?,world:PhoneWorld) -> String {
        guard let valid = validated(session,in:world) else { return LumaAssistantTrust.greeting(world) }
        if let id = valid.memoryID, let entry = LumaOwnerMemory.entries.first(where:{$0.id == id}) {
            // Do not repeat past answer text or a recalled exchange automatically.
            switch entry.topic {
            case .ownerWork: return "We were discussing Nora's work. We can continue, or talk about something else."
            case .ownerFamily,.ownerFriends: return "We were discussing Nora's everyday relationships. What would you like to ask?"
            default: return "We were talking about Nora's everyday life. Shall we continue?"
            }
        }
        return "We were discussing your observations. Have you found anything else?"
    }
}
