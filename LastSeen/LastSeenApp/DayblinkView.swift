import SwiftUI
import UIKit

enum DayblinkFriend: String, Codable, CaseIterable, Identifiable {
    case maya, lily, tessa
    var id: String { rawValue }
    var name: String {
        switch self {
        case .maya: return "Maya Brooks"
        case .lily: return "Lily Bennett"
        case .tessa: return "Tessa Reed"
        }
    }
    var handle: String {
        switch self {
        case .maya: return "maya.b"
        case .lily: return "lily.b"
        case .tessa: return "tessa.r"
        }
    }
    var portrait: String {
        switch self {
        case .maya: return "Contact_Maya"
        case .lily: return "Contact_B27_03"
        case .tessa: return "Contact_B27_07"
        }
    }
    var bio: String {
        switch self {
        case .maya: return "Books, coffee and time with friends."
        case .lily: return "Little moments and playlists."
        case .tessa: return "Art, design and everyday things."
        }
    }
}
struct DayblinkRecord: Codable, Equatable, Identifiable {
    let id: String
    let friend: DayblinkFriend
    let sender: String
    let text: String
    let date: Date
    var image: String? = nil
    var temporary = false
    var alreadyExpired = false
}
struct DayblinkPending: Codable, Equatable {
    let record: DayblinkRecord
    let due: Date
}
struct DayblinkState: Codable, Equatable {
    var opened: Set<String> = []
    var messages: [DayblinkRecord] = []
    var pending: [DayblinkPending] = []
    var muted: Set<DayblinkFriend> = []
    var notificationsEnabled = true
    var previewsEnabled = false
    var storyStart: Date? = nil
    var stories: [DayblinkStory]? = nil
    var viewedStories: Set<String>? = nil
}

struct DayblinkStory: Codable, Equatable, Identifiable {
    let id: String
    let friend: DayblinkFriend
    let caption: String
    let image: String
    let published: Date
    let expires: Date
    var expired: Bool = false
}
enum DayblinkArchive {
    // Public, licensed illustrations only. These are shared pictures, not
    // evidence, personal captures, camera access or claims of local geography.
    static let publicImages: Set<String> = ["CommunityMedia_Coffee", "CommunityMedia_Tabby", "CommunityMedia_Forest", "CommunityMedia_Udon", "CommunityMedia_Fox", "CommunityMedia_Mountains"]
    struct PictureChoice: Identifiable {
        let asset: String
        let title: String
        var id: String { asset }
    }
    static let pictureChoices: [PictureChoice] = [
        .init(asset: "CommunityMedia_Coffee", title: "Coffee"), .init(asset: "CommunityMedia_Tabby", title: "Cat"),
        .init(asset: "CommunityMedia_Forest", title: "Woodland"), .init(asset: "CommunityMedia_Udon", title: "Noodles"),
        .init(asset: "CommunityMedia_Fox", title: "Wildlife"), .init(asset: "CommunityMedia_Mountains", title: "Mountains")
    ]
    static func stories(start: Date) -> [DayblinkStory] {
        let entries: [(DayblinkFriend, String, String, TimeInterval)] = [
            (.maya, "A little lunch inspiration.", "CommunityMedia_Udon", 120),
            (.lily, "Saving this for a little animal appreciation.", "CommunityMedia_Fox", 210),
            (.tessa, "A softer palette for today.", "CommunityMedia_Mountains", 330)
        ]
        return entries.map { friend, caption, image, delay in
            let date = start.addingTimeInterval(delay)
            return .init(id: "dayblink-story-" + friend.id + "-01", friend: friend, caption: caption,
                         image: image, published: date, expires: date.addingTimeInterval(86400))
        }
    }
    static func activeStories(_ world: PhoneWorld) -> [DayblinkStory] {
        guard world.everydayArchiveRevision != nil else { return [] }
        return (world.connectedWorld?.dayblink?.stories ?? []).filter { !$0.expired && publicImages.contains($0.image) }
            .sorted { ($0.published, $0.id) > ($1.published, $1.id) }
    }
    static func records(_ world: PhoneWorld, friend: DayblinkFriend) -> [DayblinkRecord] {
        guard world.everydayArchiveRevision != nil else { return [] }
        let d = world.createdAt
        func historic(_ id: String, _ text: String, _ offset: Double, image: String? = nil, temporary: Bool = false, expired: Bool = false) -> DayblinkRecord {
            .init(id: "dayblink-" + friend.id + "-" + id, friend: friend, sender: friend.name, text: text, date: d.addingTimeInterval(-offset), image: image, temporary: temporary, alreadyExpired: expired)
        }
        let history: [DayblinkRecord]
        switch friend {
        case .maya:
            history = [historic("saved", "A little coffee inspiration for later.", 680000, image: "CommunityMedia_Coffee"),
                       historic("expired", "An older visual message.", 510000, temporary: true, expired: true)]
        case .lily:
            history = [historic("saved", "Look at this little face!", 720000, image: "CommunityMedia_Tabby"),
                       historic("expired", "An older visual message.", 425000, temporary: true, expired: true)]
        case .tessa:
            history = [historic("saved", "Keeping this woodland picture for color inspiration.", 610000, image: "CommunityMedia_Forest"),
                       historic("expired", "An older visual message.", 390000, temporary: true, expired: true)]
        }
        return (history + (world.connectedWorld?.dayblink?.messages ?? []).filter { $0.friend == friend }).sorted { ($0.date, $0.id) < ($1.date, $1.id) }
    }
    static func image(for record: DayblinkRecord, state: DayblinkState) -> String? {
        guard !record.alreadyExpired, !(record.temporary && state.opened.contains(record.id)),
              let image = record.image, publicImages.contains(image) else { return nil }
        return image
    }
    /// Only an explicitly consumed message can remain in the current viewer.
    static func viewingRecord(_ id:String,friend:DayblinkFriend,world:PhoneWorld)->DayblinkRecord? {
        guard world.connectedWorld?.dayblink?.opened.contains(id)==true,
              let record=records(world,friend:friend).first(where:{$0.id==id}),
              record.temporary,!record.alreadyExpired,
              let asset=record.image,publicImages.contains(asset) else{return nil}
        return record
    }
    static func saved(_ world:PhoneWorld)->[DayblinkRecord] {
        let state=world.connectedWorld?.dayblink ?? DayblinkState()
        return DayblinkFriend.allCases.flatMap{records(world,friend:$0)}
            .filter{!$0.temporary && image(for:$0,state:state) != nil}
            .sorted{($0.date,$0.id)>($1.date,$1.id)}
    }
    static func pendingReply(friend: DayblinkFriend, text: String, id: String, now: Date, previousCount: Int = 0, sharedImage: String? = nil) -> DayblinkPending? {
        let clean = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let words = Set(clean.split { !$0.isLetter }.map(String.init))
        guard (0..<3).contains(previousCount),
              sharedImage != nil || ["thanks", "thank you", "nice picture", "love this", "hello", "hi"].contains(clean) ||
              !words.isDisjoint(with: ["photo","picture","coffee","cat","art","color","nature","hello","thanks"]) else { return nil }
        let choices: [(String, String)]
        switch friend {
        case .maya: choices = [("A little coffee break for your day.", "CommunityMedia_Coffee"), ("This looks like a nice lunch idea.", "CommunityMedia_Udon"), ("A little scenery to end the day.", "CommunityMedia_Mountains")]
        case .lily: choices = [("A cat picture is always a good idea.", "CommunityMedia_Tabby"), ("One more animal picture for the collection.", "CommunityMedia_Fox"), ("Something cozy to look at.", "CommunityMedia_Coffee")]
        case .tessa: choices = [("Something green to brighten the screen.", "CommunityMedia_Forest"), ("I like the colors in this landscape.", "CommunityMedia_Mountains"), ("Here's another palette idea.", "CommunityMedia_Udon")]
        }
        let (caption, asset) = choices[previousCount]
        let due = now.addingTimeInterval(friend == .maya ? 14 : friend == .lily ? 21 : 34)
        return .init(record: .init(id: "dayblink-reply-" + id, friend: friend, sender: friend.name, text: caption, date: due, image: asset, temporary: true), due: due)
    }
}
struct DayblinkView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    private var state: DayblinkState { world.connected.dayblink ?? DayblinkState() }
    var body: some View {
        List {
            Section {
                LumaHeader(title: "Dayblink", detail: "Little things, shared privately", symbol: "camera.fill")
                Text("Restored conversations · Local simulation").font(.caption).foregroundColor(.secondary)
            }
            if world.state.everydayArchiveRevision == nil {
                Section { Label("Restore the phone archive to continue.", systemImage: "lock.fill") }
            } else {
                Section("Friends") {
                    ForEach(DayblinkFriend.allCases) { friend in
                        NavigationLink { DayblinkThread(friend: friend) } label: {
                            HStack(spacing: 12) {
                                DayblinkAvatar(friend: friend, size: 44)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(friend.name).font(.headline)
                                    Text("@" + friend.handle).font(.caption).foregroundColor(.secondary)
                                    let records = DayblinkArchive.records(world.state, friend: friend)
                                    if records.contains(where: { $0.temporary && DayblinkArchive.image(for: $0, state: state) != nil }) {
                                        Label("New visual message", systemImage: "square.fill").font(.caption).foregroundColor(.yellow)
                                    } else { Text("Restored conversation").font(.caption2).foregroundColor(.secondary) }
                                }
                                Spacer()
                                if state.muted.contains(friend) { Image(systemName: "bell.slash").foregroundColor(.secondary) }
                            }
                        }
                    }
                }
                Section("Your account") {
                    NavigationLink { DayblinkSettings() } label: {
                        Label("Profile, friends & privacy", systemImage: "person.crop.circle")
                    }
                    NavigationLink { DayblinkSavedView() } label: {
                        Label("Saved memories", systemImage: "bookmark")
                    }
                }
                Section("Stories") {
                    let stories = DayblinkArchive.activeStories(world.state)
                    if stories.isEmpty { Text("No active stories.").font(.subheadline).foregroundColor(.secondary) }
                    ForEach(stories) { story in
                        NavigationLink { DayblinkStoryView(id: story.id) } label: {
                            HStack(spacing: 12) {
                                DayblinkAvatar(friend: story.friend, size: 44)
                                    .overlay(Circle().stroke((state.viewedStories ?? []).contains(story.id) ? Color.gray : Color.yellow, lineWidth: 2).padding(-3))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(story.friend.name).font(.headline)
                                    Text((state.viewedStories ?? []).contains(story.id) ? "Viewed" : "New story").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(story.published, style: .relative).font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }
                    Text("Stories expire after 24 hours in the local simulation.").font(.caption).foregroundColor(.secondary)
                }
            }
        }.navigationTitle("Dayblink").navigationBarTitleDisplayMode(.inline)
    }
}
struct DayblinkAvatar: View {
    let friend: DayblinkFriend
    let size: CGFloat
    var body: some View {
        Image(friend.portrait).resizable().scaledToFill().frame(width: size, height: size).clipShape(Circle()).accessibilityHidden(true)
    }
}
struct DayblinkThread: View {
    let friend: DayblinkFriend
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var text = ""
    @FocusState private var composerFocused:Bool
    @State private var feedback = ""
    @State private var openedRecordID: String?
    @State private var showingImage = false
    @State private var selectedPicture: String? = nil
    @State private var showPictures = false
    @Environment(\.scenePhase) private var phase
    private var state: DayblinkState { world.connected.dayblink ?? DayblinkState() }
    private var currentVisual:DayblinkRecord? {
        guard phase == .active,let id=openedRecordID else{return nil}
        return DayblinkArchive.viewingRecord(id,friend:friend,world:world.state)
    }
    private func closeVisual(){showingImage=false;openedRecordID=nil}
    var body: some View {
        List {
            if world.state.everydayArchiveRevision != nil {
                Section {
                    NavigationLink {
                        DayblinkFriendProfile(friend: friend)
                    } label: {
                        HStack { DayblinkAvatar(friend: friend, size: 42); Text(friend.name).font(.headline) }
                    }
                }
                Section("Conversation") {
                    ForEach(DayblinkArchive.records(world.state, friend: friend)) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(record.sender).font(.caption.bold())
                                Spacer()
                                Text(record.date, style: .date).font(.caption2).foregroundColor(.secondary)
                            }
                            if record.temporary {
                                if DayblinkArchive.image(for:record,state:state) != nil {
                                    Button {
                                        guard phase == .active else{return}
                                        if world.openDayblink(record.id,friend:friend) {
                                            openedRecordID=record.id;showingImage=true
                                        }
                                    } label:{Label("Open once",systemImage:"square.fill").foregroundColor(.yellow)}
                                } else {
                                    Label(state.opened.contains(record.id) ? "Visual message opened":"Visual message expired",systemImage:"square.dashed").foregroundColor(.secondary)
                                }
                            } else {
                                Text(record.text)
                                if let asset = DayblinkArchive.image(for: record, state: state) {
                                    Image(asset).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }.padding(.vertical, 5)
                    }
                }
                Section("Send as Repair desk") {
                    TextField("Write a local message", text: $text, axis: .vertical)
                        .lineLimit(1...5).focused($composerFocused)
                    if let selectedPicture {
                        HStack {
                            Image(selectedPicture).resizable().scaledToFill().frame(width: 56, height: 56).clipped().clipShape(RoundedRectangle(cornerRadius: 8))
                            Text("Selected picture").font(.caption)
                            Spacer()
                            Button("Remove") { self.selectedPicture = nil }.font(.caption)
                        }
                    }
                    Button { composerFocused=false;showPictures = true } label: { Label("Add a picture", systemImage: "photo.on.rectangle") }
                    Text("\(text.count) / 500").font(.caption).foregroundColor(.secondary)
                    Button("Send") {
                        guard phase == .active else{return}
                        if world.sendDayblink(friend: friend, text: text, image: selectedPicture) {
                            text = ""; feedback = ""; selectedPicture = nil;composerFocused=false
                        } else { feedback = "Enter a shorter message or choose an available picture." }
                    }.disabled((text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && selectedPicture==nil) || text.count>500 || phase != .active)
                    if !feedback.isEmpty { Text(feedback).font(.caption).foregroundColor(.secondary) }
                    Text("The restored owner account is read-only. Responses are authored and local, not live messages.").font(.caption).foregroundColor(.secondary)
                }
            } else { Text("Conversation unavailable") }
        }.navigationTitle(friend.name).scrollDismissesKeyboard(.interactively)
            .toolbar {ToolbarItemGroup(placement:.keyboard){Spacer();Button("Done"){composerFocused=false}}}
            .onChange(of:phase){if $0 != .active {composerFocused=false;closeVisual();showPictures=false}}
            .onChange(of:world.checkpointEpoch){_ in
                composerFocused=false;closeVisual();showPictures=false;selectedPicture=nil;text="";feedback=""
            }
            .onChange(of:currentVisual?.id){if $0==nil {closeVisual()}}
            .onDisappear {closeVisual()}
            .sheet(isPresented: $showPictures) {
                NavigationStack {
                    List {
                        ForEach(DayblinkArchive.pictureChoices) { choice in
                            Button {
                                guard phase == .active,world.state.everydayArchiveRevision != nil else{return}
                                selectedPicture = choice.asset; showPictures = false
                            } label: {
                                HStack {
                                    Image(choice.asset).resizable().scaledToFill().frame(width: 64, height: 52).clipped().clipShape(RoundedRectangle(cornerRadius: 8))
                                    Text(choice.title)
                                }
                            }
                        }
                        Text("Shared illustrations from the fictional phone only. No real photo library or camera.").font(.caption).foregroundColor(.secondary)
                    }.navigationTitle("Choose a picture")
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showPictures = false } } }
                }
            }
            .sheet(isPresented:$showingImage,onDismiss:{openedRecordID=nil}) {
                NavigationStack {
                    VStack(spacing: 16) {
                        if let record=currentVisual,let asset=record.image {
                            Image(asset).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius:12))
                            Text(record.text)
                            Text("Available for this viewing only.").font(.caption).foregroundColor(.secondary)
                        } else {Text("Visual message unavailable.").foregroundColor(.secondary)}
                    }.padding().navigationTitle("Visual message")
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done"){closeVisual()} } }
                }
            }
    }
}
struct DayblinkStoryView: View {
    let id: String
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    private var story: DayblinkStory? { DayblinkArchive.activeStories(world.state).first { $0.id == id } }
    var body: some View {
        ScrollView {
            if let story, phase == .active {
                VStack(alignment: .leading, spacing: 14) {
                    HStack { DayblinkAvatar(friend: story.friend, size: 42); Text(story.friend.name).font(.headline); Spacer() }
                    Image(story.image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 16))
                    Text(story.caption).font(.title3)
                    Text("Shared illustration · Temporary story").font(.caption).foregroundColor(.secondary)
                    Text("Expires " + story.expires.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundColor(.secondary)
                }.padding(16)
            } else { Text("Story unavailable").padding() }
        }.navigationTitle("Story").navigationBarTitleDisplayMode(.inline)
            .onAppear {if phase == .active {world.markDayblinkStoryViewed(id)}}
            .onChange(of:phase){if $0 == .active {world.markDayblinkStoryViewed(id)}}
    }
}
struct DayblinkFriendProfile: View {
    let friend: DayblinkFriend
    @EnvironmentObject private var world: PhoneWorldStore
    private var state: DayblinkState { world.connected.dayblink ?? DayblinkState() }
    var body: some View {
        Form {
            if world.state.everydayArchiveRevision != nil {
                Section {
                    HStack(spacing: 14) {
                        DayblinkAvatar(friend: friend, size: 66)
                        VStack(alignment: .leading) { Text(friend.name).font(.title2.bold()); Text("@" + friend.handle).foregroundColor(.secondary) }
                    }
                    Text(friend.bio)
                }
                Section("Friend settings") {
                    Toggle("Mute notifications", isOn: Binding(get: { state.muted.contains(friend) }, set: { world.setDayblinkMuted(friend, muted: $0) }))
                }
            }
        }.navigationTitle("Friend profile")
    }
}
struct DayblinkSettings: View {
    @EnvironmentObject private var world: PhoneWorldStore
    private var state: DayblinkState { world.connected.dayblink ?? DayblinkState() }
    var body: some View {
        Form {
            Section("Restored account") {
                HStack(spacing: 12) {
                    Image("Nora_Profile").resizable().scaledToFill().frame(width: 54, height: 54).clipShape(Circle())
                    VStack(alignment: .leading) { Text("Nora Bennett").font(.headline); Text("@nora.b").font(.caption).foregroundColor(.secondary) }
                }
                LabeledContent("Account access", value: "Read-only")
                LabeledContent("Visual messages", value: "Open once")
            }
            Section("Privacy & notifications") {
                Toggle("Notifications", isOn: Binding(get: { state.notificationsEnabled }, set: { world.setDayblinkNotificationSettings(enabled: $0, previews: state.previewsEnabled) }))
                Toggle("Show previews", isOn: Binding(get: { state.previewsEnabled }, set: { world.setDayblinkNotificationSettings(enabled: state.notificationsEnabled, previews: $0) }))
                Text("No real camera, contacts, location or network access.").font(.caption).foregroundColor(.secondary)
            }
            Section("Muted friends") {
                if state.muted.isEmpty { Text("No muted friends").foregroundColor(.secondary) }
                ForEach(DayblinkFriend.allCases.filter { state.muted.contains($0) }) { friend in
                    Button("Unmute " + friend.name) { world.setDayblinkMuted(friend, muted: false) }
                }
            }
        }.navigationTitle("Account & privacy")
    }
}
struct DayblinkSavedView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    var body: some View {
        List {
            let records=DayblinkArchive.saved(world.state)
            if records.isEmpty {Text("No saved pictures").foregroundColor(.secondary)}
            ForEach(records) { record in
                if let asset = DayblinkArchive.image(for: record, state: world.connected.dayblink ?? DayblinkState()) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(asset).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 10))
                        Text(record.sender).font(.headline)
                        Text(record.text).font(.subheadline)
                    }
                }
            }
        }.navigationTitle("Saved memories")
    }
}
