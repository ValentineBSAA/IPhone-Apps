import Foundation

struct PhonePendingReply: Codable, Equatable, Identifiable {
    let id: String
    let outgoingID: String
    let neighbor: Neighbor
    let text: String
    let readAt: Date
    let dueAt: Date
    let startsTutorial: Bool
    var typingAt: Date? = nil
}

struct PhoneReplyPlan {
    let text: String
    var startsTutorial = false
    var everyday = false
}

/// Offline authored reactions. No external model, invented evidence or access grants.
enum PhoneReplyPolicy {
    /// Shared knowledge boundary for live conversations and mail. Historical
    /// records remain immutable; only pending and newly composed replies use it.
    static func ownerStatusQuestion(_ text:String)->Bool {
        !PhoneEverydayConversation.words(text).isDisjoint(with:["nora","missing","where","safe","disappeared","location","address"])
    }
    static func privateAccessQuestion(_ text:String)->Bool {
        let words=PhoneEverydayConversation.words(text)
        if !words.isDisjoint(with:["password","passcode","credentials","pin"]) {return true}
        let normalized=LumaAssistantPolicy.normalize(text)
        if !words.isDisjoint(with:["unlock","code"]) {
            return ["how","what","give","tell","need","can","could","know"].contains{words.contains($0)}
                && !confirmedUnlock(normalized)
        }
        return false
    }
    private static func confirmedUnlock(_ normalized:String)->Bool {
        let negative=["couldn t unlock","could not unlock","can t unlock","cannot unlock","haven t unlocked","have not unlocked","didn t unlock","did not unlock","not unlocked","trying to unlock","need to unlock"]
        guard !negative.contains(where:{normalized.contains($0)}) else{return false}
        return ["figured out how to unlock","managed to unlock","already unlocked","unlocked it","got it unlocked","unlocked the phone","unlocked her phone","got into her phone","got into the phone","phone is unlocked","phone s unlocked","got past the lock screen"].contains{normalized.contains($0)}
    }
    static func mayaStatusReply(_ text:String,flags:Set<String>)->String? {
        guard flags.contains(InvestigationResolution.read),ownerStatusQuestion(text),!privateAccessQuestion(text) else{return nil}
        return "I've spoken to her. She asked for some time and I want to respect that. I can't tell you her location."
    }
    static func plan(for neighbor: Neighbor, text: String, flags: Set<String>,
                     tutorialStarted: Bool, tutorialFinished: Bool, previousReply: String? = nil, previousMessage: String? = nil, recentReplies: [String] = []) -> PhoneReplyPlan {
        let normalized = text.lowercased()
        let words = Set(normalized.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        func mentions(_ terms: String...) -> Bool { terms.contains { words.contains($0) } }
        if neighbor == .unknown {
            if flags.contains("web.visited." + InvestigationResolution.indexID) {
                return PhoneReplyPlan(text: "Local rehearsal response. No remote participant is connected.")
            }
            return PhoneReplyPlan(text: InvestigationProgress.unknownReply(words: words, flags: flags))
        }
        if neighbor == .maya,let status=mayaStatusReply(text,flags:flags) {
            return PhoneReplyPlan(text:status)
        }
        if !Neighbor.original.contains(neighbor) {
            // Familiar contacts can provide grounded ordinary context without
            // claiming to know why the phone was found or exposing private material.
            let help = mentions("help","start","next","stuck","look","check","investigate")
            if tutorialFinished && help && !privateAccessQuestion(text) &&
                !mentions("address","location","whereabouts","secret","private","disappeared") {
                let response:String
                switch neighbor {
                case .tessa: response="If you want to understand Nora's work, try the studio's public journal and the older review emails. My palette reminder makes more sense beside those conversations."
                case .adrian: response="I'd start with the ordinary studio correspondence and public project notes. Keep the original records separate from any conclusions you draw."
                case .helen: response="I can tell you about our family plans, but I can't tell you what's happened. Her calendar and old messages may help you understand what she normally did."
                case .lily: response="We used to share little things in our messages. Maybe start there, rather than assuming everything on her phone is important."
                case .daniel: response="I'd check her ordinary plans and speak to someone who knows the situation. I don't want to guess just because I haven't heard from her."
                default: response="Take your time with the records you already have. I don't know anything beyond our own conversation."
                }
                if response != previousReply {return PhoneReplyPlan(text:response,everyday:true)}
            }
            if let everyday = PhoneEverydayConversation.reply(neighbor: neighbor, text: text, previousMessage: previousMessage, previousReply: previousReply, recentReplies: recentReplies) {
                return PhoneReplyPlan(text: everyday == previousReply ? "I don't have much else to add right now." : everyday, everyday: true)
            }
            return PhoneReplyPlan(text: NoraEverydayArchive.response(neighbor, words: words))
        }
        let intro = neighbor == .maya && tutorialStarted && !flags.contains("phone-tutorial-replied")
        if mentions("jailbreak", "jailbroken", "patchline", "relay", "rootless") {
            return PhoneReplyPlan(text: neighbor == .maya
                ? "Wait, what do you mean by jailbreak? Is that how you got her phone working?"
                : "I'm not familiar with that. Are you trying to reach someone in the building?")
        }
        let reportedUnlock = confirmedUnlock(LumaAssistantPolicy.normalize(text))
        let asksForAccess = privateAccessQuestion(text) || ["how do i unlock","how can i unlock","can you unlock","don't know how to unlock","couldn't unlock","could not unlock","haven't unlocked","have not unlocked","didn't unlock","not unlocked"].contains { normalized.contains($0) }
        if neighbor == .maya && reportedUnlock && !asksForAccess {
            if intro && (PhoneEverydayConversation.confirmsRepair(text) || !text.contains("?") && !text.contains("\"") && !text.contains("“") && !text.contains("”")) {
                return PhoneReplyPlan(text: "Thanks for getting her phone working. I’m Maya, a friend of Nora’s. Could you check her Notes for the plans she mentioned?", startsTutorial: true)
            }
            return PhoneReplyPlan(text: mentions("nora","missing","where","safe")
                ? "I'm glad you got it open. I wish I knew where she was. Please keep me updated on what you find."
                : "I'm glad you got it open. Take your time, and let me know how it goes.")
        }
        if mentions("password", "passcode", "pin", "unlock", "code") {
            return PhoneReplyPlan(text: neighbor == .maya
                ? "I don't know her passcode. She was pretty careful about that stuff."
                : "I don't have access to residents' phones or personal codes.")
        }
        if mentions("hate", "stupid", "idiot", "fuck", "bitch") {
            return PhoneReplyPlan(text: neighbor == .maya
                ? "Okay, I don't want to argue. I'm just worried about Nora."
                : "I'd appreciate keeping this conversation respectful.")
        }
        if intro && PhoneEverydayConversation.confirmsRepair(text) {
            return PhoneReplyPlan(text: "Oh, thank you for telling me. I'm Maya, a friend of Nora's. I was expecting to hear from her. Could you look in Notes for something called Before I forget? She mentioned writing down her plans.", startsTutorial: true)
        }
        if tutorialFinished, let everyday = PhoneEverydayConversation.reply(neighbor: neighbor, text: text, previousMessage: previousMessage, previousReply: previousReply, recentReplies: recentReplies) {
            return PhoneReplyPlan(text: everyday == previousReply ? "I don't have much else to add right now." : everyday, everyday: true)
        }
        if neighbor == .maya {
            if intro {
                return PhoneReplyPlan(text: "Sorry, I'm a little confused. Are you Nora, or are you the person who got her phone working?")
            }
            if mentions("nora", "missing", "disappeared", "where", "okay", "safe") {
                return PhoneReplyPlan(text: "I wish I knew. She hasn't answered me, which is why I reached out. Have you found anything on her phone?")
            }
            if mentions("note", "notes", "reminder", "journal", "file", "files", "photos", "photo", "pictures") {
                if tutorialFinished {
                    return PhoneReplyPlan(text: "Thanks for looking. Keep me posted if you come across anything else.")
                }
                if flags.contains("phone-tutorial-file-guidance") {
                    return PhoneReplyPlan(text: "She kept some personal things locked. I can't tell you how to open them, but maybe her own reminders will help.")
                }
                if flags.contains("phone-tutorial-note-guidance") {
                    return PhoneReplyPlan(text: "Did you find the documents she mentioned? Take your time looking through them.")
                }
                return PhoneReplyPlan(text: "Try the note she called Before I forget. I remember her mentioning it.")
            }
            if mentions("coffee", "book", "bookshop", "weekend", "party") {
                return PhoneReplyPlan(text: "We were supposed to get coffee after the bookshop. I was really looking forward to seeing her.")
            }
            if mentions("work", "game", "games", "studio", "company", "developer") {
                return PhoneReplyPlan(text: "She was always working on some new app or game. She'd get excited telling me about it, even when I didn't understand half of it.")
            }
            if mentions("family", "mother", "mum", "mom", "sister", "brother") {
                return PhoneReplyPlan(text: "Her family means a lot to her. I don't want to worry them with guesses.")
            }
            if mentions("thanks", "thank", "okay", "ok", "sure", "yes", "alright") {
                return PhoneReplyPlan(text: "Thank you. I appreciate you taking the time.")
            }
            if mentions("hello", "hi", "hey") {
                return PhoneReplyPlan(text: "Hey. Any news?")
            }
            return PhoneReplyPlan(text: "I'm not sure I follow. Can you tell me a little more about what you mean?")
        }
        if mentions("elevator", "inspection", "maintenance", "contractor", "time") {
            return PhoneReplyPlan(text: "The elevator inspection is still tentative. I'll post an update when the contractor confirms the schedule.")
        }
        if mentions("nora", "apartment", "resident", "missing", "where", "address") {
            return PhoneReplyPlan(text: "I manage the building office, but I can't confirm anyone's whereabouts. Is there a maintenance or building matter I can help with?")
        }
        if mentions("parcel", "package", "delivery") {
            return PhoneReplyPlan(text: "Please check with the building office regarding parcels. We keep residents' deliveries there.")
        }
        if mentions("thanks", "thank", "okay", "ok", "sure") {
            return PhoneReplyPlan(text: "You're welcome. Please let the office know if you need anything else.")
        }
        return PhoneReplyPlan(text: "Could you clarify what you're asking about? I handle building notices and maintenance.")
    }

}

enum PhoneConversationPresentation {
    static func shouldShowBanner(for incoming: Neighbor, visible: Neighbor?, locked: Bool, covered: Bool) -> Bool {
        !locked && (covered || incoming != visible)
    }
}
