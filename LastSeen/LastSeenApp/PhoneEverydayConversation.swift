import Foundation

/// A bounded, authored conversation layer. It never grants story progress,
/// identifies the player as the owner, or claims new knowledge about the case.
enum PhoneEverydayConversation {
    struct Topic {
        let neighbor: Neighbor
        let id: String
        let terms: Set<String>
        let first: String
        let detail: String
        let further: String
    }
    private static let topics: [Topic] = [
        .init(neighbor: .maya, id: "leisure", terms: ["coffee", "books", "book", "reading", "bookshop", "weekend", "cafe"], first: "I usually end up with a coffee and a book when I have an afternoon to myself. Sometimes I don't even open the book.", detail: "Something short is nice when life is busy. I like being able to finish a story in one sitting.", further: "Maybe the real trick is putting my phone down for half an hour."),
        .init(neighbor: .maya, id: "work", terms: ["work", "studio", "business", "games", "developer"], first: "I'm not much of a developer myself. I like hearing how people make things, though.", detail: "I understand the idea of testing something with real people. The technical side is beyond me.", further: "I'm much better at giving an opinion than fixing a bug."),
        .init(neighbor: .denise, id: "community", terms: ["community", "notice", "notices", "residents", "building", "office"], first: "The office keeps building announcements together so residents don't have to search several conversations.", detail: "If something changes, we update the original notice where possible.", further: "I can discuss general building notices, but not private resident records."),
        .init(neighbor: .denise, id: "delivery", terms: ["parcel", "parcels", "package", "delivery"], first: "For parcels, residents normally contact the building office directly.", detail: "It's helpful if they have the delivery reference ready when they contact the office.", further: "I can't confirm someone else's deliveries through this conversation."),
        .init(neighbor: .helen, id: "family", terms: ["lunch", "dinner", "food", "dessert", "sunday", "cooking"], first: "Sunday lunch is meant to be relaxed. I always make a little extra.", detail: "There's no need to bring something expensive. I just like having everyone around the table.", further: "We can always put the kettle on afterwards."),
        .init(neighbor: .helen, id: "leisure", terms: ["garden", "gardening", "plants", "flowers", "tea"], first: "I've been trying to keep the little plants by the window happy. Some do better than others.", detail: "The ones that need very little attention seem to do best in my house.", further: "I find a cup of tea and a few minutes looking out the window quite lovely."),
        .init(neighbor: .lily, id: "music", terms: ["music", "playlist", "playlists", "song", "songs"], first: "My playlists are mostly an argument between three completely different moods.", detail: "I make one for getting things done and somehow end up listening to the same five songs.", further: "I'll probably rearrange the whole thing again next weekend."),
        .init(neighbor: .lily, id: "style", terms: ["nails", "style", "outfit", "clothes", "notebook", "shopping"], first: "Pearl nails are still my favorite. And I really don't need another notebook.", detail: "I like things that are simple enough to use every day, not just pretty in a shop.", further: "Although I am extremely easy to distract with nice stationery."),
        .init(neighbor: .daniel, id: "family", terms: ["lunch", "sunday", "family", "lift", "ride"], first: "I try to leave Sunday free for family. We sort out lifts between ourselves.", detail: "Usually a quick message ahead of time is enough to arrange things.", further: "Nothing needs to turn into a complicated schedule."),
        .init(neighbor: .daniel, id: "leisure", terms: ["walk", "walking", "weekend", "sport", "exercise"], first: "I like getting out for a walk when I have a quiet weekend.", detail: "No elaborate plans, just a bit of time away from screens.", further: "I should probably make more of a habit of it."),
        .init(neighbor: .adrian, id: "promotion", terms: ["marketing", "promote", "promotion", "connective", "followers", "social", "business", "studio", "publicity"], first: "The studio page is for public progress notes. We try not to promise dates or unfinished features. I check the technical wording.", detail: "An update should be useful even to someone who has never seen the project. A short explanation is better than vague hype.", further: "We can talk about the process without sharing private test builds."),
        .init(neighbor: .adrian, id: "testing", terms: ["build", "builds", "test", "testing", "qa", "bugs", "review", "release", "saves", "accessibility"], first: "We keep the review focused on interruptions, large text and save reliability. A repeatable result matters more than a long list of promises.", detail: "I start with a reproducible issue, then check whether the fix affects other parts of the app.", further: "Testing an upgrade with an existing save is just as important as testing a fresh install."),
        .init(neighbor: .tessa, id: "art", terms: ["art", "palette", "design", "color", "colour", "contrast", "illustration"], first: "I prefer checking palettes on the actual display. Screenshots at different brightness levels can be misleading.", detail: "I compare readable labels and contrast before deciding which color looks best. Pretty isn't much use if you can't read it.", further: "And I try not to choose every color at once. That way lies a very long afternoon."),
        .init(neighbor: .tessa, id: "promotion", terms: ["marketing", "promote", "promotion", "social", "posts", "connective", "followers", "business", "studio"], first: "I can talk about the art process. The studio keeps public updates separate from private references and unfinished work.", detail: "A little explanation of why we changed something can be more interesting than a polished picture.", further: "I'd rather share something genuinely useful than force a new announcement every week."),
        .init(neighbor: .tessa, id: "leisure", terms: ["coffee", "lunch", "weekend", "books", "reading"], first: "Coffee is a perfectly valid production meeting, as long as somebody remembers the decisions.", detail: "I prefer a proper break rather than sitting at the desk pretending to take one.", further: "The laptop can survive without us for a little while.")
    ]
    private static let sensitive: Set<String> = ["password","passcode","pin","unlock","code","repair","repaired","phone","found","missing","nora","where","safe","fixed","access","account","identity","jailbreak","jailbroken","patchline","relay","rootless","archive","evidence","journal","files","notes","photos","photo","pictures","disappeared","address","private","hate","stupid","idiot","fuck","bitch"]
    static func words(_ text: String) -> Set<String> {
        Set(text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init))
    }
    private static func normalized(_ text: String) -> String {
        text.lowercased().split { !$0.isLetter && !$0.isNumber }.joined(separator: " ")
    }
    private static let followups: Set<String> = ["tell me more","can you tell me more","what do you mean","what do you mean by that","how so","why","really","and then","anything else","go on","what else","could you explain","can you explain","like what","for example"]
    private static let thanks: Set<String> = ["thanks","thank you","okay thanks","ok thanks","thanks a lot","thank you for explaining","got it","that makes sense"]
    private static let greetings: Set<String> = ["hi","hello","hey","good morning","good evening","how are you","how s it going"]
    private static func topic(for neighbor: Neighbor, text: String) -> Topic? {
        let tokens = words(text)
        guard tokens.isDisjoint(with: sensitive) else { return nil }
        let matching = topics.filter { $0.neighbor == neighbor && !$0.terms.isDisjoint(with: tokens) }
        return matching.max { $0.terms.intersection(tokens).count < $1.terms.intersection(tokens).count }
    }
    static func reply(neighbor: Neighbor, text: String, previousMessage: String?, previousReply: String?, recentReplies: [String] = []) -> String? {
        guard neighbor != .unknown, words(text).isDisjoint(with: sensitive) else { return nil }
        let clean = normalized(text)
        if thanks.contains(clean) {
            switch neighbor {
            case .maya: return "Of course. I appreciate you checking in."
            case .denise: return "You're welcome. Let the office know if you need anything practical."
            case .helen: return "You're very welcome. Look after yourself, too."
            case .lily: return "No worries at all x"
            case .daniel: return "You're welcome. No problem."
            case .adrian: return "No problem. Happy to clarify."
            case .tessa: return "Of course! Glad that made sense."
            case .unknown: return nil
            }
        }
        if greetings.contains(clean) {
            switch neighbor {
            case .maya: return "Hey. I'm around for a bit. How are you doing?"
            case .denise: return "Hello. Is there a general building matter I can help with?"
            case .helen: return "Hello, dear. I hope you're doing all right."
            case .lily: return "Hey! What's up?"
            case .daniel: return "Hi there. Everything all right?"
            case .adrian: return "Hi. What can I help clarify?"
            case .tessa: return "Hey there! Taking a little break at the moment."
            case .unknown: return nil
            }
        }
        let direct = topic(for: neighbor, text: text)
        let followup = followups.contains(clean)
        let prior = topics.first { $0.neighbor == neighbor && [ $0.first, $0.detail, $0.further ].contains(previousReply ?? "") }
        // A follow-up can only inherit a topic from an immediately preceding
        // authored response by this contact, never from another thread or a guess.
        guard let selected = direct ?? (followup ? prior : nil) else { return nil }
        if followup || previousReply == selected.first || previousReply == selected.detail || previousReply == selected.further {
            if let prior, prior.id == selected.id {
                let used = Set(recentReplies + [previousReply ?? ""])
                if !used.contains(selected.detail) { return selected.detail }
                if !used.contains(selected.further) { return selected.further }
                return "I think that's about all I can add on that. Did you have a different question?"
            }
        }
        return selected.first
    }

    /// Keep introductory progress behind a positive, unquoted repair report.
    /// Ambiguous or negated repair language gets clarification instead.
    static func confirmsRepair(_ text: String) -> Bool {
        let clean = normalized(text)
        let negatives = ["didn t repair","did not repair","haven t repaired","have not repaired","not repaired","not fixed","couldn t fix","could not fix","can t fix","cannot fix","not working","didn t fix","did not fix","not the technician","not a technician"]
        guard !negatives.contains(where: { clean.contains($0) }),
              !text.contains("?"), !text.contains("\""), !text.contains("“"), !text.contains("”") else { return false }
        let affirmative = ["i repaired","i fixed","i found","i got the phone working","i got her phone working","i got your phone working","i m the technician","i am the technician","i m a technician","i am a technician","i m not nora","i am not nora","it s not nora","this is not nora","the phone is working","her phone is working","the phone has been repaired","the phone is fixed","i m the repair","i am the repair","repair desk here"]
        return affirmative.contains { clean.contains($0) }
    }
}

enum PhoneReplyTiming {
    struct Window {
        let read: TimeInterval
        let typing: TimeInterval
        let due: TimeInterval
    }
    static func window(neighbor: Neighbor, text: String, introductory: Bool) -> Window {
        if introductory {
            return .init(read: 0.8, typing: 0.8, due: 3.2 + min(2, Double(text.count) / 130))
        }
        let read: Double
        let pause: Double
        switch neighbor {
        case .maya: read = 1.0; pause = 0.8
        case .lily: read = 0.9; pause = 0.5
        case .helen: read = 3.2; pause = 2.0
        case .daniel: read = 2.5; pause = 1.8
        case .adrian: read = 3.0; pause = 2.0
        case .tessa: read = 2.0; pause = 1.2
        case .denise: read = 3.6; pause = 2.3
        case .unknown: read = 2.8; pause = 1.4
        }
        let typing = read + pause
        let due = typing + min(6, max(1.8, Double(text.count) / 32))
        return .init(read: read, typing: typing, due: due)
    }
}
