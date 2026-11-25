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
        .init(name: "Sam Rivera", handle: "sam.rivera", bio: "Board games • cooking • local events", channel: .commonGround, first: "Thinking of organizing a relaxed board game evening. Beginners absolutely welcome.", second: "Does anyone have a reliable recipe for cinnamon rolls? Mine are more like cinnamon bricks.")
    ]
    static func posts(anchor: Date) -> [LumaSocialPost] {
        people.enumerated().flatMap { index, person in
            [person.first, person.second].enumerated().map { number, body in
                LumaSocialPost(id: "b32-community-" + person.handle + "-" + String(number), channel: person.channel, author: person.name, handle: person.handle, body: body, date: anchor.addingTimeInterval(-Double(3 + index + number * 11) * 86400 - 7200), portrait: nil, photo: nil, gate: nil)
            }
        }
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
                Text("Notification preferences are saved for this app. Live social delivery is not yet available.").font(.caption).foregroundColor(.secondary)
            }
            Section("Muted profiles") {
                if prefs.mutedAuthors.isEmpty { Text("No muted profiles").foregroundColor(.secondary) }
                ForEach(prefs.mutedAuthors.sorted(), id: \.self) { author in
                    Button("Unmute " + author) { world.toggleSocialMute(author, channel: channel) }
                }
            }
            Section("Your local activity") {
                LabeledContent("Saved posts", value: String(LumaSocialCatalog.visible(channel, world: world.state).filter { world.connected.savedPosts.contains($0.id) }.count))
                LabeledContent("Following", value: String(world.connected.follows.filter { $0.hasPrefix(channel.rawValue + "|") }.count))
            }
        }.navigationTitle("Account & settings")
    }
}
