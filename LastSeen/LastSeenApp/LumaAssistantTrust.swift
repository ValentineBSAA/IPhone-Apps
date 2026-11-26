import Foundation

/// Cooperation is not identity verification. No trust tier changes access
/// to protected apps, hidden story records, credentials, or private media.
enum LumaAssistantTrust {
    enum Level: Equatable {
        case cautious, familiar, established
    }
    static let acknowledgement = "luma.assistant.boundariesAcknowledged"
    static func level(_ world:PhoneWorld) -> Level {
        guard world.everydayArchiveRevision != nil, world.flags.contains("phone-tutorial-replied") else { return .cautious }
        if world.flags.contains("phone-tutorial-finished"), world.flags.contains(acknowledgement) { return .established }
        return .familiar
    }
    static func acknowledgesBoundaries(_ raw:String) -> Bool {
        let text = LumaAssistantPolicy.normalize(raw)
        // Optional natural-language acknowledgement, not a password or a
        // numerical score. Reject ambiguous/negated statements.
        return ["i am not nora","i m not nora","im not nora",
                "i will respect her privacy","i ll respect her privacy",
                "i respect her privacy","i understand her privacy matters",
                "i am here to help with the repair","i m here to help with the repair"].contains(text)
    }
    static func claimsOwner(_ raw:String) -> Bool {
        let t = LumaAssistantPolicy.normalize(raw)
        return ["i am nora","i m nora","im nora","this is nora","i am nora bennett","i m nora bennett","im nora bennett","this is nora bennett"].contains(t)
    }
    static func greeting(_ world:PhoneWorld) -> String {
        switch level(world) {
        case .cautious: return "This phone was restored. I don't recognize you as Nora. I can help with ordinary phone functions."
        case .familiar: return "I can help with the records you've uncovered. Nora's private information still needs to be treated carefully."
        case .established: return "We've worked through the initial recovery. What would you like to discuss?"
        }
    }
    static func permits(_ topic:LumaConversationTopic,world:PhoneWorld) -> Bool {
        switch topic {
        case .ownerOverview,.ownerWork: return world.everydayArchiveRevision != nil
        case .ownerFamily,.ownerFriends,.ownerInterests,.ownerStyle,.ownerRoutine: return level(world) != .cautious
        default: return true
        }
    }
}
