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
}
enum DayblinkArchive {
    // Public, licensed illustrations only. These are shared pictures, not
    // evidence, personal captures, camera access or claims of local geography.
    static let publicImages: Set<String> = ["CommunityMedia_Coffee", "CommunityMedia_Tabby", "CommunityMedia_Forest"]
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
    static func pendingReply(friend: DayblinkFriend, text: String, id: String, now: Date) -> DayblinkPending? {
        let clean = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard ["thanks", "thank you", "nice picture", "love this", "hello", "hi"].contains(clean) else { return nil }
        let caption: String
        let asset: String
        switch friend {
        case .maya: caption = "A little coffee break for your day."; asset = "CommunityMedia_Coffee"
        case .lily: caption = "A cat picture is always a good idea."; asset = "CommunityMedia_Tabby"
        case .tessa: caption = "Something green to brighten the screen."; asset = "CommunityMedia_Forest"
        }
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
                    Text("No active stories recovered. Older temporary items are not restored as new activity.").font(.subheadline).foregroundColor(.secondary)
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
    @State private var feedback = ""
    @State private var openedImage: String?
    @State private var showingImage = false
    private var state: DayblinkState { world.connected.dayblink ?? DayblinkState() }
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
                                if let asset = DayblinkArchive.image(for: record, state: state) {
                                    Button {
                                        if world.openDayblink(record.id, friend: friend) {
                                            openedImage = asset
                                            showingImage = true
                                        }
                                    } label: { Label("Open once", systemImage: "square.fill").foregroundColor(.yellow) }
                                } else { Label("Visual message expired", systemImage: "square.dashed").foregroundColor(.secondary) }
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
                    Button("Send") {
                        if world.sendDayblink(friend: friend, text: text) { text = ""; feedback = "" }
                        else { feedback = "Enter a shorter message, or wait for pending activity." }
                    }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if !feedback.isEmpty { Text(feedback).font(.caption).foregroundColor(.secondary) }
                    Text("The restored owner account is read-only. Responses are authored and local, not live messages.").font(.caption).foregroundColor(.secondary)
                }
            } else { Text("Conversation unavailable") }
        }.navigationTitle(friend.name)
            .sheet(isPresented: $showingImage, onDismiss: { openedImage = nil }) {
                NavigationStack {
                    VStack(spacing: 16) {
                        if let asset = openedImage, DayblinkArchive.publicImages.contains(asset) {
                            Image(asset).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Text("Available for this viewing only.").font(.caption).foregroundColor(.secondary)
                    }.padding().navigationTitle("Visual message")
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingImage = false; openedImage = nil } } }
                }
            }
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
            ForEach(DayblinkFriend.allCases.flatMap { DayblinkArchive.records(world.state, friend: $0) }.filter { !$0.temporary && $0.image != nil }) { record in
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
