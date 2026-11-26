import Foundation

enum NoraEverydayArchive {
    static let revision = 1
    struct Mail { let id: String; let sender: String; let subject: String; let body: String; let offset: TimeInterval }
    static let mail: [Mail] = [
        .init(id:"b27-studio-qa",sender:"Adrian Cole",subject:"Friday QA handoff",body:"Nora, the prototype checklist is in the shared folder. Please keep larger-text and interruption tests in Friday's review. No need to stay late.",offset:-90000),
        .init(id:"b27-art-review",sender:"Tessa Reed",subject:"Palette review",body:"Lilac and midnight options are ready. Bring your phone so we can compare colors on the actual display.",offset:-140000),
        .init(id:"b27-family",sender:"Helen Bennett",subject:"Sunday lunch",body:"Come whenever you can, love. Lily is bringing dessert. Please don't turn lunch into another meeting. Mum x",offset:-170000)
    ]
    static let documents = [
        "Blue Hour · Friday QA":"Prototype review checklist\nLarger text; interruption recovery; save persistence; contrast; one-handed controls.\nOwner: Nora Bennett. Review with Adrian and Tessa.",
        "Blue Hour · Palette review":"Compare lilac, pearl and midnight on a small screen. Keep the decision open until the accessibility check.",
        "Blue Hour · Studio notes":"Small independent studio. Keep releases manageable; test before shipping; leave room for experiments.",
        "Weekend list":"Sunday lunch at Mum's. Pick up a small dessert if Lily hasn't already. Bring the book back to Maya."
    ]
    static func expand(_ world: inout PhoneWorld) {
        if !world.flags.contains("b33.everyday.depth") {
            addStudioHistory(&world)
            world.flags.insert("b33.everyday.depth")
        }
        guard (world.everydayArchiveRevision ?? 0) < revision else { return }
        let conversations: [(Neighbor, [(Bool, String)])] = [
            (.helen, [(false,"Are you eating properly or living on coffee again?"),(true,"i had actual lunch today, promise. very proud of myself"),(false,"Sunday lunch if you're free. No pressure."),(true,"yes please. i'll put it in my calendar"),(false,"Lovely. Bring yourself, not your laptop.")]),
            (.lily, [(false,"borrowed your taste in nail polish and now everyone thinks i'm fashionable"),(true,"finally my influence is being acknowledged"),(false,"lilac or pearl for sunday?"),(true,"pearl. and don't buy another bottle just because i said that"),(false,"too late 🫶")]),
            (.daniel, [(false,"Mum says you might be coming Sunday."),(true,"yep! you too?"),(false,"I'll be there. Want a lift?"),(true,"i'll let you know. thanks for asking"),(false,"No problem. Tell Oliver to stop sending me his game scores.")]),
            (.adrian, [(false,"Friday QA list is ready. Added large text and interruptions."),(true,"thank you. please put save persistence on there too"),(false,"Done. We can review it at the studio."),(true,"perfect. no heroics, we can ship when it's ready"),(false,"A sensible release plan? From you? Historic.")]),
            (.tessa, [(false,"I made the lilac and midnight palettes. Pearl is still my favorite."),(true,"send them for friday. i want to see the contrast on my phone"),(false,"Already in the review folder. Coffee first though."),(true,"obviously. priorities"),(false,"And please wear that jacket you showed me last week. It's lovely.")])
        ]
        for (index,item) in conversations.enumerated() {
            var list = world.threads[item.0.id] ?? []
            let start = world.createdAt.addingTimeInterval(-86400 * Double(8-index))
            for (i,line) in item.1.enumerated() {
                let id = "b27-history-\(item.0.id)-\(i)"
                if !list.contains(where: { $0.id == id }) { list.append(NeighborMessage(id:id,thread:item.0.id,text:line.1,fromPlayer:line.0,at:start.addingTimeInterval(Double(i*95)),read:true)) }
            }
            world.threads[item.0.id] = list.sorted { $0.at < $1.at }
        }
        let notes = [
            PhoneNote(id:"b27-personal-style",title:"Little things for me",body:"Pearl nails or lilac? Find my silver hoops. Wash the good jacket. Make a playlist for the weekend. Leave one evening free.",modifiedAt:world.createdAt.addingTimeInterval(-200000),pinned:false),
            PhoneNote(id:"b27-studio-qa",title:"Friday QA",body:"Adrian: large text, interruptions, saves. Tessa: lilac / pearl / midnight contrast. Bring the phone. Don't rush a release.",modifiedAt:world.createdAt.addingTimeInterval(-100000),pinned:true),
            PhoneNote(id:"b27-sunday",title:"Sunday lunch",body:"Mum, Lily, Daniel. Ask Oliver how his tests went. Bring dessert if needed. Laptop stays home.",modifiedAt:world.createdAt.addingTimeInterval(-160000),pinned:false)
        ]
        for n in notes where !world.notes.contains(where: { $0.id == n.id }) { world.notes.append(n) }
        let c = Calendar.current
        let fri = c.nextDate(after:world.createdAt,matching:DateComponents(hour:15,weekday:6),matchingPolicy:.nextTime) ?? world.createdAt.addingTimeInterval(86400)
        let sun = c.nextDate(after:world.createdAt,matching:DateComponents(hour:13,weekday:1),matchingPolicy:.nextTime) ?? world.createdAt.addingTimeInterval(172800)
        for e in [PhoneEvent(id:"b27-friday-qa",title:"Blue Hour · Friday QA",detail:"Studio review with Adrian and Tessa. Palette and persistence checks.",startsAt:fri,endsAt:fri.addingTimeInterval(5400)),PhoneEvent(id:"b27-sunday-lunch",title:"Lunch at Mum's",detail:"Family lunch. Ask about a lift if needed.",startsAt:sun,endsAt:sun.addingTimeInterval(7200))] where !world.events.contains(where: { $0.id == e.id }) { world.events.append(e) }
        world.everydayArchiveRevision = revision
    }
    /// Ordinary historical exchanges add texture, not unlocks.
    private static func addStudioHistory(_ world:inout PhoneWorld) {
        let exchanges:[(Neighbor,Double,[(Bool,String)])] = [
            (.tessa,12,[(false,"I made a contrast sheet with lilac, pearl and midnight. The lilac looked lovely until I put white text on it."),(true,"can we try darker ink on the light version? i don’t want to choose from a mockup alone"),(false,"Yep. I'll make the controls match their states too. Selected, pressed, disabled, all the boring bits."),(true,"the boring bits are what makes it feel finished. compare the smallest text on my phone friday"),(false,"I'll bring the original exports. Can we record the decision in the review folder instead of burying it in chat?"),(true,"yes please. and leave room for changes after testing"),(false,"Good. Coffee first. Then we can have our extremely serious argument about purple.")]),
            (.adrian,11,[(false,"I reproduced the resume problem by switching apps during an animation. The save was fine; the view was rebuilding with the wrong state."),(true,"can you separate that in the report? a broken animation isn't the same as lost progress"),(false,"Exactly. I'm writing two cases: background during transition, and a clean launch from a saved checkpoint."),(true,"add a third for restarting after an update. people shouldn't have to restart their game every time we fix something"),(false,"Added. I'll keep the build on my test phone overnight rather than call it fixed after one run."),(true,"thank you. no launch date until we've done the boring test passes"),(false,"I'll update the team before lunch. No need to reply tonight.")]),
            (.maya,10,[(false,"Did your meeting eat your entire afternoon again?"),(true,"almost. tessa saved me with coffee and a pastry"),(false,"You're allowed to have a life outside a screen you know."),(true,"rude but fair. bookshop this weekend?"),(false,"Yes! I'll find the book I promised you. No laptops."),(true,"deal. if i start talking about release dates you have permission to change the subject")]),
            (.helen,9,[(false,"I found the big blue serving dish. Do you still like the lemon cake?"),(true,"yes!! don't make anything extra just for me"),(false,"Well, I already bought the lemons. You'll have to help me eat it."),(true,"i will make that sacrifice"),(false,"Bring Lily if she's free. We can sit outside if it's nice.")]),
            (.lily,7,[(false,"I found a notebook with actual decent paper. I am trying not to buy six."),(true,"buy one and actually use it this time"),(false,"I hate that you know me so well"),(true,"send me the shop name. i need somewhere to put ideas that isn't a work document"),(false,"Maple Street! I'll show you when we go. Also I have a playlist for you.")])
        ]
        for (person,days,lines) in exchanges {
            var thread=world.threads[person.id] ?? []
            for (i,line) in lines.enumerated() {
                let id="b33-depth-"+person.id+"-"+String(i)
                if !thread.contains(where:{$0.id==id}) {
                    thread.append(.init(id:id,thread:person.id,text:line.1,fromPlayer:line.0,at:world.createdAt.addingTimeInterval(-days*86400+Double(i*125)),read:true))
                }
            }
            world.threads[person.id]=thread.sorted{($0.at,$0.id)<($1.at,$1.id)}
        }
        let notes:[PhoneNote] = [
            .init(id:"b33-note-art",title:"Palette review",body:"Tessa has the originals in the review folder. Voice memo is my quick reminder for our meeting, not the final art decision. Compare small labels, selected and disabled controls, and the same screen at the same brightness.",modifiedAt:world.createdAt.addingTimeInterval(-145000),pinned:false),
            .init(id:"b33-note-qa",title:"Release review questions",body:"Can someone resume after a phone interruption? Is a saved game still usable after an update? Can new players find their way without reading a manual? Ask Adrian for the actual reproduction steps, not just a green check mark. No rush.",modifiedAt:world.createdAt.addingTimeInterval(-98000),pinned:false),
            .init(id:"b33-note-weekend",title:"A day without work",body:"Return the book. Find a notebook with good paper. Coffee with Maya. Leave the laptop at home for lunch. Maybe take a picture of something lovely just because.",modifiedAt:world.createdAt.addingTimeInterval(-185000),pinned:false)
        ]
        for note in notes where !world.notes.contains(where:{$0.id==note.id}) {world.notes.append(note)}
    }
    static func response(_ neighbor: Neighbor, words: Set<String>) -> String {
        if !words.isDisjoint(with:["password","passcode","pin","unlock"]) { return "I can't help with private access to her phone." }
        let repair = !words.isDisjoint(with:["repair","phone","found","missing","nora","where","safe","fixed"])
        switch neighbor {
        case .helen: return repair ? "Thank you for letting me know. Please don't make guesses about where she is. Have you spoken to Maya?" : "I'm not sure who I'm speaking to. Could you tell me a little more?"
        case .lily: return repair ? "Wait, you're the person with her phone? Please look after it. I don't want to lose our photos." : "Sorry, I don't understand. Is this about Nora?"
        case .daniel: return repair ? "Thanks for explaining. Let's stick to what we actually know for now." : "Could you tell me what this is about?"
        case .adrian: return repair ? "Thanks for the update. I can't give you access to studio accounts, but the local review records may still be there." : "If this is about the build review, the checklist should be in the local files."
        case .tessa: return repair ? "Thanks for being careful with her phone. Please keep Maya in the loop." : "If you're asking about the palette review, the notes are in the local folder."
        default: return "Could you clarify?"
        }
    }
}
