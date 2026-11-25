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
                    Toggle("Show saved snapshots only", isOn: $favoritesOnly)
                    Text("Activity history").font(.title2.bold())
                    let selected = frames.filter { !favoritesOnly || prefs.favorites.contains($0.id) }
                    if selected.isEmpty { Text("No saved snapshots.").foregroundColor(.secondary) }
                    ForEach(selected) { frame in
                        NavigationLink { HavenFrameDetail(frame: frame) } label: {
                            HStack {
                                HavenWatchImage(asset: frame.id, infrared: prefs.infrared).frame(width: 100)
                                VStack(alignment: .leading) {
                                    Text(frame.camera.rawValue).font(.headline)
                                    Text(frame.label).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if prefs.favorites.contains(frame.id) { Image(systemName: "bookmark.fill") }
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
    private var prefs: HavenWatchPreferences { world.connected.havenWatch ?? HavenWatchPreferences() }
    var body: some View {
        ScrollView {
            if HavenWatchArchive.frames(in: world.state).contains(frame) {
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
                    HStack { Text("Zoom"); Slider(value: $zoom, in: 1...3); Text(String(format: "%.1f×", zoom)).monospacedDigit() }
                    Button {
                        var next = prefs
                        if !next.favorites.insert(frame.id).inserted { next.favorites.remove(frame.id) }
                        world.setHavenWatch(next)
                    } label: { Label(prefs.favorites.contains(frame.id) ? "Remove bookmark" : "Bookmark snapshot", systemImage: prefs.favorites.contains(frame.id) ? "bookmark.fill" : "bookmark") }
                    LabeledContent("Record", value: frame.label)
                    LabeledContent("Captured", value: "Date unavailable")
                    LabeledContent("Source", value: "Restored still")
                    Text("This archive contains still images, not playable video. Infrared is a viewing filter.").font(.caption).foregroundColor(.secondary)
                }.padding(16)
            } else { Text("Snapshot unavailable").padding() }
        }.navigationTitle(frame.camera.rawValue)
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
                Text("Preference saved. No new camera events are available in this restored archive.").font(.caption).foregroundColor(.secondary)
            }
        }.navigationTitle("HavenWatch settings")
    }
}
