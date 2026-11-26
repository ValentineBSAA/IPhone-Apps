import Foundation

/// Hand-authored ordinary history spread across three years, anchored to the
/// fictional restored phone. Stable IDs and dates; not repeated generated filler.
enum PhoneYearsArchive {
    struct Exchange {let id:String;let peer:Neighbor;let days:Double;let lines:[String]}
    static let exchanges:[Exchange] = [
        .init(id:"first-room",peer:.adrian,days:1060,lines:["The lease paperwork finally came through. The room is smaller than the photographs.","small is fine. can we fit two desks and a decent chair?","Two desks, yes. The chair is a separate negotiation.","then we have a studio. i'm absurdly excited about this"]),
        .init(id:"first-sketch",peer:.tessa,days:985,lines:["I have three logo sketches. One looks like a weather app by accident.","send me the weather app one too. i want to see the mistakes","You're going to make me regret sharing my sketchbook.","never. the rough versions are my favorite"]),
        .init(id:"book-move",peer:.maya,days:910,lines:["Found the book you left in my bag during the move.","i was convinced i'd donated it accidentally","It's got a receipt in it from that cafe we used to hide in.","keep it until we go back. feels like a tiny time capsule"]),
        .init(id:"winter-lunch",peer:.helen,days:840,lines:["I still have your scarf here. Want me to bring it when I see you?","please! i've been borrowing the world's least warm scarf from lily","I'll put it by the door. Don't let work keep you out all evening.","i'll be there early this time. promise"]),
        .init(id:"shelf",peer:.daniel,days:760,lines:["The shelf should hold the books, but please don't put your computer on it.","you've correctly identified the person most likely to do that","I know you. I also know how much that computer weighs.","fine. books only. thank you for helping"]),
        .init(id:"first-review",peer:.adrian,days:690,lines:["The first outside playtest went well. Two people missed the return button completely.","that's useful. did they expect it at the bottom or the top?","Bottom, near the action they were already using. Both tried the same thing.","okay. move it and test again. no blaming the players"]),
        .init(id:"paper",peer:.lily,days:625,lines:["Guess who bought another notebook?","i'm pretending to be surprised","This one's for actual ideas. Not the decorative notebook collection.","write something terrible on page one so you can stop worrying about it"]),
        .init(id:"quiet",peer:.maya,days:550,lines:["Are you free this Saturday? I found a little reading event.","yes, if we agree i am not allowed to bring a laptop","Finally, a sensible condition.","book it in. i'll bring coffee"]),
        .init(id:"design-workshop",peer:.tessa,days:480,lines:["I tried a workshop exercise where we removed half the interface labels.","did people still know what everything did?","Some icons were obvious. Others turned into an advanced guessing game.","keep the useful labels. clarity is more important than symmetry"]),
        .init(id:"tea",peer:.helen,days:410,lines:["Your plant has a new leaf. I think it likes the kitchen window.","i'm taking this as evidence that you have magical plant powers","It might just be the sunlight, love.","nope. magic. i'm sticking with magic"]),
        .init(id:"builds",peer:.adrian,days:330,lines:["I made a release checklist template so we stop remembering things halfway through a build.","good. version, save migration, clean install and accessibility at minimum","And audio after interruptions. We missed that last time.","add it. future us will be grateful"]),
        .init(id:"art-break",peer:.tessa,days:275,lines:["I spent the afternoon drawing something that isn't for work. Very strange feeling.","good strange?","Very good strange. No feedback forms or export sizes.","keep doing it. not everything has to become a deliverable"]),
        .init(id:"weekend-train",peer:.daniel,days:195,lines:["Want me to meet you at the station on Sunday?","i can walk, but thanks. need some fresh air","All right. I'll bring the cake in case it rains.","priorities understood. see you then"]),
        .init(id:"film-night",peer:.lily,days:120,lines:["Film night. I'm choosing and you're not allowed to work through it.","can i complain about the choice?","Only after the snacks have been distributed.","acceptable contract. i'll bring popcorn"]),
        .init(id:"review-routine",peer:.tessa,days:65,lines:["Let's set aside one actual afternoon for visual testing, not five rushed minutes at the end.","yes. same screen brightness, readable labels, real device","I'll keep the exports and decisions together. No duplicate copies named final-final.","you're saving us from ourselves"])
    ]
    static func expand(_ world:inout PhoneWorld) {
        for ex in exchanges {
            var thread=world.threads[ex.peer.id] ?? []
            for (i,line) in ex.lines.enumerated() {
                let id="years-"+ex.id+"-"+String(i)
                if !thread.contains(where:{$0.id==id}) {thread.append(.init(id:id,thread:ex.peer.id,text:line,fromPlayer:i%2==1,at:world.createdAt.addingTimeInterval(-ex.days*86400+Double(i*145)),read:true))}
            }
            world.threads[ex.peer.id]=thread.sorted{($0.at,$0.id)<($1.at,$1.id)}
        }
        let notes:[(String,Double,String,String)]=[
            ("room",1059,"Things for the studio","Two desks. A chair that doesn't hurt my back. Extension leads. Something green for the window. Start small."),
            ("firsttest",689,"First outside playtest","Watch where people actually tap. Don't explain the interface unless asked. A confusing button is our problem, not theirs."),
            ("books",549,"Reading weekend","Borrow the book from Maya. Find the old receipt. Leave the computer at home."),
            ("design",479,"Workshop notes","Keep labels when icons are ambiguous. Large text before fancy transitions. Ask Tessa for the rough sketches."),
            ("checklist",329,"Release checklist draft","Version. Clean install. Existing save. Audio after interruption. Large text. Repeat failures before calling them fixed."),
            ("time",119,"Friday evening","Popcorn with Lily. No studio calls unless there is a real emergency. Take a walk before dinner.")
        ]
        for (id,days,title,body) in notes where !world.notes.contains(where:{$0.id=="years-"+id}) {world.notes.append(.init(id:"years-"+id,title:title,body:body,modifiedAt:world.createdAt.addingTimeInterval(-days*86400),pinned:false))}
    }
    static func mail(anchor:Date)->[LumaMailRecord] {
        let subjects:[(String,Neighbor,Double,String,String,String)]=[
            ("lease",.adrian,1060,"Studio room setup","Can we arrange the desks so we can both see the window? Let's avoid buying anything unnecessary until we've worked in the room.","I'll measure first. We can keep the existing chairs for now and replace the uncomfortable one."),
            ("sketch",.tessa,985,"Early identity sketches","Please keep the early sketches. I like knowing why we chose the final mark.","I have the paper versions and scans. We can revisit them when the site is ready."),
            ("test",.adrian,690,"First outside playtest","Two people missed the return control. Can we keep this as a usability finding rather than explain it away?","Agreed. I'll record their expected placement and repeat the task after the adjustment."),
            ("reading",.maya,550,"Saturday reading event","I booked the afternoon off. Please remind me if I start trying to move the studio review onto Saturday.","Absolutely. I'll send you the meeting point separately. Bring a book, not a laptop."),
            ("workshop",.tessa,480,"Interface workshop","I'd like to preserve the examples where text labels helped. We don't need every control to look minimal.","I'll collect the examples with the notes. Accessibility and clarity are part of the design, not a final coat of paint."),
            ("release",.adrian,330,"Reusable release checklist","Let's make a single checklist for clean install, existing save, interruption, accessibility and version identity.","Done. I've added a place for reproduction steps and a separate column for device acceptance."),
            ("family",.helen,410,"A little plant update","Thank you for looking after the plant. I'll bring a new pot next time I come over.","No hurry. It's doing nicely by the window. Bring yourself, that's all."),
            ("visual",.tessa,65,"Device review afternoon","Let's compare the same screen in different appearances on the actual phone. Keep original exports and decisions separate.","I'll set aside the afternoon. We can test contrast before committing to the final colors.")
        ]
        return subjects.flatMap { id,peer,days,subject,body,reply in
            let date=anchor.addingTimeInterval(-days*86400)
            return [.init(id:"years-mail-"+id,peer:peer.id,sender:RestoredPhoneBackup.ownerName,subject:subject,body:body,date:date,kind:"sent"),.init(id:"years-mail-"+id+"-reply",peer:peer.id,sender:peer.name,subject:"Re: "+subject,body:reply,date:date.addingTimeInterval(7200),kind:"inbox")]
        }
    }
    static func posts(anchor:Date)->[LumaSocialPost] {
        let rows:[(String,LumaSocialChannel,String,String,String,String?,Double)]=[
            ("room",.connective,"Nora Bennett","nora.b","We have a little studio room! Two desks and a window. Excited to make things slowly and learn as we go.","Nora_Profile",1060),
            ("sketch",.connective,"Tessa Reed","tessa.r","The early sketchbook is full of crossed-out ideas. That's my favorite stage of a project.","Contact_B27_07",985),
            ("books",.afterframe,"Maya Brooks","maya.b","Found an old book receipt in a borrowed novel. Some things make much better bookmarks than actual bookmarks.","Contact_Maya",910),
            ("winter",.afterframe,"Helen Bennett","helen.b","A lovely family afternoon. The cake did not survive.","Contact_B27_01",840),
            ("test",.connective,"Adrian Cole","adrian.c","A first playtest is useful precisely because people don't do what you expect.","Contact_B27_06",690),
            ("paper",.afterframe,"Lily Bennett","lily.b","This notebook is actually getting used. An unprecedented development.","Contact_B27_03",625),
            ("reading",.commonGround,"Nora Bennett","nora.b","Anyone else prefer the quiet reading events to the big ones? Trying to make a little more time for them.","Nora_Profile",550),
            ("workshop",.connective,"Blue Hour Interactive","bluehour","A design exercise reminded us that simple controls need to be understandable, not merely small.",nil,480),
            ("plant",.afterframe,"Nora Bennett","nora.b","A new leaf on the plant. My mother is clearly better at looking after my plants than I am.","Nora_Profile",410),
            ("release",.connective,"Adrian Cole","adrian.c","Reusable test checklists save the team from our own collective memory.","Contact_B27_06",330),
            ("art",.afterframe,"Tessa Reed","tessa.r","Drew something just for myself this afternoon. No brief, no deadline, no export requirements.","Contact_B27_07",275),
            ("popcorn",.afterframe,"Lily Bennett","lily.b","Film night and an unreasonable quantity of popcorn. Excellent evening.","Contact_B27_03",120)
        ]
        return rows.map { id,ch,author,handle,body,portrait,days in .init(id:"years-post-"+id,channel:ch,author:author,handle:handle,body:body,date:anchor.addingTimeInterval(-days*86400),portrait:portrait,photo:nil,gate:nil) }
    }
}
