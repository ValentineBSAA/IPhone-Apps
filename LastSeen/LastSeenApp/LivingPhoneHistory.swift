import Foundation

/// Ordinary historical records anchored to the restored-world date, not live activity.
enum LivingPhoneHistory {
    static func posts(anchor: Date) -> [LumaSocialPost] {
        func item(_ id: String, _ channel: LumaSocialChannel, _ author: String, _ handle: String, _ body: String, _ portrait: String?, _ days: Double) -> LumaSocialPost {
            LumaSocialPost(id: "b32-" + id, channel: channel, author: author, handle: handle, body: body, date: anchor.addingTimeInterval(-days * 86400 - 1800), portrait: portrait, photo: nil, gate: nil)
        }
        return [
            item("coffee", .afterframe, "Nora Bennett", "nora.b", "coffee tastes better when nobody asks me to open a spreadsheet. small victories.", "Nora_Profile", 12),
            item("late", .afterframe, "Nora Bennett", "nora.b", "it's technically tomorrow. the code is technically working. i am technically going to bed.", "Nora_Profile", 9),
            item("playlist", .afterframe, "Nora Bennett", "nora.b", "weekend playlist: loud enough to forget the week, not loud enough to annoy the neighbors.", "Nora_Profile", 18),
            item("style", .afterframe, "Lily Bennett", "lily.b", "Pearl nails won. I accept no further feedback on this matter.", "Contact_B27_03", 7),
            item("books", .afterframe, "Maya Brooks", "maya.b", "My reading strategy is buying a second book before finishing the first.", "Contact_Maya", 14),
            item("tea", .afterframe, "Nora Bennett", "nora.b", "watered the plants, forgot my tea, found the tea, microwaved the tea. a very successful evening.", "Nora_Profile", 6),
            item("studio-personal", .afterframe, "Nora Bennett", "nora.b", "little reminder: i make games for a living. our team at Blue Hour is doing lovely work. follow @bluehour on Connective if you're curious about the process.", "Nora_Profile", 4),
            item("art", .afterframe, "Tessa Reed", "tessa.r", "The best thing about finishing a palette is closing the twelve almost-identical color swatches.", "Contact_B27_07", 11),
            item("dessert", .afterframe, "Helen Bennett", "helen.b", "Trying a new dessert recipe. My children are very enthusiastic about the testing phase.", "Contact_B27_01", 17),
            item("quiet", .afterframe, "Nora Bennett", "nora.b", "sometimes the best part of the day is the bit after everyone else has gone home.", "Nora_Profile", 16),
            item("intro", .connective, "Nora Bennett", "nora.b", "Founder and hands-on developer at Blue Hour Interactive. We make small, thoughtfully designed games and apps. I still test builds on my own phone, and I probably always will.", "Nora_Profile", 28),
            item("company", .connective, "Blue Hour Interactive", "bluehour", "For new followers: we're an independent studio building mobile experiences with readable interfaces, thoughtful interactions and reliable saves.", nil, 24),
            item("process", .connective, "Nora Bennett", "nora.b", "Our design process: prototype, play, listen, revise. A beautiful screen doesn't mean much if the person using it cannot find the next action.", "Nora_Profile", 19),
            item("feedback", .connective, "Blue Hour Interactive", "bluehour", "What makes you comfortable returning to a game after a break? We're collecting general usability feedback. No account details needed.", nil, 15),
            item("team", .connective, "Nora Bennett", "nora.b", "Appreciation for Adrian and Tessa. Good collaborators tell you when an idea isn't ready, then help you make it better.", "Nora_Profile", 13),
            item("demo", .connective, "Blue Hour Interactive", "bluehour", "Our internal prototype is still in review. We're sharing the process rather than announcing a release date we can't promise.", nil, 8),
            item("contrast", .connective, "Tessa Reed", "tessa.r", "Today's production note: check the same screen in both appearances before calling a palette finished.", "Contact_B27_07", 5),
            item("promo", .connective, "Nora Bennett", "nora.b", "If you like behind-the-scenes game development, follow Blue Hour Interactive. We'll share progress notes, accessibility lessons and what we learn from testing.", "Nora_Profile", 3),
            item("reports", .connective, "Adrian Cole", "adrian.c", "A useful bug report says what happened, what you expected, and whether it happens again.", "Contact_B27_06", 10),
            item("schedule", .connective, "Blue Hour Interactive", "bluehour", "Our next internal review focuses on interruptions, large text, save reliability and visual polish. Thanks for following along.", nil, 2),
            item("corridor", .commonGround, "Ash Street Residents", "ashstreet", "Please keep shared corridors clear. Thanks for helping everyone get through comfortably.", nil, 9),
            item("reading", .commonGround, "Nora Bennett", "nora.b", "Any recommendations for a book I can actually finish in a weekend? Nothing too enormous please.", "Nora_Profile", 12),
            item("window", .commonGround, "Maple Cafe", "maplecafe", "We've added a few more seats by the window. Bring a book or laptop; please share the larger tables when busy.", nil, 4),
            item("firstgame", .commonGround, "Nora Bennett", "nora.b", "Local game developers: what do you wish someone had explained before you made your first game? I'm putting together practical notes.", "Nora_Profile", 20),
            item("localstudio", .commonGround, "Blue Hour Interactive", "bluehour", "We're a small local independent studio. Happy to discuss making games here; official progress notes are on Connective.", nil, 6),
            item("bags", .commonGround, "Maya Brooks", "maya.b", "Does anyone else buy a reusable bag every time they forget the twelve at home?", "Contact_Maya", 8),
            item("notebook", .commonGround, "Lily Bennett", "lily.b", "Looking for a plain notebook. I keep finding beautiful ones that I'm afraid to write in.", "Contact_B27_03", 16),
            item("readinggroup", .commonGround, "Maple Street Bookshop", "maplebooks", "Thank you to everyone who has joined a reading group lately. Suggestions for future genres are welcome.", nil, 3),
            item("cafe-work", .commonGround, "Nora Bennett", "nora.b", "thank you to the cafe staff for putting up with my laptop and the world's slowest coffee drinking.", "Nora_Profile", 7),
            item("sketch", .commonGround, "Tessa Reed", "tessa.r", "For anyone learning digital art: the little thumbnail sketch is allowed to be ugly. It is doing its job.", "Contact_B27_07", 22)
        ]
    }
    static func comments(for post: LumaSocialPost) -> [LumaSocialComment] {
        let entries: [(String, String, String)] = [
            ("b32-coffee", "Maya Brooks", "You say that like you don't voluntarily open spreadsheets."),
            ("b32-coffee", "Nora Bennett", "unfortunately i contain multitudes."),
            ("b32-late", "Tessa Reed", "Close the laptop. I mean it."),
            ("b32-late", "Nora Bennett", "yes boss (do not enjoy this)"),
            ("b32-playlist", "Lily Bennett", "send me the playlist pls"),
            ("b32-playlist", "Nora Bennett", "sending it now x"),
            ("b32-style", "Nora Bennett", "excellent decision, no notes"),
            ("b32-books", "Nora Bennett", "this is also my financial strategy apparently"),
            ("b32-tea", "Helen Bennett", "At least you remembered the plants, love."),
            ("b32-tea", "Nora Bennett", "i am improving!"),
            ("b32-studio-personal", "Maya Brooks", "Proud of you and the team!!"),
            ("b32-studio-personal", "Nora Bennett", "thank you 🫶"),
            ("b32-art", "Nora Bennett", "only twelve? impressive restraint"),
            ("b32-dessert", "Lily Bennett", "I volunteer as tribute."),
            ("b32-quiet", "Maya Brooks", "Quiet evenings are underrated."),
            ("b32-intro", "Adrian Cole", "Can confirm the phone is part of the test lab."),
            ("b32-company", "Nora Bennett", "Excited to share more of how we work."),
            ("b32-process", "Tessa Reed", "Especially the part where we revise."),
            ("b32-feedback", "Tessa Reed", "Readable text and remembering where I stopped."),
            ("b32-team", "Adrian Cole", "We also tell you when it's time for lunch."),
            ("b32-team", "Nora Bennett", "An essential part of studio operations."),
            ("b32-demo", "Nora Bennett", "Quality first. Thanks for the patience."),
            ("b32-contrast", "Nora Bennett", "Let's keep the comparison in the review notes."),
            ("b32-promo", "Tessa Reed", "Looking forward to sharing the art process."),
            ("b32-reports", "Nora Bennett", "And please tell us which version you tested."),
            ("b32-schedule", "Adrian Cole", "Checklist is ready for review."),
            ("b32-reading", "Maple Street Bookshop", "Short story collections are a lovely option."),
            ("b32-reading", "Nora Bennett", "that's actually a great idea, thanks!"),
            ("b32-firstgame", "Adrian Cole", "Back up early. Write down what you changed."),
            ("b32-firstgame", "Nora Bennett", "the second one is a personal attack."),
            ("b32-localstudio", "Tessa Reed", "We're always learning, too."),
            ("b32-bags", "Lily Bennett", "the bags have a bag of their own at this point"),
            ("b32-notebook", "Maple Street Bookshop", "We have simple notebooks near the counter."),
            ("b32-readinggroup", "Maya Brooks", "Something funny next time please."),
            ("b32-cafe-work", "Maple Cafe", "You're very welcome!"),
            ("b32-sketch", "Nora Bennett", "permission to be bad at the first draft is important.")
        ]
        return entries.enumerated().compactMap { index, entry in
            guard entry.0 == post.id else { return nil }
            return LumaSocialComment(id: "b32-comment-\(index)", postID: post.id, author: entry.1, body: entry.2, date: post.date.addingTimeInterval(Double(600 + index * 211)))
        }
    }
    static func mail(anchor: Date) -> [LumaMailRecord] {
        func pair(_ id: String, _ peer: Neighbor, _ days: Double, _ subject: String, _ body: String, _ reply: String) -> [LumaMailRecord] {
            let sent = anchor.addingTimeInterval(-days * 86400 - 3600)
            return [
                LumaMailRecord(id: "b32-mail-" + id, peer: peer.id, sender: "Nora Bennett", subject: subject, body: body, date: sent, kind: "sent"),
                LumaMailRecord(id: "b32-mail-" + id + "-reply", peer: peer.id, sender: peer.name, subject: "Re: " + subject, body: reply, date: sent.addingTimeInterval(5400), kind: "inbox")
            ]
        }
        return [
            pair("public", .adrian, 24, "Studio public updates", "Keep public updates short and honest. No promised date until review is done. I'll handle the introduction; can you check technical wording?", "That works. I'll check for claims about unfinished features. We can share general lessons without exposing internal builds."),
            pair("art", .tessa, 20, "Art process post", "Would you write a short note about choosing a palette? Nothing confidential, just the process.", "Absolutely. I'll use comparing appearances as an example. I'd rather explain why we changed a color than post six identical mockups."),
            pair("feedback", .adrian, 15, "Feedback to keep", "I asked followers what helps them return to a game. Collect general usability suggestions, not personal details.", "Good idea. I've left room in the review for resume behavior and readable controls."),
            pair("scope", .tessa, 12, "Small studio, small promises", "Let's keep the next update focused on our process. A quiet week is fine.", "Agreed. It's more sustainable than announcing a feature every week."),
            pair("contrast", .tessa, 10, "Appearance comparison", "Can we check both appearances at the same brightness and keep the notes together?", "Yes. I'll bring both palettes to review. Let's leave room for adjustments."),
            pair("review", .adrian, 6, "Review preparation", "Keep the checklist centered on larger text, interruptions and save persistence. Optional polish can wait.", "Understood. The existing QA checklist covers those. I'll bring the test cable."),
            pair("hours", .tessa, 18, "Evening availability", "Trying to leave evenings free unless something is genuinely urgent. Don't expect an immediate reply.", "Deal. That includes you. Let's use the ordinary review slot instead of turning everything into an emergency."),
            pair("photos", .helen, 21, "Photos from lunch", "Mum, remind me to send pictures next time. I want to choose a few good ones rather than the entire camera roll.", "Whenever you have time, darling. I'd rather you came to see us than worried about sorting photographs."),
            pair("book", .maya, 13, "Book recommendations", "Making a weekend list. Send me the name of that book if you remember it. No rush.", "I'll check when I get home. Also you owe me a proper coffee, not a five-minute studio coffee."),
            pair("notebook", .lily, 16, "Notebook idea", "If you find a nice plain notebook, tell me where. I need one I won't be afraid to use.", "Maple Street has some. We should go together or I'll buy something ridiculous."),
            pair("b33-resume", .adrian, 11, "Resume behavior and save tests", "Please keep the interruption and checkpoint tests separate. I want to know whether the saved data is wrong or the interface simply resumes in the wrong place. Include an update over an existing save.", "I have three separate cases and will record the exact starting state for each. We should test both a fresh install and a retained save. I can send a summary after Friday’s review."),
            pair("b33-palette", .tessa, 12, "Palette decision notes", "I left myself a short voice reminder about the lilac palette. Can we compare the original exports on the same phone? Check small labels, disabled controls and both appearances before we decide.", "Yes. I’ll bring the originals and a contrast sheet. Pearl still looks good but it needs a darker text treatment. Let’s record the decision in one place."),
            pair("b33-weekend", .maya, 9, "Bookshop and a real weekend", "I’m trying to get out of the studio for more than ten minutes. Coffee and the bookshop if you have time?", "Absolutely. I’ll find the book I promised you. No release dates, no laptop, and definitely no meeting disguised as coffee."),
            pair("profile", .adrian, 3, "Public profile", "I've refreshed my profile to explain what we do. The studio page is for progress; my page can stay a mix of work and life.", "Makes sense. I'll point people to the studio page. Let's keep internal documents where they belong.")
        ].flatMap { $0 }
    }
}
