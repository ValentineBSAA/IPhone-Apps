import Foundation

/// Finite authored everyday activity, independent of all investigation flags.
struct LumaCommunityActivityState: Codable, Equatable {
    var start: Date
    var posts: [LumaSocialPost] = []
    var comments: [LumaSocialComment] = []
}

enum LumaCommunityActivity {
    struct Discussion {
        let handle: String
        let firstHandle: String
        let first: String
        let secondHandle: String
        let second: String
    }
    static let discussions: [Discussion] = [
        .init(handle: "iris.vale", firstHandle: "taylor.clay", first: "A slightly uneven mug is usually the one I reach for.", secondHandle: "iris.vale", second: "That makes me feel much better about mine."),
        .init(handle: "miles.frames", firstHandle: "drew.paper", first: "I love looking at ordinary textures on a walk.", secondHandle: "miles.frames", second: "Exactly. The little details make the route feel different."),
        .init(handle: "sofia.hart", firstHandle: "casey.kitchen", first: "My bread improves whenever I stop rushing the dough.", secondHandle: "sofia.hart", second: "Next weekend I'll actually give it enough time."),
        .init(handle: "morgan.stitches", firstHandle: "drew.paper", first: "Keeping the odd buttons is practically a hobby on its own.", secondHandle: "morgan.stitches", second: "I need a smaller button tin, not a larger collection."),
        .init(handle: "evan.codes", firstHandle: "noah.access", first: "I also ask people to try the task without explaining the interface first.", secondHandle: "evan.codes", second: "Yes, that is often the most useful part of the session."),
        .init(handle: "amara.finch", firstHandle: "reese.types", first: "A good brief makes the design decisions much easier to explain.", secondHandle: "amara.finch", second: "Agreed. It gives everyone the same starting point."),
        .init(handle: "rowan.audio", firstHandle: "jasper.tools", first: "The simplest sounds often end up doing the most work.", secondHandle: "rowan.audio", second: "Especially when they need to be heard repeatedly."),
        .init(handle: "jamie.maps", firstHandle: "reese.types", first: "Clear hierarchy is as important on signs as on screens.", secondHandle: "jamie.maps", second: "Absolutely. People should not need to stop and decode them."),
        .init(handle: "june.reads", firstHandle: "robin.seedlings", first: "I've got a couple of paperbacks ready for the next swap.", secondHandle: "june.reads", second: "Wonderful. I'll bring a few short stories too."),
        .init(handle: "leo.mercer", firstHandle: "little.sprout", first: "I can bring a small bag of potting soil.", secondHandle: "leo.mercer", second: "Thanks. That will save us a trip."),
        .init(handle: "sam.rivera", firstHandle: "owen.noodles", first: "I can bring snacks if the evening goes ahead.", secondHandle: "sam.rivera", second: "Perfect. I'll choose a few easy games."),
        .init(handle: "harper.knits", firstHandle: "leslie.mends", first: "Small projects are satisfying when the leftover materials finally get used.", secondHandle: "harper.knits", second: "That's exactly why I keep a little basket of scraps.")
    ]

    struct Release {
        let handle: String
        let delay: TimeInterval
        let text: String
        let replyHandle: String
        let reply: String
        let replyDelay: TimeInterval
        var id: String { "b32-community-live-" + handle + "-01" }
    }
    static let releases: [Release] = [
        .init(handle: "iris.vale", delay: 75, text: "My sketchbook has a page of mug shapes now. I think the next one will be a little wider.", replyHandle: "taylor.clay", reply: "A wider base is my favorite for everyday mugs.", replyDelay: 35),
        .init(handle: "evan.codes", delay: 135, text: "Today's little accessibility reminder: check the interface at the largest text size before calling the layout finished.", replyHandle: "noah.access", reply: "And check that the important buttons are still reachable.", replyDelay: 40),
        .init(handle: "june.reads", delay: 210, text: "Put two paperbacks aside for the book swap. One is a collection of very short stories.", replyHandle: "robin.seedlings", reply: "I'll bring a spare bookmark or two.", replyDelay: 45),
        .init(handle: "casey.kitchen", delay: 330, text: "The soup leftovers made a surprisingly good lunch. Keeping this recipe in the rotation.", replyHandle: "sofia.hart", reply: "I love a recipe that is even better the next day.", replyDelay: 30),
        .init(handle: "reese.types", delay: 450, text: "Finished a layout proof this morning. The smallest caption finally has enough room to breathe.", replyHandle: "amara.finch", reply: "Clear captions make such a difference to the whole page.", replyDelay: 50),
        .init(handle: "little.sprout", delay: 600, text: "The cuttings have new leaves. Time to find a few small pots.", replyHandle: "leo.mercer", reply: "I have a couple of spare pots ready for the next swap.", replyDelay: 45)
    ]

    static func person(_ handle: String) -> LumaSocialCommunity.Person? {
        LumaSocialCommunity.people.first { $0.handle == handle }
    }

    static func historicalComments(for post: LumaSocialPost) -> [LumaSocialComment] {
        guard post.id == "b32-community-" + post.handle + "-0",
              let d = discussions.first(where: { $0.handle == post.handle }),
              let author = person(d.handle), author.name == post.author, author.channel == post.channel,
              let first = person(d.firstHandle), first.channel == post.channel,
              let second = person(d.secondHandle), second.channel == post.channel else { return [] }
        return [
            .init(id: post.id + "-discussion-01", postID: post.id, author: first.name, body: d.first, date: post.date.addingTimeInterval(1800)),
            .init(id: post.id + "-discussion-02", postID: post.id, author: second.name, body: d.second, date: post.date.addingTimeInterval(5400))
        ]
    }

    static func post(_ release: Release, start: Date) -> LumaSocialPost? {
        guard let owner = person(release.handle) else { return nil }
        return .init(id: release.id, channel: owner.channel, author: owner.name, handle: owner.handle,
                     body: release.text, date: start.addingTimeInterval(release.delay),
                     portrait: LumaSocialCommunity.portraits[owner.handle], photo: nil, gate: nil)
    }

    static func reply(_ release: Release, post: LumaSocialPost, start: Date) -> LumaSocialComment? {
        guard post.id == release.id, let peer = person(release.replyHandle), peer.channel == post.channel else { return nil }
        return .init(id: release.id + "-peer-01", postID: post.id, author: peer.name, body: release.reply,
                     date: start.addingTimeInterval(release.delay + release.replyDelay))
    }
}
