import SwiftUI
import UIKit

enum HavenCamera: String, CaseIterable, Identifiable, Codable {
    case entrance = "Front entrance", living = "Living room", balcony = "Balcony", kitchen = "Kitchen", doorbell = "Exterior doorbell"
    var id: String { rawValue }
    var number: String {
        switch self {
        case .entrance: return "01"
        case .living: return "02"
        case .balcony: return "03"
        case .kitchen: return "04"
        case .doorbell: return "05"
        }
    }
    func asset(occupied: Bool) -> String {
        "HavenWatch_CAM" + number + (occupied ? "_occupied" : "_empty")
    }
}

struct HavenWatchPreferences: Codable, Equatable {
    var armed = false
    var infrared = false
    var alertsEnabled = true
    var favorites: Set<String> = []
}

struct HavenWatchFrame: Identifiable, Equatable {
    let camera: HavenCamera
    let occupied: Bool
    var id: String { camera.asset(occupied: occupied) }
    var label: String { occupied ? "Activity snapshot" : "Quiet snapshot" }
}

enum HavenWatchArchive {
    static func marker(_ id:String)->String { "haven.snapshot.opened."+id }
    static func opened(_ world:PhoneWorld)->[HavenWatchFrame] {
        frames(in:world).filter { world.flags.contains(marker($0.id)) }
    }
    static func filtered(_ world:PhoneWorld,camera:HavenCamera?=nil,favoritesOnly:Bool=false,openedOnly:Bool=false)->[HavenWatchFrame] {
        let favorites=world.connectedWorld?.havenWatch?.favorites ?? []
        return frames(in:world).filter { frame in
            (camera == nil || frame.camera == camera) &&
            (!favoritesOnly || favorites.contains(frame.id)) &&
            (!openedOnly || world.flags.contains(marker(frame.id)))
        }
    }
    static func frames(in world: PhoneWorld) -> [HavenWatchFrame] {
        guard world.everydayArchiveRevision != nil else { return [] }
        return HavenCamera.allCases.flatMap { camera in
            [HavenWatchFrame(camera: camera, occupied: false), HavenWatchFrame(camera: camera, occupied: true)]
        }
    }
}

struct HavenWatchView: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var favoritesOnly = false
    @State private var openedOnly=false
    @State private var cameraFilter:HavenCamera?
    private var prefs: HavenWatchPreferences { world.connected.havenWatch ?? HavenWatchPreferences() }
    private var frames: [HavenWatchFrame] { HavenWatchArchive.frames(in: world.state) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LumaHeader(title: "HavenWatch", detail: "Home security · Restored archive", symbol: "shield.lefthalf.filled")
                if frames.isEmpty {
                    Label("Restore the phone archive to view saved cameras.", systemImage: "lock.fill").padding()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Local archive available", systemImage: "archivebox").font(.headline)
                        Text("Five cameras · Ten saved snapshots").font(.subheadline)
                        Text("Live connections are unavailable. Capture dates were not recovered.").font(.caption).foregroundColor(.secondary)
                        Toggle("Arm local simulation", isOn: Binding(get: { prefs.armed }, set: { value in
                            var next = prefs; next.armed = value; world.setHavenWatch(next)
                        }))
                        Text("Changes affect only the simulated controls, not the historical archive or a real security system.").font(.caption).foregroundColor(.secondary)
                    }.padding(16).lumaSurface()
                    HStack {
                        Text("Saved cameras").font(.title2.bold())
                        Spacer()
                        NavigationLink { HavenWatchSettings() } label: { Image(systemName: "gearshape").accessibilityLabel("HavenWatch settings") }
                    }
                    ForEach(HavenCamera.allCases) { camera in
                        NavigationLink {
                            HavenCameraArchive(camera: camera)
                        } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                HavenWatchImage(asset: camera.asset(occupied: false), infrared: prefs.infrared)
                                HStack {
                                    Text("CAM " + camera.number + " · " + camera.rawValue).font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption)
                                }
                                Label("Archive · 2 snapshots", systemImage: "clock").font(.caption).foregroundColor(.secondary)
                            }.padding(12).lumaSurface()
                        }.buttonStyle(.plain)
                    }
                    Text("Archive updates").font(.title2.bold())
                    let updates=HavenWatchEvents.history(world.state)
                    if updates.isEmpty {Text("No restored index updates.").font(.caption).foregroundColor(.secondary)}
                    ForEach(updates) { event in
                        NavigationLink { HavenWatchEventDetail(eventID:event.id) } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Label(HavenWatchEvents.title(event), systemImage: "archivebox").font(.headline)
                                Text("Index activity · " + event.due.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(12).lumaSurface()
                        }.buttonStyle(.plain)
                    }
                    if VeilCommunity.disputeReviewed(world.state) {
                        NavigationLink { HavenCrossArchiveReviewView() } label: {
                            VStack(alignment:.leading,spacing:5) {
                                Label("Review archive origins",systemImage:"rectangle.split.2x1").font(.headline)
                                Text("Compare recovered copies against the saved camera archive.").font(.caption).foregroundColor(.secondary)
                            }.frame(maxWidth:.infinity,alignment:.leading).padding(12).lumaSurface()
                        }.buttonStyle(.plain)
                    }
                    Text("Snapshot library").font(.title2.bold())
                    Picker("Camera",selection:$cameraFilter) {
                        Text("All cameras").tag(Optional<HavenCamera>.none)
                        ForEach(HavenCamera.allCases){camera in Text(camera.rawValue).tag(Optional(camera))}
                    }
                    Toggle("Bookmarked only",isOn:$favoritesOnly)
                    Toggle("Reviewed only",isOn:$openedOnly)
                    let selected=HavenWatchArchive.filtered(world.state,camera:cameraFilter,favoritesOnly:favoritesOnly,openedOnly:openedOnly)
                    Text("\(selected.count) of \(frames.count) snapshots · capture dates unavailable").font(.caption).foregroundColor(.secondary)
                    if selected.isEmpty {Text("No snapshots match these filters.").foregroundColor(.secondary)}
                    ForEach(selected) { frame in
                        NavigationLink { HavenFrameDetail(frame: frame) } label: {
                            HStack {
                                HavenWatchImage(asset: frame.id, infrared: prefs.infrared).frame(width: 100)
                                VStack(alignment: .leading) {
                                    Text(frame.camera.rawValue).font(.headline)
                                    Text(frame.label).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if world.state.flags.contains(HavenWatchArchive.marker(frame.id)) {Image(systemName:"checkmark.circle").accessibilityLabel("Reviewed")}
                                if prefs.favorites.contains(frame.id) {Image(systemName:"bookmark.fill").accessibilityLabel("Bookmarked")}
                            }.padding(10).lumaSurface()
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(16)
        }.navigationTitle("HavenWatch").navigationBarTitleDisplayMode(.inline)
    }
}

struct HavenWatchImage: View {
    let asset: String
    let infrared: Bool
    var body: some View {
        Group {
            if let image = UIImage(named: asset) {
                Image(uiImage: image).resizable().scaledToFit().saturation(infrared ? 0 : 1).contrast(infrared ? 1.22 : 1)
            } else {
                VStack(spacing: 8) { Image(systemName: "video.slash"); Text("Archive image unavailable").font(.caption) }
                    .frame(maxWidth: .infinity).aspectRatio(16/9, contentMode: .fit).background(Color.gray.opacity(0.18))
            }
        }.clipShape(RoundedRectangle(cornerRadius: 9)).accessibilityLabel("Archived camera snapshot")
    }
}

struct HavenCameraArchive: View {
    let camera: HavenCamera
    @EnvironmentObject private var world: PhoneWorldStore
    var body: some View {
        List {
            Section("Camera information") {
                LabeledContent("Camera", value: "CAM " + camera.number)
                LabeledContent("Connection", value: "Archive only")
                LabeledContent("Capture times", value: "Unavailable")
            }
            Section("Snapshots") {
                ForEach(HavenWatchArchive.frames(in: world.state).filter { $0.camera == camera }) { frame in
                    NavigationLink { HavenFrameDetail(frame: frame) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HavenWatchImage(asset: frame.id, infrared: world.connected.havenWatch?.infrared ?? false)
                            Text(frame.label)
                        }
                    }
                }
            }
        }.navigationTitle(camera.rawValue)
    }
}

struct HavenFrameDetail: View {
    let frame: HavenWatchFrame
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var zoom = 1.0
    @Environment(\.scenePhase) private var phase
    private var available:Bool {HavenWatchArchive.frames(in:world.state).contains(frame)}
    private var prefs: HavenWatchPreferences { world.connected.havenWatch ?? HavenWatchPreferences() }
    var body: some View {
        ScrollView {
            if phase == .active && available {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack(alignment: .topLeading) {
                        GeometryReader { geometry in
                            HavenWatchImage(asset: frame.id, infrared: prefs.infrared)
                                .scaleEffect(zoom)
                                .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                        }.aspectRatio(16/9, contentMode: .fit)
                        Text("CAM " + frame.camera.number + "  ·  ARCHIVE").font(.caption2.monospaced()).padding(6)
                            .background(Color.black.opacity(0.72)).foregroundColor(.white)
                    }.clipShape(RoundedRectangle(cornerRadius: 10))
                    HStack {
                        Text("Zoom")
                        Slider(value:$zoom,in:1...3).accessibilityLabel("Snapshot zoom")
                        Text(String(format:"%.1f×",zoom)).monospacedDigit()
                        Button("Reset"){zoom=1}.disabled(zoom==1)
                    }
                    Toggle("Infrared-style viewing",isOn:Binding(get:{prefs.infrared},set:{value in
                        guard phase == .active,available else{return}
                        var next=prefs;next.infrared=value;world.setHavenWatch(next)
                    }))
                    Button {
                        guard phase == .active,available else{return}
                        var next = prefs
                        if !next.favorites.insert(frame.id).inserted { next.favorites.remove(frame.id) }
                        world.setHavenWatch(next)
                    } label: { Label(prefs.favorites.contains(frame.id) ? "Remove bookmark" : "Bookmark snapshot", systemImage: prefs.favorites.contains(frame.id) ? "bookmark.fill" : "bookmark") }
                    LabeledContent("Record", value: frame.label)
                    LabeledContent("Captured", value: "Date unavailable")
                    LabeledContent("Source", value: "Restored still")
                    Text("This archive contains still images, not playable video. Infrared is a viewing filter.").font(.caption).foregroundColor(.secondary)
                    if VeilCommunity.disputeReviewed(world.state) {
                        NavigationLink { EvidenceComparisonView(initialRecordID:"haven:"+frame.id) } label: {
                            Label("Compare with opened records",systemImage:"rectangle.split.2x1")
                        }
                    }
                }.padding(16)
            } else { Text("Snapshot unavailable").padding() }
        }.navigationTitle(frame.camera.rawValue)
            .onAppear { if phase == .active { world.recordHavenSnapshotOpened(frame.id) } }
            .onChange(of:phase) { value in
                if value == .active {world.recordHavenSnapshotOpened(frame.id)} else {zoom=1}
            }
            .onChange(of:available){if !$0 {zoom=1}}
    }
}

struct HavenWatchSettings: View {
    @EnvironmentObject private var world: PhoneWorldStore
    private var prefs: HavenWatchPreferences { world.connected.havenWatch ?? HavenWatchPreferences() }
    var body: some View {
        Form {
            Section("Display") {
                Toggle("Infrared-style viewing", isOn: Binding(get: { prefs.infrared }, set: { value in
                    var next = prefs; next.infrared = value; world.setHavenWatch(next)
                }))
            }
            Section("Local alerts") {
                Toggle("Security notifications", isOn: Binding(get: { prefs.alertsEnabled }, set: { value in
                    var next = prefs; next.alertsEnabled = value; world.setHavenWatch(next)
                }))
                Text("Controls alerts for local archive updates. No live camera events are received.").font(.caption).foregroundColor(.secondary)
            }
        }.navigationTitle("HavenWatch settings")
    }
}


/// The home archive and VEIL copies remain distinct sources. This optional
/// review is based on their visible scenes, not a claim of matched cameras.
enum HavenCrossArchiveReview {
    static let marker = "haven.cross-archive.reviewed"
    static let note = "The home security archive contains saved stills with camera labels, while the anonymous copies have no authenticated camera identifier. Similar rooms are not sufficient to establish a shared capture source."
    static let choices = ["Every recovered copy came from a confirmed HavenWatch camera.",
                          "The two collections have different source labels; a shared capture source is unverified.",
                          "The original capture dates establish the order of both collections."]
    /// Stable authored pairing, independent of temporary archive access.
    static func potentialPair(_ pair:EvidenceConnection)->Bool {
        guard pair.relation == .source, pair.first != pair.second else { return false }
        let ids=[pair.first,pair.second]
        guard let haven=ids.first(where:{$0.hasPrefix("haven:")}),
              let image=ids.first(where:{$0.hasPrefix("image:VEIL_Home_")}),
              let camera=HavenCamera.allCases.first(where:{
                  ["haven:"+$0.asset(occupied:false),"haven:"+$0.asset(occupied:true)].contains(haven)
              }) else { return false }
        let asset=String(image.dropFirst(6))
        switch camera {
        case .kitchen: return ["VEIL_Home_01","VEIL_Home_03"].contains(asset)
        case .living: return ["VEIL_Home_02","VEIL_Home_05","VEIL_Home_06"].contains(asset)
        case .balcony: return asset == "VEIL_Home_04"
        default: return false
        }
    }
    static func matchingPair(_ pair:EvidenceConnection,in world:PhoneWorld)->Bool {
        guard potentialPair(pair),
              let haven=[pair.first,pair.second].first(where:{$0.hasPrefix("haven:")}),
              let image=[pair.first,pair.second].first(where:{$0.hasPrefix("image:VEIL_Home_")}),
              HavenWatchArchive.opened(world).contains(where:{"haven:"+$0.id == haven}) else { return false }
        let asset=String(image.dropFirst(6))
        return VeilArchive.homeMedia(world).contains(asset) &&
              world.flags.contains("veil.viewed."+asset) &&
              (world.connectedWorld?.recoveredImageReviews ?? []).contains(asset)
    }
    static func ready(_ world:PhoneWorld)->Bool {
        VeilCommunity.disputeReviewed(world) &&
        (world.connectedWorld?.evidenceConnections ?? []).prefix(40).contains { matchingPair($0,in:world) }
    }
    static func reviewed(_ world:PhoneWorld)->Bool {
        ready(world) && world.flags.contains(marker)
    }
    static func accepts(_ answer:Int,in world:PhoneWorld)->Bool { ready(world) && answer == 1 }
}

struct HavenCrossArchiveReviewView:View {
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @State private var choice:Int?
    @State private var notice=""
    var body:some View {
        List {
            if VeilCommunity.disputeReviewed(world.state),phase == .active {
                Section {
                    Text("Review a saved camera snapshot and a recovered home photograph showing a comparable room. Save an origins comparison before recording your conclusion.")
                    NavigationLink { EvidenceComparisonView() } label: {
                        Label("Open comparison workspace",systemImage:"rectangle.split.2x1")
                    }
                }
                Section("Saved cameras") {
                    ForEach(HavenCamera.allCases) { camera in
                        NavigationLink { HavenCameraArchive(camera:camera) } label: { Text(camera.rawValue) }
                    }
                }
                if HavenCrossArchiveReview.reviewed(world.state) {
                    Section("Recorded observation") {
                        Text(HavenCrossArchiveReview.note)
                        NavigationLink { SocialArchiveReviewView() } label:{ Label("Review social account records",systemImage:"person.crop.circle") }
                    }
                } else if HavenCrossArchiveReview.ready(world.state) {
                    Section("What can be established?") {
                        ForEach(HavenCrossArchiveReview.choices.indices,id:\.self) { i in
                            Button { choice=i;notice="" } label: {
                                Label(HavenCrossArchiveReview.choices[i],systemImage:choice==i ? "largecircle.fill.circle":"circle")
                            }.buttonStyle(.plain)
                        }
                        Button("Record conclusion") {
                            guard let choice,phase == .active else { return }
                            notice=world.recordHavenCrossArchiveReview(choice) ? "Observation saved." : "Review the source labels again."
                        }.buttonStyle(.borderedProminent).disabled(choice==nil)
                        if !notice.isEmpty { Text(notice).font(.caption) }
                    }
                } else { Text("A matching saved origins comparison is needed.").font(.caption).foregroundColor(.secondary) }
            } else { Text("Review unavailable.") }
        }.navigationTitle("Archive origins")
        .onChange(of:phase){if $0 != .active {choice=nil;notice=""}}
        .onChange(of:HavenCrossArchiveReview.ready(world.state)){if !$0 {choice=nil;notice=""}}
    }
}
