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
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 6) {
            ForEach(NoraPhotoCatalog.photos.filter(\.privateAlbum)) { photo in
                if photo.available(flags: world.state.flags, authenticated: true) {
                    Image(photo.id).resizable().scaledToFit().accessibilityLabel("Recovered photograph")
                } else {
                    LockedPhotoSurface().aspectRatio(1, contentMode: .fit)
                }
            }
        }
        Text("Access is verified. These photographs remain unrecovered until their individual discoveries are made.")
            .font(.caption).foregroundColor(.secondary)
    }
}
