import SwiftUI

enum NoraPhotoGate: String {
    case publicPhoto, notes, files, journal, future
}
struct NoraPhoto: Identifiable {
    let id: String
    let gate: NoraPhotoGate
    var privateAlbum: Bool { gate == .future }
    var title: String { "Photo " + String(id.suffix(2)) }
    func available(flags: Set<String>, authenticated: Bool = false) -> Bool {
        switch gate {
        case .publicPhoto: return true
        case .notes: return flags.contains("nora-photo-notes")
        case .files: return flags.contains("nora-photo-files")
        case .journal: return flags.contains("nora-photo-journal")
        case .future: return authenticated && flags.contains("nora-photo-unlocked-" + id)
        }
    }
    var lockedHint: String {
        switch gate {
        case .publicPhoto: return ""
        case .notes: return "Recover a personal reminder."
        case .files: return "Connect the recovered documents."
        case .journal: return "Recover the protected journal."
        case .future: return "A later discovery is required."
        }
    }
}

enum NoraPhotoCatalog {
    static let photos: [NoraPhoto] = (1...12).map { i in
        let gate: NoraPhotoGate
        switch i {
        case 1...3: gate = .publicPhoto
        case 4...5: gate = .notes
        case 6...7: gate = .files
        case 8...9: gate = .journal
        default: gate = .future
        }
        return NoraPhoto(id: String(format: "Nora_Photo_%02d", i), gate: gate)
    } + [NoraPhoto(id: "Nora_Collage_01", gate: .future), NoraPhoto(id: "Nora_Collage_02", gate: .future)]
    /// Existing approved private records recover in a separate authenticated
    /// album session. No narrative claims about the individual pixels are made.
    static func privateRecoveryEligible(_ id:String,flags:Set<String>)->Bool {
        let earned=discoveryFlags(from:flags)
        guard photos.contains(where:{$0.id==id && $0.privateAlbum}),
              earned.contains("phone-tutorial-finished"),
              earned.contains("nora-photo-journal") else{return false}
        let archiveVisited=earned.contains("web.visited.archive") && LumaWebCatalog.page("archive")?.available(earned)==true
        let inspected=archiveVisited && earned.contains("web.visited.archive-records") &&
            (LumaWebCatalog.page("archive-records")?.images.contains{earned.contains("web.inspected."+$0)} ?? false)
        let ledger=inspected && earned.contains("web.visited.archive-ledger") && LumaWebCatalog.page("archive-ledger")?.available(earned)==true
        func recovered(_ name:String)->Bool {earned.contains("nora-photo-unlocked-"+name)}
        switch id {
        case "Nora_Photo_10":return true
        case "Nora_Photo_11":return inspected
        case "Nora_Photo_12":return ledger
        case "Nora_Collage_01":return inspected && recovered("Nora_Photo_10") && recovered("Nora_Photo_11")
        case "Nora_Collage_02":return ledger && recovered("Nora_Photo_12") && recovered("Nora_Collage_01")
        default:return false
        }
    }
    static func discoveryFlags(from flags: Set<String>) -> Set<String> {
        var result = flags
        if flags.contains("phone-tutorial-visited-note") && flags.contains("phone-tutorial-replied") {
            result.insert("nora-photo-notes")
        }
        if result.contains("nora-photo-notes") && flags.contains("phone-tutorial-visited-desk") && flags.contains("phone-tutorial-visited-reservation") {
            result.insert("nora-photo-files")
        }
        if result.contains("nora-photo-files") && flags.contains("phone-tutorial-visited-journal") {
            result.insert("nora-photo-journal")
        }
        return result
    }
}

/// Locked cells never instantiate the real image, even below the texture.
struct LockedPhotoSurface: View {
    var compact = true
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.12, blue: 0.15)
            Image("Photo_Locked_Texture").resizable().scaledToFill()
            VStack(spacing: 5) {
                Image(systemName: "lock.fill").font(compact ? .title3 : .largeTitle)
                Text("Unrecovered").font(compact ? .caption2 : .headline).lineLimit(1).minimumScaleFactor(0.7)
            }.foregroundColor(.white)
        }.clipped().accessibilityLabel("Locked photograph")
    }
}

/// Remains inside the independent protected-area session; never uses global
/// owner verification alone to authorize private photos.
struct NoraPrivateAlbum: View {
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 6) {
            ForEach(NoraPhotoCatalog.photos.filter(\.privateAlbum)) { photo in
                if photo.available(flags: world.state.flags, authenticated: true) {
                    Image(photo.id).resizable().scaledToFit().accessibilityLabel("Recovered photograph")
                } else {
                    VStack(spacing:6) {
                        LockedPhotoSurface().aspectRatio(1, contentMode: .fit)
                        if NoraPhotoCatalog.privateRecoveryEligible(photo.id,flags:world.state.flags) {
                            Button("Recover record") {
                                guard phase == .active else{return}
                                _ = world.recoverPrivatePhoto(photo.id,authenticated:true)
                            }.buttonStyle(.bordered).font(.caption).disabled(phase != .active)
                        }
                    }
                }
            }
        }
        Text("Access is verified. Recover available records here as the investigation progresses. Private records remain inside this album.")
            .font(.caption).foregroundColor(.secondary)
    }
}
