import SwiftUI
import AVKit
import AVFoundation
import Combine

struct MotionwellClip: Identifiable, Equatable {
    let id: String
    let creator: String
    let handle: String
    let title: String
    let poster: String
    let seconds: Int
    let short: Bool
    let description: String
    var file: String { "Motionwell_" + id }
    var url: URL? { Bundle.main.url(forResource: file, withExtension: "mp4") }
    var durationLabel: String { String(format: "%d:%02d", seconds / 60, seconds % 60) }
}
struct MotionwellWatch: Codable, Equatable {
    var seconds: Double
    var lastWatched: Date
}
struct MotionwellComment: Codable, Equatable, Identifiable {
    let id: String
    let clipID: String
    let body: String
    let date: Date
}
struct MotionwellState: Codable, Equatable {
    var subscriptions: Set<String> = []
    var likes: Set<String> = []
    var saved: Set<String> = []
    var watch: [String: MotionwellWatch] = [:]
    var comments: [MotionwellComment] = []
    var notificationsEnabled = true
    var previewsEnabled = false
    var publicationStart: Date? = nil
    var published: Set<String>? = nil
    var mutedChannels: Set<String>? = nil
    var seenUploads: Set<String>? = nil
}
enum MotionwellArchive {
    static let clips: [MotionwellClip] = [
        .init(id: "coffee", creator: "Maple Cafe", handle: "maplecafe", title: "A quiet coffee break", poster: "CommunityMedia_Coffee", seconds: 12, short: true, description: "An animated photo essay about slowing down for a coffee. No filmed footage or spoken audio."),
        .init(id: "woodland", creator: "Avery Quinn", handle: "avery.green", title: "A little woodland inspiration", poster: "CommunityMedia_Forest", seconds: 12, short: true, description: "A short animated photograph for people who enjoy plants and quiet spaces."),
        .init(id: "animals", creator: "Nina Wells", handle: "nina.wild", title: "Two very different animals", poster: "CommunityMedia_Fox", seconds: 30, short: false, description: "A short wildlife and pet photo essay. Observe wildlife respectfully; the pictures are shared illustrations, not a local sighting."),
        .init(id: "studio", creator: "Blue Hour Interactive", handle: "bluehour", title: "A moment to reset", poster: "CommunityMedia_Mountains", seconds: 60, short: false, description: "A silent studio mood reel about taking a break from work. Original editing of licensed public photographs, not a product trailer or recorded studio footage.")
    ]
    struct ScheduledUpload {
        let clip: MotionwellClip
        let delay: TimeInterval
    }
    static let scheduled: [ScheduledUpload] = [
        .init(clip: .init(id: "cafe-lunch", creator: "Maple Cafe", handle: "maplecafe", title: "A small lunch break", poster: "CommunityMedia_Udon", seconds: 24, short: true, description: "A silent animated photo essay pairing a bowl of noodles with a quiet coffee break. Shared illustrations, not footage from the cafe."), delay: 90),
        .init(clip: .init(id: "green-walk", creator: "Avery Quinn", handle: "avery.green", title: "Two views of the outdoors", poster: "CommunityMedia_Forest", seconds: 36, short: false, description: "A silent animated photo essay with forest and mountain scenery. Shared licensed images, not a live location or personal recording."), delay: 240)
    ]
    static func visible(_ world: PhoneWorld) -> [MotionwellClip] {
        guard world.everydayArchiveRevision != nil else { return [] }
        let published = world.connectedWorld?.motionwell?.published ?? []
        return scheduled.reversed().filter { published.contains($0.clip.id) }.map(\.clip) + clips
    }
    static func progress(_ seconds:Double,duration:Int)->Double {
        guard seconds.isFinite,duration>0 else{return 0}
        return min(Double(duration),max(0,seconds))
    }
    static func resume(_ seconds:Double,duration:Int)->Double {
        let value=progress(seconds,duration:duration)
        return value < Double(duration)-2 ? value:0
    }
    static func feed(_ world:PhoneWorld,filter:String,query:String="")->[MotionwellClip] {
        let q=query.trimmingCharacters(in:.whitespacesAndNewlines)
        let term=q.hasPrefix("@") ? String(q.dropFirst()):q
        let state=world.connectedWorld?.motionwell ?? MotionwellState()
        let rows=visible(world).filter { clip in
            (term.isEmpty || [clip.title,clip.creator,clip.handle,clip.description].contains{$0.localizedCaseInsensitiveContains(term)}) &&
            (filter != "Shorts" || clip.short) &&
            (filter != "Following" || state.subscriptions.contains(clip.handle)) &&
            (filter != "Saved" || state.saved.contains(clip.id)) &&
            (filter != "History" || state.watch[clip.id] != nil)
        }
        if filter=="History" {
            return rows.sorted {
                let left=state.watch[$0.id]?.lastWatched ?? .distantPast
                let right=state.watch[$1.id]?.lastWatched ?? .distantPast
                return left == right ? $0.id < $1.id : left > right
            }
        }
        return rows
    }
    static func canNotify(_ id: String, world: PhoneWorld) -> Bool {
        guard let state = world.connectedWorld?.motionwell,
              state.notificationsEnabled, state.published?.contains(id) == true,
              !(state.seenUploads ?? []).contains(id),
              let upload = scheduled.first(where: { $0.clip.id == id }),
              state.subscriptions.contains(upload.clip.handle),
              !(state.mutedChannels ?? []).contains(upload.clip.handle),
              visible(world).contains(upload.clip), upload.clip.url != nil else { return false }
        return true
    }
}
struct MotionwellView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var filter = "Home"
    @State private var query = ""
    private var state: MotionwellState { world.connected.motionwell ?? MotionwellState() }
    private var clips: [MotionwellClip] {
        MotionwellArchive.feed(world.state,filter:filter,query:query)
    }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                LumaHeader(title: "Motionwell", detail: "Watch something worth your time", symbol: "play.rectangle.fill")
                if world.state.everydayArchiveRevision == nil {
                    Label("Restore the archive to view channels.", systemImage: "lock.fill")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(["Home", "Shorts", "Following", "Saved", "History"], id: \.self) { choice in
                                Button(choice) { filter = choice }
                                    .font(.subheadline.weight(.medium)).padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(filter == choice ? Color.red.opacity(0.35) : Color.secondary.opacity(0.12), in: Capsule())
                            }
                        }.buttonStyle(.plain)
                    }
                    if clips.isEmpty { Text("Nothing here yet.").foregroundColor(.secondary).padding() }
                    ForEach(clips) { clip in
                        NavigationLink { MotionwellPlayerView(clip: clip) } label: {
                            MotionwellTile(clip: clip, progress: state.watch[clip.id]?.seconds, isNew: state.published?.contains(clip.id) == true && !(state.seenUploads ?? []).contains(clip.id))
                        }.buttonStyle(.plain)
                    }
                    Text("Offline restored media. These initial videos are animated photo essays, not camera recordings or live streams.").font(.caption).foregroundColor(.secondary)
                }
            }.padding(16)
        }.navigationTitle("Motionwell").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink { MotionwellSettings() } label: { Image(systemName: "person.crop.circle").accessibilityLabel("Motionwell account") }
                }
            }
    }
}
struct MotionwellTile: View {
    let clip: MotionwellClip
    let progress: Double?
    var isNew = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                GeometryReader { geometry in
                    Image(clip.poster).resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                }.aspectRatio(16.0/9, contentMode: .fit)
                Text(clip.url == nil ? "Unavailable" : clip.durationLabel).font(.caption2.bold()).padding(5).background(.black.opacity(0.8)).foregroundColor(.white).padding(6)
            }.clipShape(RoundedRectangle(cornerRadius: 12))
            if let progress {ProgressView(value:MotionwellArchive.progress(progress,duration:clip.seconds),total:Double(max(1,clip.seconds))).tint(.red)}
            HStack {
                Text(clip.title).font(.headline)
                if isNew { Text("NEW").font(.caption2.bold()).foregroundColor(.red) }
            }
            Text(clip.creator + (clip.short ? " · Short photo essay" : " · Photo essay")).font(.caption).foregroundColor(.secondary)
        }.padding(12).lumaSurface(radius: 16)
    }
}
struct MotionwellPlayerView: View {
    let clip: MotionwellClip
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @State private var player: AVPlayer?
    @State private var draft = ""
    @State private var feedback = ""
    @State private var lastSaved = 0.0
    @State private var started = false
    @State private var playbackError=false
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    private var state: MotionwellState { world.connected.motionwell ?? MotionwellState() }
    private var eligible: Bool { MotionwellArchive.visible(world.state).contains(clip) }
    private func savePosition(force: Bool = false) {
        guard eligible,!playbackError,let player,player.currentItem?.status == .readyToPlay else{return}
        let seconds = player.currentTime().seconds
        guard seconds.isFinite, seconds >= 0 else { return }
        if player.rate > 0 && seconds > 0.25 { started = true }
        guard started, force || abs(seconds - lastSaved) >= 4 else { return }
        world.recordMotionwellWatch(clip.id, seconds: seconds)
        lastSaved = seconds
    }
    private func loadPlayer() {
        guard phase == .active,eligible,let url=clip.url,player==nil else{return}
        playbackError=false;started=false
        let item=AVPlayer(url:url)
        let resume=MotionwellArchive.resume(state.watch[clip.id]?.seconds ?? 0,duration:clip.seconds)
        if resume>0 {item.seek(to:CMTime(seconds:resume,preferredTimescale:600))}
        player=item;lastSaved=resume
        world.markMotionwellUploadSeen(clip.id)
    }
    private func releasePlayer() {
        player?.pause();player=nil;started=false;lastSaved=0;playbackError=false
    }
    var body: some View {
        ScrollView {
            if eligible && phase == .active {
                VStack(alignment: .leading, spacing: 15) {
                    if let player,!playbackError {
                        VideoPlayer(player:player).aspectRatio(16.0/9,contentMode:.fit)
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "video.slash").font(.largeTitle)
                            Text("Local video unavailable").font(.headline)
                            Text(playbackError ? "The local file could not be played.":"This item cannot play until its media is bundled.").font(.caption)
                            if playbackError {Button("Retry"){releasePlayer();loadPlayer()}.buttonStyle(.bordered)}
                        }.frame(maxWidth: .infinity).aspectRatio(16.0/9, contentMode: .fit).lumaSurface()
                    }
                    Text(clip.title).font(.title2.bold())
                    HStack {
                        NavigationLink { MotionwellChannel(handle: clip.handle) } label: {
                            VStack(alignment: .leading) { Text(clip.creator).font(.headline); Text("@" + clip.handle).font(.caption).foregroundColor(.secondary) }
                        }
                        Spacer()
                        Button(state.subscriptions.contains(clip.handle) ? "Following" : "Subscribe") { world.toggleMotionwellSubscription(clip.handle) }.buttonStyle(.borderedProminent).tint(.red)
                    }
                    HStack {
                        Button { world.toggleMotionwellItem(clip.id, saved: false) } label: {
                            Label("Like", systemImage: state.likes.contains(clip.id) ? "hand.thumbsup.fill" : "hand.thumbsup")
                        }
                        Spacer()
                        Button { world.toggleMotionwellItem(clip.id, saved: true) } label: {
                            Label("Save", systemImage: state.saved.contains(clip.id) ? "bookmark.fill" : "bookmark")
                        }
                    }.buttonStyle(.bordered)
                    DisclosureGroup("About this video") {
                        Text(clip.description).font(.subheadline).padding(.vertical, 5)
                        Text("Silent · Animated photo essay · Local media").font(.caption).foregroundColor(.secondary)
                    }
                    Divider()
                    Text("Discussion").font(.headline)
                    ForEach(state.comments.filter { $0.clipID == clip.id }) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Repair desk").font(.caption.bold())
                            Text(comment.body)
                            Text(comment.date, style: .relative).font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    TextField("Write a local comment", text: $draft, axis: .vertical).textFieldStyle(.roundedBorder)
                    Text("\(draft.count) / 500").font(.caption).foregroundColor(.secondary)
                    Button("Post comment") {
                        guard phase == .active else{return}
                        if world.addMotionwellComment(clip.id, text: draft) { draft = ""; feedback = "" }
                        else { feedback = "Enter a shorter comment." }
                    }.disabled(draft.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || draft.count>500 || phase != .active)
                    if !feedback.isEmpty { Text(feedback).font(.caption).foregroundColor(.secondary) }
                }.padding(16)
            } else { Text("Video unavailable").padding() }
        }.navigationTitle("Watch").navigationBarTitleDisplayMode(.inline)
            .onAppear {loadPlayer()}
            .onReceive(timer){_ in
                guard phase == .active,eligible,let player else{return}
                if player.currentItem?.status == .failed || player.status == .failed {
                    player.pause();playbackError=true
                } else {savePosition()}
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
                if let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                   AVAudioSession.InterruptionType(rawValue: raw) == .began {
                    savePosition(force: true); player?.pause()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for:AVAudioSession.routeChangeNotification)){notification in
                if let raw=notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                   AVAudioSession.RouteChangeReason(rawValue:raw) == .oldDeviceUnavailable {
                    savePosition(force:true);player?.pause()
                }
            }
            .onChange(of:eligible){if !$0 {releasePlayer()} else {loadPlayer()}}
            .onChange(of:phase){if $0 != .active {savePosition(force:true);player?.pause()} else {loadPlayer()}}
            .onDisappear {savePosition(force:true);releasePlayer()}
    }
}
struct MotionwellChannel: View {
    let handle: String
    @EnvironmentObject private var world: PhoneWorldStore
    private var clips: [MotionwellClip] { MotionwellArchive.visible(world.state).filter { $0.handle == handle } }
    var body: some View {
        List {
            if let first = clips.first {
                Section {
                    Text(first.creator).font(.title2.bold())
                    Text("@" + handle).foregroundColor(.secondary)
                    Button((world.connected.motionwell?.subscriptions.contains(handle) ?? false) ? "Unsubscribe" : "Subscribe") { world.toggleMotionwellSubscription(handle) }
                    if world.connected.motionwell?.subscriptions.contains(handle) == true {
                        Toggle("New video alerts", isOn: Binding(
                            get: { !(world.connected.motionwell?.mutedChannels ?? []).contains(handle) },
                            set: { world.setMotionwellChannelAlerts(handle, enabled: $0) }))
                    }
                }
                Section("Videos") {
                    ForEach(clips) { clip in
                        NavigationLink { MotionwellPlayerView(clip: clip) } label: { MotionwellTile(clip: clip, progress: nil) }
                    }
                }
            } else { Text("Channel unavailable") }
        }.navigationTitle("Channel")
    }
}
struct MotionwellSettings: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var confirmClear=false
    private var state: MotionwellState { world.connected.motionwell ?? MotionwellState() }
    var body: some View {
        Form {
            if world.state.everydayArchiveRevision != nil {
                Section("Restored account") {
                    HStack {
                        Image("Nora_Profile").resizable().scaledToFill().frame(width: 44, height: 44).clipShape(Circle())
                        VStack(alignment: .leading) { Text("Nora Bennett").font(.headline); Text("@nora.b").font(.caption).foregroundColor(.secondary) }
                    }
                    LabeledContent("Account", value: "Read-only archive")
                }
                Section("Local activity") {
                    LabeledContent("Subscriptions", value: String(state.subscriptions.count))
                    LabeledContent("Saved videos", value: String(state.saved.count))
                    LabeledContent("Watch history", value: String(state.watch.count))
                    Button("Clear local watch history",role:.destructive){confirmClear=true}.disabled(state.watch.isEmpty)
                }
                Section("Notification preferences") {
                    Toggle("Channel notifications", isOn: Binding(get: { state.notificationsEnabled }, set: { world.setMotionwellNotifications(enabled: $0, previews: state.previewsEnabled) }))
                    Toggle("Show previews", isOn: Binding(get: { state.previewsEnabled }, set: { world.setMotionwellNotifications(enabled: state.notificationsEnabled, previews: $0) }))
                    Text("Follow a channel to receive alerts for its authored local releases. Older videos do not generate alerts. No live uploads or external services.").font(.caption).foregroundColor(.secondary)
                }
            } else { Text("Account unavailable") }
        }.navigationTitle("Account & settings")
            .confirmationDialog("Clear watch history?",isPresented:$confirmClear){
                Button("Clear history",role:.destructive){world.clearMotionwellHistory()}
            } message:{Text("Saved videos and subscriptions are kept.")}
    }
}
