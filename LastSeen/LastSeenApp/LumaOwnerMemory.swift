import Foundation

/// Curated fictional owner-facing memory summaries. This is not a scan of the
/// owner's private records, nor memory of the current player as Nora.
/// Each memory is an authored paraphrase of ordinary restored content.
enum LumaOwnerMemory {
    struct Memory {
        let id: String
        let topic: LumaConversationTopic
        let terms: Set<String>
        let source: String
        let text: String
        let followup: String
    }
    static let entries: [Memory] = [
        .init(id:"owner",topic:.ownerOverview,terms:["nora","owner","bennett","personality"],source:"b32-intro; b32-process; personal",
              text:"Nora Bennett is the previous owner of this phone. Her ordinary records suggest someone creative and conscientious, with a dry sense of humor. She runs a small game studio, but work wasn't her whole life.",
              followup:"She also made time for friends, books and family. That's the everyday Nora I can describe from the restored information, not a complete account of her life."),
        .init(id:"studio",topic:.ownerWork,terms:["studio","company","founder","developer","job","career","work","business","games","blue","hour"],source:"b32-intro; b32-studio-personal",
              text:"Nora founded Blue Hour Interactive and was a hands-on developer. She preferred testing on the phone itself rather than relying only on screenshots.",
              followup:"Her public updates were about the development process, not promises about unfinished projects. Adrian and Tessa helped her review the work."),
        .init(id:"qa",topic:.ownerWork,terms:["qa","testing","test","bugs","builds","build","release","accessibility","saves"],source:"b27-studio-qa; qa",
              text:"Her review reminders emphasize readable text, interruption recovery, reliable saves and checking contrast on a real display.",
              followup:"She often put a small number of concrete checks on a list instead of rushing to ship. That is a remembered working preference, not a clue to a protected record."),
        .init(id:"team",topic:.ownerWork,terms:["adrian","tessa","coworkers","colleagues","team","collaborators"],source:"b32-team; b27-art-review",
              text:"Adrian helped with technical reviews. Tessa worked on the art and palette choices. Nora appreciated collaborators who could tell her when an idea needed more work.",
              followup:"Their ordinary correspondence includes practical review reminders and friendly jokes about coffee. It doesn't establish what any of them knew about later events."),
        .init(id:"mum",topic:.ownerFamily,terms:["helen","mum","mom","mother","parent","parents","family"],source:"b27-family; b27-history-helen-3",
              text:"Helen Bennett is Nora's mum. Their messages often concern ordinary things: eating properly, making time for family and coming to Sunday lunch.",
              followup:"Helen wanted Nora to bring herself rather than her laptop. Their correspondence reads as warm and familiar."),
        .init(id:"lunch",topic:.ownerFamily,terms:["sunday","lunch","dessert","dinner","meal"],source:"b27-sunday; lunch",
              text:"Sunday lunch was something Nora made reminders for. She wanted to check whether dessert was needed and leave the laptop at home.",
              followup:"The plans were ordinary family arrangements, not confirmation of where she is now."),
        .init(id:"siblings",topic:.ownerFamily,terms:["lily","daniel","oliver","siblings","sister","brother"],source:"b27-sunday; b27-history-daniel-2; b27-history-lily-2",
              text:"Lily, Daniel and Oliver appear in Nora's family reminders. They discussed things like lunch, lifts, nail colors and games.",
              followup:"The small jokes in their old messages tell us more about their everyday familiarity than any formal profile could."),
        .init(id:"maya",topic:.ownerFriends,terms:["maya","friend","friends","friendship","closest","relationships"],source:"maya-old-1; maya-old-3; weekend",
              text:"Maya Brooks was a familiar friend. They lent each other things, talked about books and arranged coffee. Nora's old replies were usually warm and informal.",
              followup:"Their everyday messages show that they made time for one another. I wouldn't infer more than that about their relationship."),
        .init(id:"building",topic:.ownerFriends,terms:["denise","neighbor","neighbour","neighbors","neighbours"],source:"denise-old-1; denise-old-2",
              text:"Denise handled ordinary building-office correspondence with Nora, including parcels and maintenance notices.",
              followup:"Those are routine communications. I can't use them to establish anybody's current whereabouts."),
        .init(id:"books",topic:.ownerInterests,terms:["book","books","read","reading","bookshop","novel","novels"],source:"b32-reading; maya-old-2; weekend",
              text:"Books come up repeatedly in Nora's reminders and chats. She lent books to Maya and asked for recommendations she could finish in a weekend.",
              followup:"She seemed to enjoy reading without turning it into another obligation. I don't have a reliable favorite author or title."),
        .init(id:"music",topic:.ownerInterests,terms:["music","song","songs","playlist","playlists","listen","listening"],source:"b32-playlist; b27-personal-style",
              text:"Nora made weekend playlists. One of her public posts joked about making the music loud enough to forget the week, but not loud enough to bother the neighbors.",
              followup:"I know she liked making playlists, but the recovered information doesn't establish a favorite artist or genre."),
        .init(id:"style",topic:.ownerStyle,terms:["style","clothes","clothing","wear","outfit","fashion","jacket","earrings","hoops"],source:"b27-personal-style; b27-history-tessa-4",
              text:"Her personal reminders mention a good jacket, silver hoops and small things she wanted to do for herself.",
              followup:"These are little everyday preferences, not a complete wardrobe or a way to verify the date or identity in a photograph."),
        .init(id:"colors",topic:.ownerStyle,terms:["color","colors","colour","colours","nails","polish","pearl","lilac","palette","favorite","favourite"],source:"b27-personal-style; b27-history-lily-3; b27-art-review",
              text:"Pearl and lilac appear in Nora's nail and style notes. She suggested pearl to Lily, but I wouldn't claim that either was her permanent favorite color.",
              followup:"She also compared lilac, pearl and midnight in her studio work. A design preference and a personal favorite aren't necessarily the same thing."),
        .init(id:"coffee",topic:.ownerRoutine,terms:["coffee","tea","drink","drinks","cafe","café","break"],source:"shopping; b32-coffee; b32-tea",
              text:"Coffee and tea recur in Nora's ordinary notes. She joked about forgetting her tea while doing other things, and about coffee being better without spreadsheets.",
              followup:"She made informal plans for coffee with friends. I don't have a confirmed favorite order or a current schedule."),
        .init(id:"home",topic:.ownerRoutine,terms:["plants","plant","garden","gardening","housework","chores","weekend"],source:"weekend; b32-tea; personal",
              text:"Her reminders included watering plants, returning borrowed things and finding a frame for a photograph. Small household tasks were mixed in with her work lists.",
              followup:"She also tried to leave one evening free. There was more to her routine than the studio."),
        .init(id:"rest",topic:.ownerRoutine,terms:["sleep","rest","tired","late","night","bed","busy","routine","habits","schedule"],source:"b32-late; b32-quiet; personal memo",
              text:"Nora sometimes joked about working late, but also reminded herself that she didn't need to fill every hour with work.",
              followup:"She valued quiet time. Those notes describe ordinary habits, not a reliable account of her mental state or what happened later.")
    ]
    static let topics: Set<LumaConversationTopic> = [.ownerOverview,.ownerWork,.ownerFamily,.ownerFriends,.ownerInterests,.ownerStyle,.ownerRoutine]
    static func match(_ words:Set<String>, previous:LumaConversationTopic?) -> LumaConversationTopic? {
        // Case-specific wording always belongs to investigation policy, even
        // when a familiar person's name appears in the question.
        let investigative: Set<String> = ["stalker","stalking","blackmail","extort","extortion","harassment","hacker","sender","threat","threats","missing","disappeared","where","location","safe","real","fake","proof","identity","photo","photos","picture","pictures","images","messages","message","private","password","passcode","why"]
        guard words.isDisjoint(with:investigative) else { return nil }
        let ownerReference = !words.isDisjoint(with:["nora","bennett","owner","she","her"])
        let matches = entries.map { ($0, $0.terms.intersection(words).count) }.filter { $0.1 > 0 && $0.0.topic != .ownerOverview }
        if let best = matches.max(by: { $0.1 < $1.1 }) { return best.0.topic }
        if let previous, topics.contains(previous), !words.isDisjoint(with:["she","her","more","that","them","think","like"]) { return previous }
        if ownerReference { return .ownerOverview }
        return nil
    }
    static func answer(_ topic:LumaConversationTopic, question:String, previous:LumaConversationTopic?, world:PhoneWorld) -> String {
        guard world.everydayArchiveRevision != nil else {
            return "My previous owner's everyday memory hasn't been restored yet. I don't want to guess."
        }
        let words = LumaAssistantConversation.words(question)
        let candidates = entries.filter { $0.topic == topic }
        guard let entry = candidates.enumerated().max(by: { a,b in
            let x = a.element.terms.intersection(words).count
            let y = b.element.terms.intersection(words).count
            return x == y ? a.offset > b.offset : x < y
        })?.element else { return "I don't have a reliable memory of that. What would you like to know about Nora?" }
        let hasDetail = !entry.terms.isDisjoint(with:words)
        if previous == topic && !hasDetail { return entry.followup }
        return entry.text
    }
}
