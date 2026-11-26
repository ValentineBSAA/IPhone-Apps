import Foundation

/// Authored fictional past interactions, not quotes extracted from actual user data.
enum LumaOwnerHistory {
    struct Exchange: Identifiable {
        let id: String
        let memoryID: String
        let question: String
        let reply: String
    }
    private static func exchange(_ memory:String,_ number:Int,_ question:String,_ reply:String) -> Exchange {
        .init(id:memory+"-"+String(number),memoryID:memory,question:question,reply:reply)
    }
    static let all: [Exchange] = [
        exchange("owner",1,"Can you make my to-do list less ridiculous?","We can separate work from the things you want to do for yourself."),
        exchange("owner",2,"Remind me that I have a life outside this phone.","Make room for something you enjoy. Not everything needs a checklist."),
        exchange("studio",1,"I want to test this on the actual phone, not just look at screenshots.","That lets you check readability and whether the controls feel natural."),
        exchange("studio",2,"Help me word a studio update without promising a date.","Describe what the team has learned rather than announcing a deadline."),
        exchange("qa",1,"What do I need to remember for the build review?","Large text, interruptions, reliable saves and contrast."),
        exchange("qa",2,"I'm tempted to squeeze one more thing into the build.","Finish the checks you planned before expanding the scope."),
        exchange("team",1,"I need something useful to discuss with Adrian and Tessa.","Keep technical checks and palette decisions on the review list."),
        exchange("team",2,"How do I make feedback feel less like a disaster?","Treat a specific problem as something the team can improve."),
        exchange("mum",1,"Mum says I live on coffee. She's probably not wrong.","A lunch break would be a reasonable addition to your list."),
        exchange("mum",2,"Remind me to call Mum on Sunday.","A family reminder fits into your weekend list."),
        exchange("lunch",1,"Do I need to bring dessert to Sunday lunch?","Your reminder says to check with your family first."),
        exchange("lunch",2,"I'm going to try leaving the laptop at home.","Then lunch can remain lunch rather than another meeting."),
        exchange("siblings",1,"Lily is debating nail colors again.","You mentioned pearl and lilac in your notes."),
        exchange("siblings",2,"I need to remember to ask Oliver about his tests.","That's one of the family reminders on your list."),
        exchange("maya",1,"Make sure I remember to return Maya's things.","Returning the borrowed items belongs on your weekend list."),
        exchange("maya",2,"Coffee with Maya sounds much better than more spreadsheets.","Keep the coffee plan informal until it's confirmed."),
        exchange("building",1,"Where should I put routine maintenance reminders?","Keep building notices separate from personal tasks."),
        exchange("building",2,"I need to remember that parcel.","A pickup reminder belongs with your ordinary errands."),
        exchange("books",1,"I want a book I can finish in a weekend.","A shorter book might suit the time you want to leave for yourself."),
        exchange("books",2,"I always end up lending my books to someone.","You could keep a simple list of borrowed books."),
        exchange("music",1,"I should make a playlist that isn't for working.","A weekend playlist doesn't need to be another productivity tool."),
        exchange("music",2,"Can I have an evening with music and absolutely no plans?","You don't need to make every evening productive."),
        exchange("style",1,"What little things did I want to do for myself?","Your notes mention the good jacket and silver hoops."),
        exchange("style",2,"I want to wash that jacket before I forget again.","It's already on your personal reminders list."),
        exchange("colors",1,"Pearl or lilac? A very important dilemma.","Both appear in your notes. It doesn't need to be a permanent decision."),
        exchange("colors",2,"The palette looks different on this screen.","Compare the labels at the same brightness before choosing."),
        exchange("coffee",1,"I made tea and forgot about it. Again.","Perhaps a short break would be more useful than another reminder."),
        exchange("coffee",2,"Coffee beans need to go on the shopping list.","Coffee beans are among your ordinary shopping reminders."),
        exchange("home",1,"I need a small list of things to do at home.","Water the plants and return the borrowed things."),
        exchange("home",2,"I still need a frame for that photograph.","Your little-things list is a good place for that reminder."),
        exchange("rest",1,"I'm still working and it's technically tomorrow.","You've reminded yourself that you don't need to fill every hour."),
        exchange("rest",2,"Leave one evening completely free, please.","An evening without work belongs on the weekend list too.")
    ]
    static func visible(_ world:PhoneWorld) -> [Exchange] {
        LumaAssistantTrust.level(world) == .established ? all : []
    }
    static func recollection(_ id:String,world:PhoneWorld,index:Int) -> String? {
        let matches = visible(world).filter { $0.memoryID == id }
        guard matches.indices.contains(index) else { return nil }
        let item = matches[index]
        return "I remember this ordinary exchange:\nNora: “"+item.question+"”\nI replied: “"+item.reply+"”"
    }
    static func requestsRecollection(_ words:Set<String>) -> Bool {
        !words.isDisjoint(with:["remember","recall","asked","said","conversation","conversations","talked","chatted","history","another","example"])
    }
}
