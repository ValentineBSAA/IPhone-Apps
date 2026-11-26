import SwiftUI

struct LumaSocialPreferences: Codable, Equatable {
    var mutedAuthors: Set<String> = []
    var notificationsEnabled = true
    var showPreviews = true
}

enum LumaSocialCommunity {
    struct Person {
        let name: String
        let handle: String
        let bio: String
        let channel: LumaSocialChannel
        let first: String
        let second: String
    }
    static let people: [Person] = [
        .init(name: "Iris Vale", handle: "iris.vale", bio: "Illustrator • weekend ceramics", channel: .afterframe, first: "Finally glazed the little blue bowl. It only took three attempts and a very patient teacher.", second: "The handle on my latest mug is slightly crooked. It has character, apparently."),
        .init(name: "Miles Chen", handle: "miles.frames", bio: "Hobby photographer • walks and architecture", channel: .afterframe, first: "The light on the brickwork this morning was worth getting up early for.", second: "Left the camera at home today. Sometimes a walk can just be a walk."),
        .init(name: "Sofia Hart", handle: "sofia.hart", bio: "Home cooking and gardening", channel: .afterframe, first: "The basil has survived another week. The kitchen smells wonderful.", second: "Tried making bread again. Much better when I actually read the recipe."),
        .init(name: "Evan Park", handle: "evan.codes", bio: "Independent accessibility consultant", channel: .connective, first: "A usability session is more useful when people can describe what confused them in their own words.", second: "Spent the afternoon reviewing contrast and keyboard navigation. Small details add up."),
        .init(name: "Amara Finch", handle: "amara.finch", bio: "Freelance editor • small business owner", channel: .connective, first: "A project brief should explain who the work is for before listing everything it needs to contain.", second: "My favorite project milestone is a clear, kind handoff."),
        .init(name: "Rowan Bell", handle: "rowan.audio", bio: "Independent sound designer", channel: .connective, first: "Testing sound at a comfortable volume matters. A cue should communicate without overwhelming the listener.", second: "Finished a small collection of original interface sounds this week. Taking tomorrow off."),
        .init(name: "June Ellis", handle: "june.reads", bio: "Reader • community events", channel: .commonGround, first: "Anyone interested in a casual book swap next month? No need to bring anything fancy.", second: "Finished the short story collection from the reading group. Would happily lend it out."),
        .init(name: "Leo Mercer", handle: "leo.mercer", bio: "Cycling • neighborhood gardening", channel: .commonGround, first: "The community planter could use a little attention this weekend. I'll bring spare gloves.", second: "Found a nice quiet route for my evening ride. Glad the weather held."),
        .init(name: "Sam Rivera", handle: "sam.rivera", bio: "Board games • cooking • local events", channel: .commonGround, first: "Thinking of organizing a relaxed board game evening. Beginners absolutely welcome.", second: "Does anyone have a reliable recipe for cinnamon rolls? Mine are more like cinnamon bricks."),
        .init(name: "Devon Price", handle: "devon.trails", bio: "Trail maps, weather and walking", channel: .afterframe, first: "Saving this mountain view for the next rainy afternoon. Anyone else collect pictures of places they'd like to walk?", second: "A short walk counts. Not every weekend needs an expedition."),
        .init(name: "Ellis Morgan", handle: "ellis.mugs", bio: "Coffee enthusiast • amateur cook", channel: .afterframe, first: "An espresso appreciation post. The tiny cup is somehow the best part.", second: "Bought a kitchen scale and immediately discovered how inconsistent my coffee measurements were."),
        .init(name: "Mina Foster", handle: "mina.paws", bio: "Cat person • home projects", channel: .afterframe, first: "This tabby photo is an instant mood improvement. Look at that little expression.", second: "My weekend project is organizing a cupboard that has been fighting back for months."),
        .init(name: "Noah Grant", handle: "noah.access", bio: "Freelance interface designer", channel: .connective, first: "When a prototype fails a usability check, write down the failure before redesigning. Otherwise you can solve the wrong problem.", second: "I keep a reusable checklist for focus order, readable labels and large text."),
        .init(name: "Clara West", handle: "clara.prints", bio: "Independent printmaker • small shop", channel: .connective, first: "The most useful shop update this month was a clearer description of delivery windows. Nothing glamorous, but fewer confused messages.", second: "Finally set aside an afternoon to organize my invoices. Future me deserves the favor."),
        .init(name: "Jasper Lane", handle: "jasper.tools", bio: "Indie software developer", channel: .connective, first: "A tiny tool with one reliable job is often more valuable than a large dashboard nobody understands.", second: "Today's reminder: test an upgrade with an existing save, not just a fresh install."),
        .init(name: "Nina Wells", handle: "nina.wild", bio: "Wildlife photos • quiet walks", channel: .commonGround, first: "Sharing a fox photograph for the wildlife thread. Please give wild animals plenty of distance.", second: "Any recommendations for a beginner-friendly field guide? I keep mixing up the local birds."),
        .init(name: "Owen Reed", handle: "owen.noodles", bio: "Home cooking • recipe swaps", channel: .commonGround, first: "A bowl of udon is a pretty convincing argument for a noodle night. Sharing this as dinner inspiration.", second: "I finally learned to prepare ingredients before turning the stove on. It only took several very chaotic dinners."),
        .init(name: "Avery Quinn", handle: "avery.green", bio: "Plants • books • outdoor photography", channel: .commonGround, first: "Saving this woodland photograph as inspiration for a tiny fern corner at home.", second: "If anyone has tips for keeping a houseplant alive through winter, I'm listening.")
,
        .init(name: "Morgan Hale", handle: "morgan.stitches", bio: "Sewing • repairs • slow weekends", channel: .afterframe, first: "Mended the pocket on my favorite jacket instead of replacing it. Very satisfying.", second: "The fabric shop had an entire shelf of odd buttons. I resisted almost all of them."),
        .init(name: "Riley Shaw", handle: "riley.runs", bio: "Early walks • running journals", channel: .afterframe, first: "Took the shorter route this morning and still felt better for getting outside.", second: "The rain sounded lovely once I was home with dry socks."),
        .init(name: "Taylor Brooks", handle: "taylor.clay", bio: "Pottery • sketchbooks", channel: .afterframe, first: "My clay bowl finally holds water. A tiny but very welcome milestone.", second: "Trying a pale green glaze next. The test tiles are drying on the windowsill."),
        .init(name: "Casey Flynn", handle: "casey.kitchen", bio: "Weekend baker • meal planning", channel: .afterframe, first: "Made enough soup for the next few lunches. Future me is going to be delighted.", second: "I think the secret to my bread is leaving it alone for longer than I want to."),
        .init(name: "Drew Carter", handle: "drew.paper", bio: "Stationery • handwritten letters", channel: .afterframe, first: "Found a notebook with paper that doesn't bleed through. Small victory.", second: "Writing a few thank-you cards tonight before I forget again."),
        .init(name: "Jamie Patel", handle: "jamie.maps", bio: "Transit and urban design", channel: .connective, first: "A useful map answers where to go next before it tries to show everything.", second: "Spent the morning simplifying a set of direction signs. Fewer words helped."),
        .init(name: "Reese Kim", handle: "reese.types", bio: "Editorial design • typography", channel: .connective, first: "A readable type hierarchy is worth more than another decorative element.", second: "Checking the smallest labels in a design before approving the large screens."),
        .init(name: "Cameron Ellis", handle: "cam.records", bio: "Independent records coordinator", channel: .connective, first: "A filing convention only works if the entire team understands it.", second: "Archived the completed folders today. The desk finally feels less crowded."),
        .init(name: "Alexis Stone", handle: "alexis.studio", bio: "Craft teacher • workshop planning", channel: .connective, first: "Leaving a few extra minutes at the end of a class makes cleanup much less stressful.", second: "Rewriting the materials list so beginners don't have to guess what to bring."),
        .init(name: "Blair Sutton", handle: "blair.repair", bio: "Electronics repair • tinkering", channel: .connective, first: "Labeling tiny screws before taking something apart is a very worthwhile habit.", second: "Repaired an old lamp this afternoon. Glad I kept the spare parts."),
        .init(name: "Robin Fletcher", handle: "robin.seedlings", bio: "Retired librarian • community garden", channel: .commonGround, first: "The seedlings are ready to move into larger pots. I've got a few spares if anyone wants one.", second: "Finished sorting a box of donated books. Some lovely forgotten titles in there."),
        .init(name: "Harper Monroe", handle: "harper.knits", bio: "Knitting • family recipes", channel: .commonGround, first: "Finally finished the scarf I started before the weather changed.", second: "Does anyone have a favorite pattern for using up small amounts of leftover yarn?"),
        .init(name: "Parker Doyle", handle: "parker.records", bio: "Record collecting • neighborhood walks", channel: .commonGround, first: "Played an old jazz record while making breakfast. A rather nice start to the day.", second: "Sorting the record sleeves this weekend. Somehow the alphabet always gets away from me."),
        .init(name: "Leslie Ford", handle: "leslie.mends", bio: "Woodworking • community workshops", channel: .commonGround, first: "Sanded down a little wooden shelf that has been waiting in the garage for months.", second: "The workshop has spare sandpaper if anyone is finishing a small project."),
        .init(name: "The Cat Window", handle: "cat.window", bio: "Illustrated cat appreciation account", channel: .afterframe, first: "A reminder to give the cat the sunny chair. Apparently it was never ours.", second: "Today's tiny joy: a cat discovering a perfectly ordinary cardboard box."),
        .init(name: "Good Dog Notes", handle: "gooddog.notes", bio: "Dog walks • pet care reminders", channel: .commonGround, first: "A slow sniff-filled walk is still a good walk.", second: "Remember the water bowl when heading out on a longer afternoon walk."),
        .init(name: "Quiet Summit", handle: "quiet.summit", bio: "Illustrated outdoor inspiration", channel: .afterframe, first: "Collecting mountain pictures for the days when a walk isn't on the cards.", second: "The best outdoor plan is the one you can enjoy safely at your own pace."),
        .init(name: "Little Sprout Club", handle: "little.sprout", bio: "Houseplants • gardening ideas", channel: .commonGround, first: "A small plant swap sounds lovely. Cuttings welcome, fancy pots optional.", second: "Checking the soil before watering has saved more plants than any fancy gadget.")
    ]
    static let portraits: [String: String] = [
        "iris.vale": "CommunityPortrait_11",
        "miles.frames": "CommunityPortrait_17",
        "sofia.hart": "CommunityPortrait_13",
        "evan.codes": "CommunityPortrait_02",
        "amara.finch": "CommunityPortrait_09",
        "rowan.audio": "CommunityPortrait_08",
        "june.reads": "CommunityPortrait_04",
        "leo.mercer": "CommunityPortrait_07",
        "sam.rivera": "CommunityPortrait_15",
        "devon.trails": "CommunityPortrait_01",
        "ellis.mugs": "CommunityPortrait_03",
        "mina.paws": "CommunityPortrait_10",
        "noah.access": "CommunityPortrait_06",
        "clara.prints": "CommunityPortrait_12",
        "jasper.tools": "CommunityPortrait_05",
        "nina.wild": "CommunityPortrait_16",
        "owen.noodles": "CommunityPortrait_14",
        "avery.green": "CommunityPortrait_18",
        "morgan.stitches": "CommunityReserve_01",
        "riley.runs": "CommunityReserve_02",
        "taylor.clay": "CommunityReserve_03",
        "casey.kitchen": "CommunityReserve_04",
        "drew.paper": "CommunityReserve_05",
        "jamie.maps": "CommunityReserve_06",
        "reese.types": "CommunityReserve_07",
        "cam.records": "CommunityReserve_08",
        "alexis.studio": "CommunityReserve_09",
        "blair.repair": "CommunityReserve_10",
        "robin.seedlings": "CommunityOlder_1",
        "harper.knits": "CommunityOlder_2",
        "parker.records": "CommunityOlder_3",
        "leslie.mends": "CommunityOlder_4",
        "cat.window": "CommunityAvatar_Cat",
        "gooddog.notes": "CommunityAvatar_Dog",
        "quiet.summit": "CommunityAvatar_Mountain",
        "little.sprout": "CommunityAvatar_Gardening"
    ]
    // Exact authored record-to-media map. Never resolve arbitrary photo names
    // through the community catalog, or treat these as Nora's photographs.
    static let photoAssignments: [String: String] = [
        "b32-community-devon.trails-0": "CommunityMedia_Mountains",
        "b32-community-ellis.mugs-0": "CommunityMedia_Coffee",
        "b32-community-mina.paws-0": "CommunityMedia_Tabby",
        "b32-community-nina.wild-0": "CommunityMedia_Fox",
        "b32-community-owen.noodles-0": "CommunityMedia_Udon",
        "b32-community-avery.green-0": "CommunityMedia_Forest"
    ]
    static func posts(anchor: Date) -> [LumaSocialPost] {
        people.enumerated().flatMap { index, person in
            [person.first, person.second].enumerated().map { number, body in
                let id = "b32-community-" + person.handle + "-" + String(number)
                return LumaSocialPost(id: id, channel: person.channel, author: person.name, handle: person.handle, body: body, date: anchor.addingTimeInterval(-Double(3 + index + number * 11) * 86400 - 7200), portrait: portraits[person.handle], photo: photoAssignments[id], gate: nil)
            }
        }
    }
    static func publicPhoto(_ post: LumaSocialPost) -> String? {
        guard let asset = photoAssignments[post.id], asset == post.photo,
              people.contains(where: { $0.name == post.author && $0.handle == post.handle && $0.channel == post.channel }) else { return nil }
        return asset
    }
    static func bio(author: String, channel: LumaSocialChannel) -> String? {
        if let person = people.first(where: { $0.name == author && $0.channel == channel }) { return person.bio }
        switch author {
        case "Nora Bennett":
            switch channel {
            case .afterframe: return "Little moments, late nights, music and coffee."
            case .connective: return "Founder and lead developer · Blue Hour Interactive"
            case .commonGround: return "Local reader, game developer and coffee enthusiast."
            }
        case "Blue Hour Interactive": return "Independent mobile games and apps · Studio updates"
        case "Maya Brooks": return "Books, coffee and time with friends."
        case "Lily Bennett": return "Art, playlists and small everyday adventures."
        case "Adrian Cole": return "Technical lead · Blue Hour Interactive"
        case "Tessa Reed": return "Artist and producer · Blue Hour Interactive"
        default: return nil
        }
    }
}

struct LumaSocialAccountView: View {
    let channel: LumaSocialChannel
    @EnvironmentObject private var world: PhoneWorldStore
    private var prefs: LumaSocialPreferences { world.socialPreferences(channel) }
    var body: some View {
        List {
            Section("Restored account") {
                NavigationLink { LumaSocialProfile(channel: channel, author: "Nora Bennett") } label: {
                    HStack {
                        Image("Nora_Profile").resizable().scaledToFill().frame(width: 48, height: 48).clipShape(Circle())
                        VStack(alignment: .leading) { Text("Nora Bennett").font(.headline); Text("@nora.b").font(.caption).foregroundColor(.secondary) }
                    }
                }
                if channel == .connective {
                    NavigationLink("Blue Hour Interactive · Company page") { LumaSocialProfile(channel: channel, author: "Blue Hour Interactive") }
                }
                LabeledContent("Access", value: "Restored snapshot")
                Text("Owner profile is read-only. New local posts use the Repair desk identity.").font(.caption).foregroundColor(.secondary)
            }
            Section("Local viewing preferences") {
                Toggle("App notifications", isOn: Binding(get: { prefs.notificationsEnabled }, set: { value in var next = prefs; next.notificationsEnabled = value; world.setSocialPreferences(next, channel: channel) }))
                Toggle("Notification previews", isOn: Binding(get: { prefs.showPreviews }, set: { value in var next = prefs; next.showPreviews = value; world.setSocialPreferences(next, channel: channel) }))
                Text("These preferences apply to new local community replies. Restored posts remain available.").font(.caption).foregroundColor(.secondary)
            }
            Section("Muted profiles") {
                if prefs.mutedAuthors.isEmpty { Text("No muted profiles").foregroundColor(.secondary) }
                ForEach(prefs.mutedAuthors.sorted(), id: \.self) { author in
                    Button("Unmute " + author) { world.toggleSocialMute(author, channel: channel) }
                }
            }
            Section("Discover people") {
                NavigationLink("Browse all profiles") { LumaSocialDirectory(channel: channel) }
                NavigationLink("Following") { LumaSocialDirectory(channel: channel, followingOnly: true) }
            }
            Section("Your local activity") {
                LabeledContent("Saved posts", value: String(LumaSocialCatalog.visible(channel, world: world.state).filter { world.connected.savedPosts.contains($0.id) }.count))
                LabeledContent("Following", value: String(world.connected.follows.filter { $0.hasPrefix(channel.rawValue + "|") }.count))
            }
        }.navigationTitle("Account & settings")
    }
}

/// Browsable account directory derived from the actually accessible feed.
struct LumaSocialDirectory: View {
    let channel: LumaSocialChannel
    var followingOnly = false
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var query = ""
    private var accounts: [LumaSocialPost] {
        let posts = LumaSocialCatalog.visible(channel, world: world.state)
        var seen = Set<String>()
        return posts.filter { post in
            guard seen.insert(post.author).inserted else { return false }
            let following = world.connected.follows.contains(channel.rawValue + "|" + post.author)
            return (!followingOnly || following) && (query.isEmpty || [post.author, post.handle, LumaSocialCommunity.bio(author: post.author, channel: channel) ?? ""].contains { $0.localizedCaseInsensitiveContains(query) })
        }.sorted { $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
    }
    var body: some View {
        List {
            if accounts.isEmpty { Text(followingOnly ? "No followed accounts found." : "No matching profiles.").foregroundColor(.secondary) }
            ForEach(accounts) { post in
                NavigationLink { LumaSocialProfile(channel: channel, author: post.author) } label: {
                    HStack(spacing: 12) {
                        LumaSocialAvatar(post: post, size: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(post.author).font(.headline)
                            Text("@" + post.handle).font(.caption).foregroundColor(.secondary)
                            if let bio = LumaSocialCommunity.bio(author: post.author, channel: channel) {
                                Text(bio).font(.caption2).foregroundColor(.secondary).lineLimit(2)
                            }
                        }
                    }.padding(.vertical, 4)
                }
            }
        }.navigationTitle(followingOnly ? "Following" : "Discover people")
            .searchable(text: $query, prompt: "Names, interests or usernames")
    }
}

/// Original typographic fallback for fictional business/organization accounts.
/// Not an imported real corporate logo.
struct LumaSocialAvatar: View {
    let post: LumaSocialPost
    let size: CGFloat
    private var mark: String? {
        switch post.handle {
        case "bluehour": return "BH"
        case "maplebooks": return "MB"
        case "maplecafe": return "MC"
        case "ashstreet": return "AS"
        default: return nil
        }
    }
    var body: some View {
        Group {
            if let portrait = post.portrait {
                Image(portrait).resizable().scaledToFill()
            } else if let mark {
                ZStack {
                    LinearGradient(colors: [post.channel.accent.opacity(0.85), .black.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(mark).font(.system(size: size * 0.32, weight: .bold, design: .rounded)).foregroundColor(.white)
                }
            } else {
                ZStack {
                    Circle().fill(post.channel.accent.opacity(0.18))
                    Image(systemName: "person.crop.circle.fill").font(.system(size: size * 0.84)).foregroundColor(post.channel.accent)
                }
            }
        }.frame(width: size, height: size).clipShape(Circle()).accessibilityHidden(true)
    }
}
