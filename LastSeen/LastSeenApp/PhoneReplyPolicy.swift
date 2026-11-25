import Foundation

struct PhonePendingReply: Codable, Equatable, Identifiable {
    let id: String
    let outgoingID: String
    let neighbor: Neighbor
    let text: String
    let readAt: Date
    let dueAt: Date
    let startsTutorial: Bool
}

struct PhoneReplyPlan {
    let text: String
    var startsTutorial = false
}

/// Offline authored reactions. No external model, invented evidence or access grants.
enum PhoneReplyPolicy {
    static func plan(for neighbor: Neighbor, text: String, flags: Set<String>,
                     tutorialStarted: Bool, tutorialFinished: Bool, previousReply: String? = nil) -> PhoneReplyPlan {
        let normalized = text.lowercased()
        let words = Set(normalized.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        func mentions(_ terms: String...) -> Bool { terms.contains { words.contains($0) } }
        if neighbor == .unknown { return PhoneReplyPlan(text: InvestigationProgress.unknownReply(words: words, flags: flags)) }
        if !Neighbor.original.contains(neighbor) {
            if words.isDisjoint(with: ["password","passcode","pin","unlock","repair","phone","found","missing","nora","where","safe","fixed","access","account","identity"]),
               let everyday = everydayReply(neighbor, words: words) {
                return PhoneReplyPlan(text: everyday == previousReply ? "That's all I can add on that for now. Was there a particular detail you meant?" : everyday)
            }
            return PhoneReplyPlan(text: NoraEverydayArchive.response(neighbor, words: words))
        }
        let intro = neighbor == .maya && tutorialStarted && !flags.contains("phone-tutorial-replied")
        if mentions("jailbreak", "jailbroken", "patchline", "relay", "rootless") {
            return PhoneReplyPlan(text: neighbor == .maya
                ? "Wait, what do you mean by jailbreak? Is that how you got her phone working?"
                : "I'm not familiar with that. Are you trying to reach someone in the building?")
        }
        let reportedUnlock = ["figured out how to unlock","managed to unlock","already unlocked","unlocked it","got it unlocked"].contains { normalized.contains($0) }
        let asksForAccess = ["how do i","how can i","can you","what is","what's","don't know how","couldn't","could not","haven't","have not","didn't","not unlocked"].contains { normalized.contains($0) }
        if neighbor == .maya && !intro && reportedUnlock && !asksForAccess {
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
        if intro && (mentions("repair", "repaired", "fixed", "working", "found", "technician", "phone") || normalized.contains("not nora")) {
            return PhoneReplyPlan(text: "Oh, thank you for telling me. I'm Maya, a friend of Nora's. I was expecting to hear from her. Could you look in Notes for something called Before I forget? She mentioned writing down her plans.", startsTutorial: true)
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
    private static func everydayReply(_ neighbor: Neighbor, words: Set<String>) -> String? {
        func has(_ terms: String...) -> Bool { !words.isDisjoint(with: terms) }
        switch neighbor {
        case .adrian:
            if has("marketing","promote","promotion","connective","followers","social","studio","business") { return "The studio page is for public progress notes. We try not to promise dates or unfinished features. I handle technical wording when asked." }
            if has("build","test","qa","bugs","review","release") { return "We keep the review focused on interruptions, large text and save reliability. A repeatable result matters more than a long list of promises." }
            if has("thanks","thank") { return "No problem. Keep the questions specific and I'll do what I can." }
        case .tessa:
            if has("art","palette","design","color","colour","contrast") { return "I prefer checking palettes on the actual display. Screenshots at different brightness levels can make a good color look terrible." }
            if has("marketing","promote","social","posts","connective","followers") { return "I can talk about the art process. The studio keeps public updates separate from private references and unfinished work." }
            if has("coffee","lunch","weekend") { return "Coffee is a perfectly valid production meeting, as long as somebody remembers the decisions." }
        case .helen:
            if has("lunch","dinner","food","dessert","sunday") { return "Sunday lunch is meant to be relaxed. I always make a little extra. Nobody needs to bring anything expensive." }
            if has("thanks","thank") { return "You're very welcome. Take care of yourself too." }
        case .lily:
            if has("music","playlist","song","songs") { return "My playlists are mostly an argument between three completely different moods." }
            if has("nails","style","outfit","clothes","notebook","shopping") { return "I have opinions about all of those, unfortunately. Pearl nails are still my favorite." }
        case .daniel:
            if has("lunch","sunday","family","lift","ride") { return "I usually try to leave Sunday free for family. We sort out lifts between ourselves." }
            if has("thanks","thank") { return "You're welcome. Keep me posted if there's anything practical I can do." }
        default: break
        }
        return nil
    }
}

enum PhoneConversationPresentation {
    static func shouldShowBanner(for incoming: Neighbor, visible: Neighbor?, locked: Bool, covered: Bool) -> Bool {
        !locked && (covered || incoming != visible)
    }
}
